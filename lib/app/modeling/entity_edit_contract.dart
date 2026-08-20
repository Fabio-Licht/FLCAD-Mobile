import '../../core/cad_document/cad_document.dart';
import '../../core/feature_lifecycle/feature_lifecycle.dart';

/// Permanent authoring contract shared by every FLCAD modeling workspace.
///
/// An authored entity has one stable identity. Re-entering its editor must
/// mutate that same entity and its owned children; it must never create a
/// replacement merely because the operator left the authoring workspace.
abstract final class EntityEditContract {
  static const activationGesture = FeatureLifecycleContract.activationGesture;

  static bool isAuthoringRoot(CadDocumentEntity entity) {
    return FeatureLifecycleContract.appliesTo(entity);
  }

  static String workspace(CadDocumentEntity entity) =>
      entity.data['authoringWorkspace'] as String? ??
      switch (entity.kind) {
        CadDocumentEntityKind.sketch => 'Sketch',
        CadDocumentEntityKind.surface => 'Surfaces',
        CadDocumentEntityKind.shell || CadDocumentEntityKind.solid => 'Solids',
        _ => 'Modeling',
      };
}
