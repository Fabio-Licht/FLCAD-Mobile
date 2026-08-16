import '../interaction/interaction_context.dart';

class ViewportHighlight {
  const ViewportHighlight({required this.entities, this.showNormal = true});
  final List<ModelingSelection> entities;
  final bool showNormal;
  bool contains(String id) => entities.any((e) => e.id == id);
}
