import '../../fel/commands/fel_command.dart';
import '../../fel/runtime/fel_context.dart';
import '../../fel/types/fel_type.dart';
import '../api/parametric_api.dart';
import '../builders/feature_builder.dart';
import '../features/engineering_feature.dart';

class ParametricFeatureFELCommand implements FELCommand {
  const ParametricFeatureFELCommand(this.name, this.kind);
  @override
  final String name;
  final FeatureKind kind;
  @override
  List<FELType> get argumentTypes => const [];
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext c,
    List<FELValue> args,
  ) async {
    final source = c.pipelineValue.value;
    if (source == null) throw StateError('Pipeline source required');
    final feature = await ParametricApi().createFeature(
      FeatureRecipe(
        projectId: c.projectId,
        name: '${kind.name} ${DateTime.now().millisecondsSinceEpoch}',
        kind: kind,
        sourceIds: [source.toString()],
        parameters: kind == FeatureKind.extrude
            ? const {'distance': 1.0}
            : const {},
      ),
    );
    return FELCommandResult(
      value: FELValue(FELType.solid, feature),
      description: 'Feature ${feature.kind.name}: ${feature.status.name}',
    );
  }
}

class KernelRequiredFELCommand implements FELCommand {
  const KernelRequiredFELCommand(this.name);
  @override
  final String name;
  @override
  List<FELType> get argumentTypes => const [];
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext c,
    List<FELValue> args,
  ) => throw UnsupportedError(
    '$name requires an installed GeometryKernelAdapter',
  );
}

List<FELCommand> createParametricFELCommands() => [
  for (final e in const {
    'CREATE FEATURE': FeatureKind.extrude,
    'EXTRUDE': FeatureKind.extrude,
    'REVOLVE': FeatureKind.revolve,
    'SWEEP': FeatureKind.sweep,
    'LOFT': FeatureKind.loft,
    'FILLET': FeatureKind.fillet,
    'CHAMFER': FeatureKind.chamfer,
    'SHELL': FeatureKind.shell,
    'PATTERN': FeatureKind.pattern,
    'MIRROR': FeatureKind.mirror,
  }.entries)
    ParametricFeatureFELCommand(e.key, e.value),
  for (final n in [
    'CREATE SOLID',
    'BOOLEAN UNION',
    'BOOLEAN SUBTRACT',
    'BOOLEAN INTERSECT',
    'VALIDATE FEATURE',
    'VALIDATE SOLID',
  ])
    KernelRequiredFELCommand(n),
];
