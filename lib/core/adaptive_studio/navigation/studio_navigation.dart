import '../models/adaptive_studio_models.dart';

class StudioNavigation {
  const StudioNavigation();
  void visit(NavigationState state, String id, {String kind = 'object'}) {
    state.breadcrumb.add(id);
    state.recentObjects
      ..remove(id)
      ..insert(0, id);
    if (state.recentObjects.length > 20) state.recentObjects.removeLast();
    final list = kind == 'feature'
        ? state.recentFeatures
        : kind == 'reference'
        ? state.recentReferences
        : null;
    if (list != null) {
      list
        ..remove(id)
        ..insert(0, id);
      if (list.length > 20) list.removeLast();
    }
  }

  void favorite(NavigationState state, String id, bool value) =>
      value ? state.favorites.add(id) : state.favorites.remove(id);
  void pin(NavigationState state, String id, bool value) =>
      value ? state.pinnedObjects.add(id) : state.pinnedObjects.remove(id);
}
