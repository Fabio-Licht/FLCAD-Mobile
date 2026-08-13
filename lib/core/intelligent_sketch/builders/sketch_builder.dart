import '../../utils/id_generator.dart';
import '../entities/sketch_entity.dart';
import '../models/sketch_context.dart';

class SketchEntityRecipe {
  const SketchEntityRecipe(
    this.kind,
    this.anchors, {
    this.parameters = const {},
    this.sourceIds = const [],
  });
  final SketchEntityKind kind;
  final List<SketchAnchor> anchors;
  final Map<String, double> parameters;
  final List<String> sourceIds;
}

abstract interface class SketchEntityBuilder {
  SketchEntity build(
    SketchEntityRecipe recipe, {
    SketchEntityMode mode = SketchEntityMode.live,
  });
}

class DefaultSketchEntityBuilder implements SketchEntityBuilder {
  const DefaultSketchEntityBuilder();
  @override
  SketchEntity build(
    SketchEntityRecipe recipe, {
    SketchEntityMode mode = SketchEntityMode.live,
  }) {
    _validate(recipe);
    return SketchEntity(
      id: IdGenerator.generate(),
      kind: recipe.kind,
      mode: mode,
      anchors: List.unmodifiable(recipe.anchors),
      parameters: Map.unmodifiable(recipe.parameters),
      sourceIds: List.unmodifiable(recipe.sourceIds),
    );
  }

  void _validate(SketchEntityRecipe recipe) {
    final count = recipe.anchors.length;
    if (recipe.kind == SketchEntityKind.point && count != 1) {
      throw ArgumentError('Point requires one anchor');
    }
    if ({
          SketchEntityKind.line,
          SketchEntityKind.rectangle,
          SketchEntityKind.slot,
        }.contains(recipe.kind) &&
        count < 2) {
      throw ArgumentError('${recipe.kind.name} requires at least two anchors');
    }
    if (recipe.kind == SketchEntityKind.circle &&
        (count != 1 || (recipe.parameters['radius'] ?? 0) <= 0)) {
      throw ArgumentError('Circle requires a center and positive radius');
    }
    if ({
          SketchEntityKind.arc,
          SketchEntityKind.spline,
          SketchEntityKind.polyline,
        }.contains(recipe.kind) &&
        count < 2) {
      throw ArgumentError('${recipe.kind.name} requires control anchors');
    }
  }
}
