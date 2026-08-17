import 'package:flutter/material.dart';
import 'dart:ui' show PointMode, VertexMode, Vertices;
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import '../../core/geometric_kernel/geometry/vectors.dart';
import 'camera/cad_camera_controller.dart';
import 'scene/cad_scene_graph.dart';
import 'selection/viewport_picking_controller.dart';

enum CadRenderStyle { shaded, wireframe, hiddenLine, transparent, ghost }

class ProfessionalCadViewportWidget extends StatefulWidget {
  const ProfessionalCadViewportWidget({
    super.key,
    required this.scene,
    required this.camera,
    this.onPick,
    this.onSketchTap,
    this.showSketchGrid = false,
  });

  final CadSceneGraph scene;
  final CadCameraController camera;
  final ValueChanged<CadViewportPick>? onPick;
  final ValueChanged<Offset>? onSketchTap;
  final bool showSketchGrid;

  @override
  State<ProfessionalCadViewportWidget> createState() =>
      _ProfessionalCadViewportWidgetState();
}

class _ProfessionalCadViewportWidgetState
    extends State<ProfessionalCadViewportWidget> {
  CadRenderStyle style = CadRenderStyle.shaded;
  Offset? previous;
  double previousScale = 1;
  final picking = ViewportPickingController();
  final Map<String, _MeshRenderCache> meshRenderCaches = {};

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) =>
              widget.camera.resize(constraints.maxWidth, constraints.maxHeight),
        );
        final colors = Theme.of(context).colorScheme;
        return Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              widget.camera.zoom(event.scrollDelta.dy > 0 ? 1.12 : .88);
            }
          },
          child: GestureDetector(
            onTapUp: widget.onSketchTap != null
                ? (event) => widget.onSketchTap!(event.localPosition)
                : widget.onPick == null
                ? null
                : (event) {
                    final hit = picking.pick(
                      position: event.localPosition,
                      camera: widget.camera,
                      scene: widget.scene,
                    );
                    if (hit != null) widget.onPick!(hit);
                  },
            onScaleStart: (event) {
              previous = event.localFocalPoint;
              previousScale = 1;
            },
            onScaleUpdate: (event) {
              final delta =
                  event.localFocalPoint - (previous ?? event.localFocalPoint);
              previous = event.localFocalPoint;
              if (event.pointerCount > 1 && event.scale != previousScale) {
                widget.camera.zoom(previousScale / event.scale);
                previousScale = event.scale;
              } else if (HardwareKeyboard.instance.isShiftPressed) {
                final scale =
                    (widget.camera.eye - widget.camera.target).length / 500;
                widget.camera.pan(-delta.dx * scale, delta.dy * scale);
              } else {
                widget.camera.orbit(delta.dx / 180, delta.dy / 180);
              }
            },
            onScaleEnd: (_) {
              previous = null;
              previousScale = 1;
            },
            child: ColoredBox(
              color: colors.surfaceContainerLowest,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _CadScenePainter(
                        scene: widget.scene,
                        camera: widget.camera,
                        style: style,
                        colors: colors,
                        showGrid: widget.showSketchGrid,
                        meshRenderCaches: meshRenderCaches,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: SegmentedButton<CadRenderStyle>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: CadRenderStyle.shaded,
                          label: Text('Shaded'),
                        ),
                        ButtonSegment(
                          value: CadRenderStyle.wireframe,
                          label: Text('Wire'),
                        ),
                        ButtonSegment(
                          value: CadRenderStyle.hiddenLine,
                          label: Text('Hidden line'),
                        ),
                        ButtonSegment(
                          value: CadRenderStyle.transparent,
                          label: Text('X-Ray'),
                        ),
                      ],
                      selected: {style},
                      onSelectionChanged: (value) =>
                          setState(() => style = value.first),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: IconButton.filledTonal(
                      tooltip: widget.camera.projectionMode.name,
                      onPressed: widget.camera.toggleProjection,
                      icon: const Icon(Icons.view_in_ar),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProjectedTriangle {
  const _ProjectedTriangle(
    this.path,
    this.depth,
    this.intensity,
    this.selected,
  );
  final Path path;
  final double depth;
  final double intensity;
  final bool selected;
}

class _MeshRenderChunk {
  _MeshRenderChunk({
    required this.xyz,
    required this.indices,
    required this.intensity,
  }) : screen = Float32List(xyz.length ~/ 3 * 2),
       colors = Int32List(xyz.length ~/ 3);

  final Float64List xyz;
  final Uint16List indices;
  final Float32List intensity;
  final Float32List screen;
  final Int32List colors;
  int colorKey = -1;
}

class _MeshRenderCache {
  _MeshRenderCache._(this.chunks, this.nodesSource, this.trianglesSource);
  final List<_MeshRenderChunk> chunks;
  final Object nodesSource;
  final Object trianglesSource;

  factory _MeshRenderCache.from(CadSceneEntity entity) {
    final nodes = (entity.geometry['nodes'] as List).cast<num>();
    final triangles = (entity.geometry['triangles'] as List).cast<num>();
    const trianglesPerChunk = 20000;
    final chunks = <_MeshRenderChunk>[];
    for (
      var first = 0;
      first < triangles.length;
      first += trianglesPerChunk * 3
    ) {
      final end = math.min(first + trianglesPerChunk * 3, triangles.length);
      final localByGlobal = <int, int>{};
      final xyz = <double>[];
      final localIndices = <int>[];
      final intensitySum = <double>[];
      final intensityCount = <int>[];
      int localVertex(int global) => localByGlobal.putIfAbsent(global, () {
        final offset = global * 3;
        xyz.addAll([
          nodes[offset].toDouble(),
          nodes[offset + 1].toDouble(),
          nodes[offset + 2].toDouble(),
        ]);
        intensitySum.add(0);
        intensityCount.add(0);
        return localByGlobal.length;
      });

      for (var offset = first; offset + 2 < end; offset += 3) {
        final ga = triangles[offset].toInt();
        final gb = triangles[offset + 1].toInt();
        final gc = triangles[offset + 2].toInt();
        final a = ga * 3, b = gb * 3, c = gc * 3;
        final abx = nodes[b].toDouble() - nodes[a].toDouble();
        final aby = nodes[b + 1].toDouble() - nodes[a + 1].toDouble();
        final abz = nodes[b + 2].toDouble() - nodes[a + 2].toDouble();
        final acx = nodes[c].toDouble() - nodes[a].toDouble();
        final acy = nodes[c + 1].toDouble() - nodes[a + 1].toDouble();
        final acz = nodes[c + 2].toDouble() - nodes[a + 2].toDouble();
        final nx = aby * acz - abz * acy;
        final ny = abz * acx - abx * acz;
        final nz = abx * acy - aby * acx;
        final length = math.sqrt(nx * nx + ny * ny + nz * nz);
        final light = length == 0
            ? .18
            : (.18 +
                      .72 *
                          ((nx * .3 - ny * .5 + nz * .8) / length / .989949)
                              .abs())
                  .clamp(0.0, 1.0);
        final la = localVertex(ga), lb = localVertex(gb), lc = localVertex(gc);
        localIndices.addAll([la, lb, lc]);
        for (final local in [la, lb, lc]) {
          intensitySum[local] += light;
          intensityCount[local]++;
        }
      }
      chunks.add(
        _MeshRenderChunk(
          xyz: Float64List.fromList(xyz),
          indices: Uint16List.fromList(localIndices),
          intensity: Float32List.fromList([
            for (var i = 0; i < intensitySum.length; i++)
              intensitySum[i] / math.max(intensityCount[i], 1),
          ]),
        ),
      );
    }
    return _MeshRenderCache._(
      chunks,
      entity.geometry['nodes'] as Object,
      entity.geometry['triangles'] as Object,
    );
  }
}

class _CadScenePainter extends CustomPainter {
  _CadScenePainter({
    required this.scene,
    required this.camera,
    required this.style,
    required this.colors,
    required this.showGrid,
    required this.meshRenderCaches,
  }) : super(repaint: Listenable.merge([scene, camera]));
  final CadSceneGraph scene;
  final CadCameraController camera;
  final CadRenderStyle style;
  final ColorScheme colors;
  final bool showGrid;
  final Map<String, _MeshRenderCache> meshRenderCaches;

  @override
  void paint(Canvas canvas, Size size) {
    final currentEntityIds = scene.entities.map((entity) => entity.id).toSet();
    meshRenderCaches.removeWhere((id, _) => !currentEntityIds.contains(id));
    if (showGrid) {
      final paint = Paint()
        ..color = colors.outlineVariant.withValues(alpha: .3)
        ..strokeWidth = .5;
      const spacing = 24.0;
      for (var x = size.width / 2 % spacing; x < size.width; x += spacing) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
      for (var y = size.height / 2 % spacing; y < size.height; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    }
    final projected = <_ProjectedTriangle>[];
    for (final entity in scene.entities.where((item) => item.visible)) {
      if (entity.geometry['nodes'] is List &&
          entity.geometry['triangles'] is List) {
        if (style == CadRenderStyle.shaded ||
            style == CadRenderStyle.transparent) {
          _paintMeshBatched(canvas, entity, size);
        } else {
          _projectMesh(entity, size, projected);
        }
      } else {
        _paintReference(canvas, size, entity);
      }
    }
    projected.sort((a, b) => b.depth.compareTo(a.depth));
    for (final triangle in projected) {
      final selected = triangle.selected ? colors.tertiary : colors.primary;
      final alpha = style == CadRenderStyle.transparent ? .22 : .82;
      if (style != CadRenderStyle.wireframe) {
        canvas.drawPath(
          triangle.path,
          Paint()
            ..style = PaintingStyle.fill
            ..color = Color.lerp(
              colors.surfaceContainer,
              selected,
              triangle.intensity,
            )!.withValues(alpha: alpha),
        );
      }
      if (style != CadRenderStyle.shaded || triangle.selected) {
        canvas.drawPath(
          triangle.path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = triangle.selected ? 1.8 : .65
            ..color = selected.withValues(alpha: .9),
        );
      }
    }
  }

  void _paintMeshBatched(Canvas canvas, CadSceneEntity entity, Size size) {
    final alpha = style == CadRenderStyle.transparent ? .22 : .82;
    var cache = meshRenderCaches[entity.id];
    if (cache == null ||
        !identical(cache.nodesSource, entity.geometry['nodes']) ||
        !identical(cache.trianglesSource, entity.geometry['triangles'])) {
      cache = _MeshRenderCache.from(entity);
      meshRenderCaches[entity.id] = cache;
    }
    final matrix = camera.viewProjectionMatrix.values;
    final background = colors.surfaceContainer.toARGB32();
    final foreground =
        (entity.geometry['displayColor'] == 'destructiveRed'
                ? Colors.redAccent
                : entity.selected
                ? colors.tertiary
                : colors.primary)
            .toARGB32();
    final alphaByte = (alpha * 255).round();
    final colorKey = Object.hash(background, foreground, alphaByte);
    int channel(int value, int shift) => (value >> shift) & 0xff;
    for (final chunk in cache.chunks) {
      for (var i = 0, p = 0; i < chunk.xyz.length; i += 3, p += 2) {
        final x = chunk.xyz[i], y = chunk.xyz[i + 1], z = chunk.xyz[i + 2];
        final w = matrix[12] * x + matrix[13] * y + matrix[14] * z + matrix[15];
        final px =
            (matrix[0] * x + matrix[1] * y + matrix[2] * z + matrix[3]) / w;
        final py =
            (matrix[4] * x + matrix[5] * y + matrix[6] * z + matrix[7]) / w;
        chunk.screen[p] = (px + 1) * size.width / 2;
        chunk.screen[p + 1] = (1 - py) * size.height / 2;
      }
      if (chunk.colorKey != colorKey) {
        for (var i = 0; i < chunk.colors.length; i++) {
          final t = chunk.intensity[i];
          int mix(int shift) =>
              (channel(background, shift) +
                      (channel(foreground, shift) -
                              channel(background, shift)) *
                          t)
                  .round()
                  .clamp(0, 255);
          chunk.colors[i] =
              (alphaByte << 24) | (mix(16) << 16) | (mix(8) << 8) | mix(0);
        }
        chunk.colorKey = colorKey;
      }
      final renderedVertices = Vertices.raw(
        VertexMode.triangles,
        chunk.screen,
        colors: chunk.colors,
        indices: chunk.indices,
      );
      canvas.drawVertices(
        renderedVertices,
        BlendMode.srcOver,
        Paint()..color = Colors.white,
      );
      renderedVertices.dispose();
    }
  }

  void _projectMesh(
    CadSceneEntity entity,
    Size size,
    List<_ProjectedTriangle> output,
  ) {
    final nodes = (entity.geometry['nodes'] as List).cast<num>();
    final indices = (entity.geometry['triangles'] as List).cast<num>();
    Vector3 vertex(int index) => Vector3(
      nodes[index * 3].toDouble(),
      nodes[index * 3 + 1].toDouble(),
      nodes[index * 3 + 2].toDouble(),
    );
    Offset screen(Vector3 point) {
      final p = camera.viewProjectionMatrix.transformPoint(point);
      return Offset((p.x + 1) * size.width / 2, (1 - p.y) * size.height / 2);
    }

    for (var index = 0; index + 2 < indices.length; index += 3) {
      final a = vertex(indices[index].toInt());
      final b = vertex(indices[index + 1].toInt());
      final c = vertex(indices[index + 2].toInt());
      final viewA = camera.viewMatrix.transformPoint(a);
      final viewB = camera.viewMatrix.transformPoint(b);
      final viewC = camera.viewMatrix.transformPoint(c);
      if (viewA.z >= -camera.nearPlane &&
          viewB.z >= -camera.nearPlane &&
          viewC.z >= -camera.nearPlane) {
        continue;
      }
      final normal = (b - a).cross(c - a).normalized;
      final intensity =
          (.18 + .72 * normal.dot(const Vector3(.3, -.5, .8).normalized).abs())
              .clamp(0.0, 1.0);
      final pa = screen(a), pb = screen(b), pc = screen(c);
      if (![pa, pb, pc].every((p) => p.dx.isFinite && p.dy.isFinite)) continue;
      output.add(
        _ProjectedTriangle(
          Path()
            ..moveTo(pa.dx, pa.dy)
            ..lineTo(pb.dx, pb.dy)
            ..lineTo(pc.dx, pc.dy)
            ..close(),
          (viewA.z + viewB.z + viewC.z) / 3,
          intensity,
          entity.selected,
        ),
      );
    }
  }

  void _paintReference(Canvas canvas, Size size, CadSceneEntity entity) {
    Vector3 vector(Object? value) {
      final values = value as List;
      return Vector3(
        (values[0] as num).toDouble(),
        (values[1] as num).toDouble(),
        (values[2] as num).toDouble(),
      );
    }

    Offset project(Vector3 value) {
      final point = camera.viewProjectionMatrix.transformPoint(value);
      return Offset(
        (point.x + 1) * size.width / 2,
        (1 - point.y) * size.height / 2,
      );
    }

    void line(Vector3 from, Vector3 to, Color color, {double width = 1.5}) {
      canvas.drawLine(
        project(from),
        project(to),
        Paint()
          ..color = color
          ..strokeWidth = width,
      );
    }

    final scale = (camera.eye - camera.target).length * .16;
    if ((entity.kind == CadSceneEntityKind.surface ||
            entity.kind == CadSceneEntityKind.preview) &&
        entity.geometry['surfaceKind'] == 'plane') {
      final parameters = (entity.geometry['parameters'] as Map)
          .cast<String, dynamic>();
      final origin = vector(parameters['origin']);
      final normal = vector(parameters['normal']).normalized;
      final x = normal
          .cross(
            normal.z.abs() < .9
                ? const Vector3(0, 0, 1)
                : const Vector3(0, 1, 0),
          )
          .normalized;
      final y = normal.cross(x).normalized;
      final halfWidth =
          ((parameters['width'] as num?)?.toDouble() ?? scale) / 2;
      final halfHeight =
          ((parameters['height'] as num?)?.toDouble() ?? scale) / 2;
      final path = Path()
        ..addPolygon(
          [
            origin - x * halfWidth - y * halfHeight,
            origin + x * halfWidth - y * halfHeight,
            origin + x * halfWidth + y * halfHeight,
            origin - x * halfWidth + y * halfHeight,
          ].map(project).toList(),
          true,
        );
      final preview = entity.kind == CadSceneEntityKind.preview;
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.fill
          ..color = (preview ? colors.tertiary : colors.primary).withValues(
            alpha: preview ? .2 : .62,
          ),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = preview ? 2 : 1
          ..color = preview ? colors.tertiary : colors.primary,
      );
      return;
    }
    switch (entity.kind) {
      case CadSceneEntityKind.point:
        canvas.drawCircle(
          project(vector(entity.geometry['position'])),
          entity.selected ? 7 : 5,
          Paint()..color = colors.tertiary,
        );
      case CadSceneEntityKind.axis:
        final origin = vector(entity.geometry['origin']);
        final direction = vector(entity.geometry['direction']).normalized;
        final length =
            (entity.geometry['visualLength'] as num?)?.toDouble() ?? scale * 2;
        final axisColor = switch (entity.geometry['axisColor']) {
          'x' => Colors.red,
          'y' => Colors.green,
          'z' => Colors.blue,
          _ => colors.secondary,
        };
        line(
          origin - direction * (length / 2),
          origin + direction * (length / 2),
          entity.selected ? colors.tertiary : axisColor,
          width: entity.selected ? 2.5 : 1.5,
        );
      case CadSceneEntityKind.plane:
        final origin = vector(entity.geometry['origin']);
        final normal = vector(entity.geometry['normal']).normalized;
        final preferred = entity.geometry['xDirection'];
        final x = preferred is List
            ? vector(preferred).normalized
            : normal
                  .cross(
                    normal.z.abs() < .9
                        ? const Vector3(0, 0, 1)
                        : const Vector3(0, 1, 0),
                  )
                  .normalized;
        final y = normal.cross(x).normalized;
        final extent =
            ((entity.geometry['visualSize'] as num?)?.toDouble() ??
                scale * 1.4) /
            2;
        final planeColor = switch (entity.geometry['planeColor']) {
          'xy' => Colors.blue,
          'xz' => Colors.green,
          'yz' => Colors.red,
          _ => colors.secondary,
        };
        final corners = [
          origin - x * extent - y * extent,
          origin + x * extent - y * extent,
          origin + x * extent + y * extent,
          origin - x * extent + y * extent,
        ].map(project).toList();
        final path = Path()..addPolygon(corners, true);
        canvas.drawPath(
          path,
          Paint()
            ..color = planeColor.withValues(alpha: .16)
            ..style = PaintingStyle.fill,
        );
        canvas.drawPath(
          path,
          Paint()
            ..color = entity.selected ? colors.tertiary : planeColor
            ..style = PaintingStyle.stroke,
        );
      case CadSceneEntityKind.coordinateSystem:
        final origin = vector(entity.geometry['origin']);
        line(
          origin,
          origin + vector(entity.geometry['xAxis']).normalized * scale,
          Colors.red,
        );
        line(
          origin,
          origin + vector(entity.geometry['yAxis']).normalized * scale,
          Colors.green,
        );
        line(
          origin,
          origin + vector(entity.geometry['zAxis']).normalized * scale,
          Colors.blue,
        );
      case CadSceneEntityKind.curve:
      case CadSceneEntityKind.sketch:
      case CadSceneEntityKind.preview:
        final rawSegments = entity.geometry['segments'];
        if (rawSegments is List) {
          final paint = Paint()
            ..color = entity.selected ? Colors.yellow : Colors.blue
            ..strokeWidth = entity.selected
                ? 3
                : (entity.geometry['strokeWidth'] as num?)?.toDouble() ?? 2
            ..strokeCap = StrokeCap.round
            ..isAntiAlias = true;
          for (final raw in rawSegments) {
            final segment = raw as List;
            line(
              vector(segment[0]),
              vector(segment[1]),
              paint.color,
              width: paint.strokeWidth,
            );
          }
          break;
        }
        final points = (entity.geometry['points'] as List? ?? const [])
            .map(vector)
            .map(project)
            .toList();
        if (points.length > 1) {
          final displayColor = switch (entity.geometry['displayColor']) {
            'destructiveRed' => Colors.redAccent,
            'splineMagenta' => Colors.purpleAccent,
            'sketchGreen' => Colors.lightGreenAccent,
            'previewOrange' => Colors.orangeAccent,
            _ => colors.secondary,
          };
          canvas.drawPoints(
            PointMode.polygon,
            points,
            Paint()
              ..color = entity.selected ? colors.tertiary : displayColor
              ..strokeWidth =
                  (entity.geometry['strokeWidth'] as num?)?.toDouble() ?? 2
              ..strokeCap = StrokeCap.round
              ..isAntiAlias = true,
          );
        }
      case CadSceneEntityKind.mesh:
      case CadSceneEntityKind.surface:
      case CadSceneEntityKind.solid:
      case CadSceneEntityKind.gizmo:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _CadScenePainter oldDelegate) =>
      oldDelegate.style != style ||
      oldDelegate.colors != colors ||
      oldDelegate.showGrid != showGrid;
}
