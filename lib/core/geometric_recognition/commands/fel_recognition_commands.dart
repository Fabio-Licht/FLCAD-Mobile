import '../../fel/commands/fel_command.dart';
import '../../fel/runtime/fel_context.dart';
import '../../fel/types/fel_type.dart';
import '../../geometric_kernel/geometry/vectors.dart';
import '../../smart_regions/models/geometry.dart' as mesh;
import '../api/recognition_api.dart';
import '../models/recognition_models.dart';

class RecognitionFELCommand implements FELCommand {
  RecognitionFELCommand(this.name, this.action, this.api);
  @override
  final String name;
  final String action;
  final RecognitionApi api;
  @override
  List<FELType> get argumentTypes => switch (action) {
    'recognizeRegion' || 'explain' || 'confidence' => const [FELType.string],
    _ => const [],
  };
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> args,
  ) async {
    Object value;
    switch (action) {
      case 'recognize' || 'rebuild':
        value = await api.recognize(
          _context(context),
          rebuild: action == 'rebuild',
        );
      case 'recognizeRegion':
        final requested = args.first.value as String;
        if (context.activeRegion?.id != requested) {
          throw StateError('SELECT REGION $requested must be executed first');
        }
        value = await api.recognize(_context(context));
      case 'list':
        value = await api.list(context.projectId);
      case 'candidates':
        value = (await api.list(
          context.projectId,
        )).expand((result) => [result.winner, ...result.alternatives]).toList();
      case 'confidence':
        value = api.explain(args.first.value as String).dna.confidence;
      case 'explain':
        value = api.explain(args.first.value as String).explanation;
      case 'compare':
        value = (await api.list(context.projectId))
            .map(
              (result) => {
                'id': result.id,
                'type': result.winner.type.name,
                'score': result.winner.statistics.score,
              },
            )
            .toList();
      case 'validate':
        value = (await api.list(context.projectId))
            .where(
              (result) => result.winner.status == RecognitionStatus.validated,
            )
            .toList();
      case 'clear':
        await api.clear(context.projectId);
        value = true;
      default:
        throw UnsupportedError(action);
    }
    return FELCommandResult(
      value: FELValue(FELType.dynamicType, value),
      description: '$name completed',
    );
  }

  RecognitionContext _context(FELExecutionContext context) {
    final activeMesh = context.activeMesh;
    if (activeMesh == null) {
      throw StateError('A mesh or region must be selected first');
    }
    final region = context.activeRegion;
    final triangleIds =
        region?.selection.indices ??
        Set<int>.from(
          List.generate(activeMesh.triangles.length, (index) => index),
        );
    final vertexIds = <int>{};
    for (final index in triangleIds) {
      final triangle = activeMesh.triangles[index];
      vertexIds
        ..add(triangle.a)
        ..add(triangle.b)
        ..add(triangle.c);
    }
    Vector3 convert(mesh.Vec3 value) => Vector3(value.x, value.y, value.z);
    final points = vertexIds
            .map((index) => convert(activeMesh.vertices[index]))
            .toList(),
        normals = triangleIds
            .map((index) => convert(activeMesh.triangleNormal(index)))
            .toList(),
        regionId = region?.id ?? 'mesh:${activeMesh.id}';
    return RecognitionContext(
      observation: RecognitionObservation(
        projectId: context.projectId,
        meshId: activeMesh.id,
        regionId: regionId,
        points: points,
        normals: normals,
        meshFingerprint:
            '${activeMesh.id}:${activeMesh.vertices.length}:${activeMesh.triangles.length}',
        regionFingerprint: '$regionId:${triangleIds.length}',
      ),
    );
  }
}

List<FELCommand> createRecognitionFELCommands({RecognitionApi? api}) {
  final recognition = api ?? RecognitionApi();
  return [
    RecognitionFELCommand('RECOGNIZE', 'recognize', recognition),
    RecognitionFELCommand('RECOGNIZE REGION', 'recognizeRegion', recognition),
    RecognitionFELCommand('LIST PRIMITIVES', 'list', recognition),
    RecognitionFELCommand('SHOW CANDIDATES', 'candidates', recognition),
    RecognitionFELCommand('SHOW CONFIDENCE', 'confidence', recognition),
    RecognitionFELCommand('EXPLAIN PRIMITIVE', 'explain', recognition),
    RecognitionFELCommand('COMPARE PRIMITIVES', 'compare', recognition),
    RecognitionFELCommand('VALIDATE PRIMITIVES', 'validate', recognition),
    RecognitionFELCommand('REBUILD RECOGNITION', 'rebuild', recognition),
    RecognitionFELCommand('CLEAR RECOGNITION', 'clear', recognition),
  ];
}
