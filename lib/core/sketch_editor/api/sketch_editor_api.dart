import '../../sketch_engine/entities/sketch_entities.dart';
import '../../sketch_engine/models/sketch_models.dart';
import '../engine/sketch_editor_engine.dart';
import '../models/editor_models.dart';

class SketchEditorApi {
  const SketchEditorApi(this.engine);
  final SketchEditorEngine engine;
  EditorOperation preview(
    SketchToolType tool,
    List<SketchVector> points, {
    Map<String, dynamic>? parameters,
  }) => engine.start(tool, points, parameters: parameters);
  List<SketchEntity> confirm(String previewId) => engine.confirm(previewId);
  void cancel(String previewId) => engine.cancel(previewId);
  void edit(
    SketchToolType tool,
    Iterable<String> ids, {
    SketchVector? delta,
    double value = 1,
  }) => engine.edit(tool, ids, delta: delta, value: value);
  bool undo() => engine.undo();
  bool redo() => engine.redo();
  DegreesOfFreedom get dof => engine.readDof();
  SketchQuality get quality => engine.quality();
  List<SketchRecommendation> get recommendations => engine.recommendations();
}
