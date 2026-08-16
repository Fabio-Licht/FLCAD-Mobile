enum ModelingCapabilityStatus {
  integrated,
  requiresInteractionAdapter,
  engineUnavailable,
}

class ModelingCapability {
  const ModelingCapability({
    required this.id,
    required this.engine,
    required this.status,
    required this.requirement,
  });
  final String id, engine, requirement;
  final ModelingCapabilityStatus status;
  bool get mayBeExposed => status == ModelingCapabilityStatus.integrated;
}

class ModelingCapabilityRegistry {
  const ModelingCapabilityRegistry();

  static const capabilities = <ModelingCapability>[
    ModelingCapability(
      id: 'selection.document',
      engine: 'ModelingViewportController',
      status: ModelingCapabilityStatus.integrated,
      requirement: 'Imported kernel document',
    ),
    ModelingCapability(
      id: 'preview.confirmation',
      engine: 'InteractionManager',
      status: ModelingCapabilityStatus.integrated,
      requirement: 'Evidence-backed registered tool',
    ),
    ModelingCapability(
      id: 'recognition.analytic',
      engine: 'ProfessionalRecognitionEngine / SurfaceRecognitionEngine',
      status: ModelingCapabilityStatus.requiresInteractionAdapter,
      requirement:
          'Region hit-testing and a certified MeshEntity/RecognitionContext adapter',
    ),
    ModelingCapability(
      id: 'reference.smart',
      engine: 'SmartReferenceEngine',
      status: ModelingCapabilityStatus.requiresInteractionAdapter,
      requirement:
          'EngineeringFeatureSession; the engine produces consultative candidates and decisions, not CAD entities',
    ),
    ModelingCapability(
      id: 'reference.geometry',
      engine: 'ReferenceEngine',
      status: ModelingCapabilityStatus.requiresInteractionAdapter,
      requirement:
          'Accepted Smart Reference candidate mapped to a validated reference recipe',
    ),
    ModelingCapability(
      id: 'sketch.2d',
      engine: 'SketchEngine / SketchEditorEngine / ConstraintEngine',
      status: ModelingCapabilityStatus.requiresInteractionAdapter,
      requirement:
          'Sketch canvas, point capture, snapping, dimensions and command adapters',
    ),
    ModelingCapability(
      id: 'sketch.3d',
      engine: 'No dedicated certified 3D sketch workflow API',
      status: ModelingCapabilityStatus.engineUnavailable,
      requirement: 'Future certified 3D sketch engine and persistence contract',
    ),
    ModelingCapability(
      id: 'surface.analytic',
      engine: 'SurfaceGenerationEngine',
      status: ModelingCapabilityStatus.requiresInteractionAdapter,
      requirement:
          'Approved SurfacePlan candidate and kernel-supported parameters',
    ),
    ModelingCapability(
      id: 'surface.loft_sweep',
      engine: 'TransitionEngine',
      status: ModelingCapabilityStatus.requiresInteractionAdapter,
      requirement: 'Validated section/path selection and Transition UI',
    ),
    ModelingCapability(
      id: 'surface.fill_patch',
      engine: 'AdvancedSurfaceEngine / SurfaceOperationsEngine',
      status: ModelingCapabilityStatus.requiresInteractionAdapter,
      requirement: 'PatchEntity, topology report and surface-quality report',
    ),
    ModelingCapability(
      id: 'surface.edit',
      engine: 'SurfaceOperationsEngine plus specialized surface engines',
      status: ModelingCapabilityStatus.requiresInteractionAdapter,
      requirement:
          'Kernel-backed PatchEntity and topology/quality selection context',
    ),
    ModelingCapability(
      id: 'gizmo.transform',
      engine: 'SketchEngine transforms only',
      status: ModelingCapabilityStatus.requiresInteractionAdapter,
      requirement:
          'No general CAD gizmo contract exists; sketch-only move/rotate/scale can be exposed in a sketch canvas',
    ),
  ];

  ModelingCapability require(String id) => capabilities.firstWhere(
    (value) => value.id == id,
    orElse: () => throw StateError('Unknown modeling capability: $id'),
  );

  Iterable<ModelingCapability> get exposed =>
      capabilities.where((e) => e.mayBeExposed);
}
