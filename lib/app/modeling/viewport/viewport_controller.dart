import 'package:flutter/foundation.dart';

import '../interaction/interaction_context.dart';
import 'viewport_camera.dart';
import 'viewport_highlight.dart';
import 'viewport_navigation.dart';
import 'viewport_preview.dart';
import 'viewport_selection.dart';

class ModelingViewportController extends ChangeNotifier {
  final selector = const ViewportSelection();
  final navigation = ViewportNavigation();
  List<ModelingSelection> selection = const [];
  EngineeringPreview? preview;
  ViewportCamera get camera => navigation.camera;
  ViewportHighlight get highlight => ViewportHighlight(entities: selection);
  ViewportPreview get previewLayer => ViewportPreview(value: preview);
  void select(
    ModelingSelection value, {
    SelectionModifier modifier = SelectionModifier.replace,
  }) {
    selection = selector.apply(selection, value, modifier);
    notifyListeners();
  }

  void selectFromExplorer(ModelingSelection value, {bool additive = false}) =>
      select(
        value,
        modifier: additive
            ? SelectionModifier.shift
            : SelectionModifier.replace,
      );
  void clearSelection() {
    selection = const [];
    notifyListeners();
  }

  void showPreview(EngineeringPreview value) {
    preview = value;
    notifyListeners();
  }

  void clearPreview() {
    preview = null;
    notifyListeners();
  }

  void orbit(double dx, double dy) {
    navigation.orbit(dx, dy);
    notifyListeners();
  }

  void pan(double dx, double dy) {
    navigation.pan(dx, dy);
    notifyListeners();
  }

  void zoom(double factor) {
    navigation.zoom(factor);
    notifyListeners();
  }
}
