import 'package:flutter/foundation.dart';

import '../../core/cad_document/alignment_coordinate_system.dart';
import '../../core/geometric_kernel/geometry/vectors.dart';

enum AlignmentCoordinateSystemSlot { plane, axis, point, viewportOrigin }

enum AlignmentCoordinateSystemCaptureResult { inactive, accepted, incompatible }

double? parseAlignmentCoordinateMm(String value) {
  final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
  return parsed == null || !parsed.isFinite ? null : parsed;
}

/// Transient three-slot capture state for the alignment coordinate system.
/// It is deliberately independent from document/global selection.
final class AlignmentCoordinateSystemSelectionController
    extends ChangeNotifier {
  AlignmentCoordinateSystemSlot? _activeSlot;
  String? _planeEntityId;
  String? _axisEntityId;
  String? _pointEntityId;
  AlignmentCoordinateSystemOriginKind _originKind =
      AlignmentCoordinateSystemOriginKind.referencePoint;
  Vector3? _manualOrigin;

  AlignmentCoordinateSystemSlot? get activeSlot => _activeSlot;
  String? get planeEntityId => _planeEntityId;
  String? get axisEntityId => _axisEntityId;
  String? get pointEntityId => _pointEntityId;
  AlignmentCoordinateSystemOriginKind get originKind => _originKind;
  Vector3? get manualOrigin => _manualOrigin;
  bool get active => _activeSlot != null;
  bool get complete =>
      _planeEntityId != null &&
      _axisEntityId != null &&
      (_originKind == AlignmentCoordinateSystemOriginKind.referencePoint
          ? _pointEntityId != null
          : _manualOrigin != null);

  void chooseOriginKind(AlignmentCoordinateSystemOriginKind value) {
    if (_originKind == value) return;
    _originKind = value;
    _activeSlot = null;
    _pointEntityId = null;
    _manualOrigin = null;
    notifyListeners();
  }

  void setManualOrigin(
    Vector3? value, {
    required AlignmentCoordinateSystemOriginKind kind,
  }) {
    if (kind == AlignmentCoordinateSystemOriginKind.referencePoint) {
      throw ArgumentError.value(kind, 'kind', 'Manual origin kind required');
    }
    _originKind = kind;
    _manualOrigin = value;
    _pointEntityId = null;
    _activeSlot = null;
    notifyListeners();
  }

  void begin(AlignmentCoordinateSystemSlot slot) {
    if (_activeSlot == slot) return;
    _activeSlot = slot;
    notifyListeners();
  }

  void choose(AlignmentCoordinateSystemSlot slot, String? entityId) {
    switch (slot) {
      case AlignmentCoordinateSystemSlot.plane:
        _planeEntityId = entityId;
      case AlignmentCoordinateSystemSlot.axis:
        _axisEntityId = entityId;
      case AlignmentCoordinateSystemSlot.point:
        _originKind = AlignmentCoordinateSystemOriginKind.referencePoint;
        _pointEntityId = entityId;
        _manualOrigin = null;
      case AlignmentCoordinateSystemSlot.viewportOrigin:
        throw StateError('Viewport origin must be completed with a 3D hit.');
    }
    _activeSlot = null;
    notifyListeners();
  }

  AlignmentCoordinateSystemCaptureResult capture(
    String entityId, {
    required Set<String> planeCandidateIds,
    required Set<String> axisCandidateIds,
    required Set<String> pointCandidateIds,
  }) {
    final slot = _activeSlot;
    if (slot == null) return AlignmentCoordinateSystemCaptureResult.inactive;
    final compatible = switch (slot) {
      AlignmentCoordinateSystemSlot.plane => planeCandidateIds.contains(
        entityId,
      ),
      AlignmentCoordinateSystemSlot.axis => axisCandidateIds.contains(entityId),
      AlignmentCoordinateSystemSlot.point => pointCandidateIds.contains(
        entityId,
      ),
      AlignmentCoordinateSystemSlot.viewportOrigin => false,
    };
    if (!compatible) return AlignmentCoordinateSystemCaptureResult.incompatible;
    choose(slot, entityId);
    return AlignmentCoordinateSystemCaptureResult.accepted;
  }

  void clear({bool clearValues = true}) {
    if (_activeSlot == null &&
        (!clearValues ||
            (_planeEntityId == null &&
                _axisEntityId == null &&
                _pointEntityId == null))) {
      return;
    }
    _activeSlot = null;
    if (clearValues) {
      _planeEntityId = null;
      _axisEntityId = null;
      _pointEntityId = null;
      _originKind = AlignmentCoordinateSystemOriginKind.referencePoint;
      _manualOrigin = null;
    }
    notifyListeners();
  }
}
