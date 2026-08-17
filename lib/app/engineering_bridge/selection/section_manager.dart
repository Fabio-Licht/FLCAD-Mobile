import 'dart:math' as math;

import '../../../core/cad_document/cad_document.dart';
import '../../../core/geometric_kernel/geometry/primitives.dart';
import '../../../core/geometric_kernel/geometry/vectors.dart';
import '../../runtime/cad_runtime.dart';
import 'mesh_bvh.dart';
import 'mesh_section_kernel.dart';

class SectionManager {
  const SectionManager(this.runtime);
  final CadRuntime runtime;

  List<CadDocumentEntity> get sections =>
      runtime.document?.entities.values
          .where((entity) => entity.kind == CadDocumentEntityKind.section)
          .toList() ??
      const [];

  Future<CadDocumentEntity> create({
    required String planeId,
    required Vector3 origin,
    required Vector3 normal,
    String? name,
    double absoluteTolerance = 1e-9,
    double relativeTolerance = 1e-10,
  }) async {
    final geometry =
        runtime.activeMeshGeometry ??
        (throw StateError('Import an STL before creating a Section.'));
    final mesh =
        runtime.activeImport?.mesh ??
        (throw StateError('The active STL has no official mesh handle.'));
    final bvh = runtime.readOrCreate<MeshBvh>(
      'sections.meshBvh',
      () => MeshBvh(geometry),
    );
    final result = ProfessionalMeshSectionKernel(bvh).intersect(
      plane: Plane3(origin, normal),
      tolerance: MeshSectionTolerance(
        absolute: absoluteTolerance,
        relative: relativeTolerance,
      ),
    );
    final sequence = sections.length + 1;
    final id = 'section:${DateTime.now().microsecondsSinceEpoch}';
    final entity = _entity(
      id: id,
      name: name ?? 'Section ${sequence.toString().padLeft(3, '0')}',
      planeId: planeId,
      meshId: mesh.persistentId,
      origin: origin,
      normal: normal.normalized,
      result: result,
      absoluteTolerance: absoluteTolerance,
      relativeTolerance: relativeTolerance,
    );
    await runtime.mutate(command: 'section.create', upsert: [entity]);
    runtime.select({id});
    return entity;
  }

  Future<CadDocumentEntity> updateOffset(String id, double offset) async {
    final source =
        runtime.document?.entities[id] ??
        (throw StateError('Unknown Section: $id'));
    final definition = Map<String, dynamic>.from(source.data['section'] as Map);
    final origin = Vector3.fromJson(definition['origin'] as List);
    final normal = Vector3.fromJson(definition['normal'] as List).normalized;
    return createReplacement(
      source,
      origin: origin + normal * offset,
      normal: normal,
      command: 'section.update',
    );
  }

  Future<CadDocumentEntity> createReplacement(
    CadDocumentEntity source, {
    required Vector3 origin,
    required Vector3 normal,
    required String command,
  }) async {
    final definition = Map<String, dynamic>.from(source.data['section'] as Map);
    final geometry =
        runtime.activeMeshGeometry ??
        (throw StateError('The Section mesh is unavailable.'));
    final bvh = runtime.readOrCreate<MeshBvh>(
      'sections.meshBvh',
      () => MeshBvh(geometry),
    );
    final absolute = (definition['absoluteTolerance'] as num).toDouble();
    final relative = (definition['relativeTolerance'] as num).toDouble();
    final result = ProfessionalMeshSectionKernel(bvh).intersect(
      plane: Plane3(origin, normal),
      tolerance: MeshSectionTolerance(absolute: absolute, relative: relative),
    );
    final replacement = _entity(
      id: source.id,
      name: source.data['name'] as String,
      planeId: definition['planeId'] as String,
      meshId: definition['meshId'] as String,
      origin: origin,
      normal: normal,
      result: result,
      absoluteTolerance: absolute,
      relativeTolerance: relative,
    );
    await runtime.mutate(command: command, upsert: [replacement]);
    return replacement;
  }

  Future<List<CadDocumentEntity>> createMultiple({
    required String planeId,
    required Vector3 origin,
    required Vector3 normal,
    required int count,
    required double spacing,
  }) async {
    if (count < 1) throw ArgumentError.value(count, 'count');
    final output = <CadDocumentEntity>[];
    final first = -(count - 1) * spacing / 2;
    for (var index = 0; index < count; index++) {
      output.add(
        await create(
          planeId: planeId,
          origin: origin + normal.normalized * (first + index * spacing),
          normal: normal,
        ),
      );
    }
    return output;
  }

  Future<void> rename(String id, String name) async {
    final source =
        runtime.document?.entities[id] ??
        (throw StateError('Unknown Section: $id'));
    await runtime.mutate(
      command: 'section.rename',
      upsert: [
        CadDocumentEntity(
          id: source.id,
          kind: source.kind,
          data: {...source.data, 'name': name.trim()},
        ),
      ],
    );
  }

  Future<void> remove(String id) =>
      runtime.removeEntity(id, command: 'section.delete');
  Future<void> visibility(String id, bool visible) =>
      runtime.setEntityVisibility(id, visible);

  CadDocumentEntity _entity({
    required String id,
    required String name,
    required String planeId,
    required String meshId,
    required Vector3 origin,
    required Vector3 normal,
    required MeshSectionResult result,
    required double absoluteTolerance,
    required double relativeTolerance,
  }) {
    final segments = result.segments
        .map((segment) => [segment.a.toJson(), segment.b.toJson()])
        .toList();
    final length = result.segments.fold<double>(
      0,
      (total, segment) => total + segment.a.distanceTo(segment.b),
    );
    final topology = _topology(result.segments, normal);
    return CadDocumentEntity(
      id: id,
      kind: CadDocumentEntityKind.section,
      data: {
        'name': name,
        'sceneKind': 'curve',
        'sceneVisible': true,
        'sceneGeometry': {
          'segments': segments,
          'color': 'sectionBlue',
          'strokeWidth': 2.0,
        },
        'section': {
          'planeId': planeId,
          'meshId': meshId,
          'origin': origin.toJson(),
          'normal': normal.toJson(),
          'segments': segments,
          'length': length,
          'segmentCount': result.segments.length,
          'pointCount': result.points.length,
          'loopCount': topology.$1,
          'closed': topology.$2,
          'open': !topology.$2,
          'projectedArea': topology.$3,
          'absoluteTolerance': absoluteTolerance,
          'relativeTolerance': relativeTolerance,
          'toleranceUsed':
              result.segments.firstOrNull?.tolerance ??
              math.max(absoluteTolerance, relativeTolerance),
          'candidateTriangles': result.diagnostics.candidateTriangles,
          'degenerations': result.diagnostics.degenerateCount,
          'coplanarTriangles': result.diagnostics.coplanarTriangleCount,
          'nonManifoldEdges': result.diagnostics.nonManifoldEdgeCount,
          'elapsedMicroseconds': result.diagnostics.elapsed.inMicroseconds,
        },
      },
    );
  }

  (int, bool, double) _topology(List<SectionSegment> segments, Vector3 normal) {
    if (segments.isEmpty) return (0, false, 0);
    final tolerance = segments.first.tolerance;
    String key(Vector3 p) =>
        '${(p.x / tolerance).round()}:${(p.y / tolerance).round()}:${(p.z / tolerance).round()}';
    final adjacency = <String, List<String>>{};
    final points = <String, Vector3>{};
    for (final segment in segments) {
      final a = key(segment.a), b = key(segment.b);
      points[a] = segment.a;
      points[b] = segment.b;
      (adjacency[a] ??= []).add(b);
      (adjacency[b] ??= []).add(a);
    }
    final unvisited = adjacency.keys.toSet();
    var loops = 0, area = 0.0;
    var allClosed = true;
    final xAxis = normal
        .cross(
          normal.z.abs() < .9 ? const Vector3(0, 0, 1) : const Vector3(0, 1, 0),
        )
        .normalized;
    final yAxis = normal.cross(xAxis).normalized;
    while (unvisited.isNotEmpty) {
      final seed = unvisited.first;
      final component = <String>{}, pending = <String>[seed];
      while (pending.isNotEmpty) {
        final value = pending.removeLast();
        if (!component.add(value)) continue;
        pending.addAll(
          adjacency[value]!.where((item) => !component.contains(item)),
        );
      }
      unvisited.removeAll(component);
      final closed = component.every((item) => adjacency[item]!.length == 2);
      if (!closed) {
        allClosed = false;
        continue;
      }
      loops++;
      final ordered = <String>[seed];
      String? previous;
      var current = seed;
      while (true) {
        final next = adjacency[current]!.firstWhere(
          (item) => item != previous,
          orElse: () => seed,
        );
        if (next == seed) break;
        ordered.add(next);
        previous = current;
        current = next;
        if (ordered.length > component.length) break;
      }
      var twiceArea = 0.0;
      for (var index = 0; index < ordered.length; index++) {
        final a = points[ordered[index]]!;
        final b = points[ordered[(index + 1) % ordered.length]]!;
        final ax = a.dot(xAxis), ay = a.dot(yAxis);
        final bx = b.dot(xAxis), by = b.dot(yAxis);
        twiceArea += ax * by - bx * ay;
      }
      area += twiceArea.abs() / 2;
    }
    return (loops, allClosed, area);
  }
}
