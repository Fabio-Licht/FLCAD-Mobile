import 'package:flutter/foundation.dart';

enum PlaneAxisIntersectionSlot { plane, axis }

enum PlaneAxisIntersectionCaptureResult { inactive, accepted, incompatible }

/// Transient launcher-only state for sequential viewport capture.
///
/// It deliberately owns no document selection and persists nothing.
final class PlaneAxisIntersectionSelectionController extends ChangeNotifier {
  PlaneAxisIntersectionSlot? _activeSlot;
  String? _planeEntityId;
  String? _axisEntityId;

  PlaneAxisIntersectionSlot? get activeSlot => _activeSlot;
  String? get planeEntityId => _planeEntityId;
  String? get axisEntityId => _axisEntityId;
  bool get active => _activeSlot != null;
  bool get complete => _planeEntityId != null && _axisEntityId != null;

  void begin(PlaneAxisIntersectionSlot slot) {
    if (_activeSlot == slot) return;
    _activeSlot = slot;
    notifyListeners();
  }

  void choose(PlaneAxisIntersectionSlot slot, String? entityId) {
    if (slot == PlaneAxisIntersectionSlot.plane) {
      _planeEntityId = entityId;
    } else {
      _axisEntityId = entityId;
    }
    _activeSlot = null;
    notifyListeners();
  }

  PlaneAxisIntersectionCaptureResult capture(
    String entityId, {
    required Set<String> planeCandidateIds,
    required Set<String> axisCandidateIds,
  }) {
    final slot = _activeSlot;
    if (slot == null) return PlaneAxisIntersectionCaptureResult.inactive;
    final compatible = switch (slot) {
      PlaneAxisIntersectionSlot.plane => planeCandidateIds.contains(entityId),
      PlaneAxisIntersectionSlot.axis => axisCandidateIds.contains(entityId),
    };
    if (!compatible) {
      return PlaneAxisIntersectionCaptureResult.incompatible;
    }
    choose(slot, entityId);
    return PlaneAxisIntersectionCaptureResult.accepted;
  }

  void clear({bool clearValues = true}) {
    if (_activeSlot == null &&
        (!clearValues || (_planeEntityId == null && _axisEntityId == null))) {
      return;
    }
    _activeSlot = null;
    if (clearValues) {
      _planeEntityId = null;
      _axisEntityId = null;
    }
    notifyListeners();
  }
}
