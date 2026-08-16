import '../interaction/interaction_context.dart';
import '../parameters/parameter_validation.dart';
import '../tools/active_tool.dart';

class EngineeringPreviewEngine {
  const EngineeringPreviewEngine({
    this.validation = const ParameterValidation(),
  });
  final ParameterValidation validation;
  Future<EngineeringPreview> build(
    ActiveTool tool,
    List<ModelingSelection> selection,
    Map<String, Object?> parameters,
  ) async {
    final issues = validation.validate(parameters);
    if (issues.isNotEmpty) {
      throw StateError(
        issues.map((e) => '${e.field}: ${e.message}').join('; '),
      );
    }
    final preview = await tool.previewBuilder(selection, parameters);
    if (preview.evidence.isEmpty) {
      throw StateError('An engineering preview must contain evidence.');
    }
    if (preview.confidence < 0 || preview.confidence > 1) {
      throw StateError('Preview confidence must be between zero and one.');
    }
    return preview;
  }
}
