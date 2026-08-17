import '../builders/sketch_builders.dart';
import '../engine/sketch_engine.dart';
import '../entities/sketch_entities.dart';
import '../history/sketch_history.dart';
import '../models/sketch_models.dart';

class SketchEngineApi {
  SketchEngineApi(this.engine) : builders = SketchBuilders(engine);
  final SketchEngine engine;
  final SketchBuilders builders;
  Sketch createSketch(
    String name, {
    SketchPlane? plane,
    SketchCoordinateSystem? coordinates,
  }) => engine.createSketch(name, plane: plane, coordinates: coordinates);
  void deleteSketch(String id) => engine.deleteSketch(id);
  void openSketch(String id) => engine.openSketch(id);
  void closeSketch() => engine.closeSketch();
  void deleteEntity(String id) => engine.deleteEntity(id);
  void move(String id, SketchVector delta) => engine.modify(
    id,
    SketchHistoryAction.move,
    (e) => e.parameters['translation'] = delta.toJson(),
  );
  void rotate(String id, double angle) => engine.modify(
    id,
    SketchHistoryAction.rotate,
    (e) => e.parameters['rotation'] = angle,
  );
  void scale(String id, double factor) => engine.modify(
    id,
    SketchHistoryAction.scale,
    (e) => e.parameters['scale'] = factor,
  );
  void mirror(String id) => engine.modify(
    id,
    SketchHistoryAction.mirror,
    (e) => e.parameters['mirrored'] = !(e.parameters['mirrored'] == true),
  );
  void setConstruction(String id, bool value) => engine.modify(
    id,
    SketchHistoryAction.construction,
    (e) => e.construction = value,
  );
  void setReference(String id, bool value) => engine.modify(
    id,
    SketchHistoryAction.reference,
    (e) => e.reference = value,
  );
  List<Sketch> get sketches => List.unmodifiable(engine.sketches.values);
  SketchEntity? entity(String id) => engine.entities[id];
  Future<void> load() => engine.load();
  Future<void> persist() => engine.persist();
}
