import '../engine/alignment_engine.dart';
import '../models/alignment_models.dart';

class AlignmentBuilder {
  const AlignmentBuilder(this.engine);
  final AlignmentEngine engine;
  Alignment build({
    required AlignmentType type,
    required AlignmentInput input,
    AlignmentParameters? parameters,
  }) => engine.create(type, input, parameters: parameters);
}
