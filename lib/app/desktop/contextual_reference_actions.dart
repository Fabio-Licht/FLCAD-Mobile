import '../../core/cad_document/cad_document.dart';
import '../cad_viewport/selection/viewport_picking_controller.dart';
import 'reference_tree_taxonomy.dart';

enum ContextualReferenceAction {
  manualPoint,
  manualPlane,
  manualAxis,
  planeAxisIntersectionPoint,
  alignmentCoordinateSystem,
  plane,
  axis,
}

/// The legacy Geometry menu is global and must not be filtered by the current
/// tree or viewport selection. These entries route to the existing Entidades
/// panels; the contextual reference launcher is an additional entry point.
enum GeometryCreateAction { point, plane, vector, curve }

extension GeometryCreateActionPresentation on GeometryCreateAction {
  String get menuLabel => switch (this) {
    GeometryCreateAction.point => '📍  Ponto',
    GeometryCreateAction.plane => '▱  Plano',
    GeometryCreateAction.vector => '↗  Vetor',
    GeometryCreateAction.curve => '⌁  Curva',
  };
}

abstract final class GeometryCreateActions {
  static const List<GeometryCreateAction> global = [
    GeometryCreateAction.point,
    GeometryCreateAction.plane,
    GeometryCreateAction.vector,
    GeometryCreateAction.curve,
  ];

  static List<GeometryCreateAction> visible({
    CadDocumentEntity? selectedEntity,
    CadViewportPick? viewportPick,
  }) => global;
}

class ContextualReferencePlan {
  const ContextualReferencePlan({
    required this.origin,
    required this.actions,
    this.unavailable,
    this.showManualSection = false,
  });

  final String origin;
  final List<ContextualReferenceAction> actions;
  final String? unavailable;
  final bool showManualSection;
}

/// Routes only to existing, durable reference commands. It owns no geometry,
/// fitting or persistence policy.
abstract final class ContextualReferenceActions {
  static ContextualReferencePlan plan({
    CadDocumentEntity? entity,
    CadViewportPick? pick,
    String? managedFaceSurfaceType,
    bool recognizedStlPlaneAvailable = false,
  }) {
    if (entity?.data['systemProtected'] == true) {
      return switch (entity!.data['sceneKind']) {
        'plane' => const ContextualReferencePlan(
          origin: 'Sistema padrão — plano de suporte',
          actions: [ContextualReferenceAction.manualPlane],
        ),
        'axis' => const ContextualReferencePlan(
          origin: 'Sistema padrão — eixo de suporte',
          actions: [ContextualReferenceAction.manualAxis],
        ),
        'point' => const ContextualReferencePlan(
          origin: 'Sistema padrão — origem de suporte',
          actions: [ContextualReferenceAction.manualPoint],
        ),
        _ => const ContextualReferencePlan(
          origin: 'Sistema padrão',
          actions: [],
          unavailable: 'Selecione um plano, eixo ou origem do sistema padrão.',
        ),
      };
    }
    if (entity != null && ReferenceTreeTaxonomy.isProjectedReference(entity)) {
      return const ContextualReferencePlan(
        origin: 'Referência existente',
        actions: [],
        unavailable:
            'Use Mostrar/Ocultar, Renomear ou Inspector; nenhuma referência será duplicada.',
      );
    }
    if (pick == null) {
      return const ContextualReferencePlan(
        origin: 'Manual',
        actions: [
          ContextualReferenceAction.manualPoint,
          ContextualReferenceAction.manualPlane,
          ContextualReferenceAction.manualAxis,
          ContextualReferenceAction.planeAxisIntersectionPoint,
          ContextualReferenceAction.alignmentCoordinateSystem,
        ],
        showManualSection: true,
      );
    }
    final isManagedFace =
        pick.subentityKind == CadViewportSubentityKind.face &&
        (pick.presentationSubId ?? 0) > 0 &&
        entity != null &&
        entity.data['managedStlAssets'] == null &&
        (entity.data['managedStepAssets'] is Map ||
            entity.data['managedBrepAssets'] is Map);
    if (isManagedFace) {
      return switch (managedFaceSurfaceType) {
        'plane' => const ContextualReferencePlan(
          origin: 'Face STEP/BREP — topologia exata',
          actions: [ContextualReferenceAction.plane],
        ),
        'cylinder' => const ContextualReferencePlan(
          origin: 'Face STEP/BREP — topologia exata',
          actions: [ContextualReferenceAction.axis],
        ),
        _ => const ContextualReferencePlan(
          origin: 'Face STEP/BREP — topologia exata',
          actions: [],
          unavailable:
              'Esta face não é planar nem cilíndrica; não há referência segura disponível.',
        ),
      };
    }
    if (entity?.data['managedStlAssets'] is Map) {
      return recognizedStlPlaneAvailable
          ? const ContextualReferencePlan(
              origin: 'Região STL — ajuste de malha',
              actions: [ContextualReferenceAction.plane],
            )
          : const ContextualReferencePlan(
              origin: 'Região STL — ajuste de malha',
              actions: [],
              unavailable:
                  'Selecione e aceite uma hipótese planar de Recognition antes de criar o plano.',
            );
    }
    return const ContextualReferencePlan(
      origin: 'Seleção sem contrato de referência',
      actions: [],
      unavailable:
          'Nenhuma referência segura está disponível para esta seleção.',
    );
  }
}
