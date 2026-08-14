import '../advisor/alignment_advisor.dart';
import '../builders/alignment_builder.dart';
import '../engine/alignment_engine.dart';
import '../models/alignment_models.dart';
import '../preview/alignment_preview.dart';
import '../validation/alignment_quality.dart';
import '../validation/alignment_validation.dart';

class AlignmentApi {
  AlignmentApi(this.engine) : builder = AlignmentBuilder(engine);
  final AlignmentEngine engine;
  final AlignmentBuilder builder;
  List<Alignment> get alignments => List.unmodifiable(engine.alignments.values);
  AlignmentPreview preview(String id) => engine.preview(id);
  void apply(String id) => engine.apply(id);
  void cancel(String id) => engine.cancel(id);
  Future<AlignmentExecutionResult> commit(String id) => engine.commit(id);
  void rollback(String id) => engine.rollback(id);
  AlignmentValidationResult validate(String id) => engine.validate(id);
  AlignmentQuality quality(String id) => engine.quality(id);
  List<AlignmentRecommendation> recommendations(String id) =>
      engine.recommendations(id);
}
