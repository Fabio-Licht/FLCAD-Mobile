import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../camera/cad_camera_controller.dart';
import '../camera/camera_pan_audit.dart';
import '../professional_cad_viewport_widget.dart';
import '../scene/cad_scene_graph.dart';
import '../selection/viewport_picking_controller.dart';
import '../../engineering_bridge/contracts/bridge_selection.dart';
import '../../../core/geometric_kernel/geometry/vectors.dart';
import '../../operational_entities/operational_entity.dart';
import '../../operational_entities/operational_entity_resolver.dart';
import 'native_viewport_bridge.dart';

class IntegratedCadViewportWidget extends StatefulWidget {
  const IntegratedCadViewportWidget({
    super.key,
    required this.scene,
    required this.camera,
    this.onPick,
    this.nativeBridgeFactory,
    this.onSketchSupportPick,
    this.onSketchEntityPick,
    this.onSketchEntityDoublePick,
    this.onSketchTap,
    this.onSketchSecondaryTap,
    this.onSketchHover,
    this.onSketchEntityDragStart,
    this.onSketchEntityDragUpdate,
    this.onSketchEntityDragEnd,
    this.showSketchGrid = false,
    this.operationalEntities,
    this.operationalResolver,
    this.operationalSelection,
    this.onViewportReady,
    this.enableInspectionHover = false,
  });

  /// The viewport owns and disposes the bridge returned by this factory.
  final NativeViewportBridge Function()? nativeBridgeFactory;
  final CadSceneGraph scene;
  final CadCameraController camera;
  final ValueChanged<CadViewportPick>? onPick;
  final ValueChanged<CadViewportPick>? onSketchSupportPick;
  final ValueChanged<CadViewportPick>? onSketchEntityPick;
  final ValueChanged<CadViewportPick>? onSketchEntityDoublePick;
  final ValueChanged<Offset>? onSketchTap;
  final VoidCallback? onSketchSecondaryTap;
  final ValueChanged<Offset>? onSketchHover;
  final void Function(CadViewportPick pick, Offset position)?
  onSketchEntityDragStart;
  final ValueChanged<Offset>? onSketchEntityDragUpdate;
  final ValueChanged<Offset>? onSketchEntityDragEnd;
  final bool showSketchGrid;
  final OperationalEntityRegistry? operationalEntities;
  final OperationalEntityResolver? operationalResolver;
  final OperationalSelectionManager? operationalSelection;
  final VoidCallback? onViewportReady;
  final bool enableInspectionHover;

  @override
  State<IntegratedCadViewportWidget> createState() =>
      _IntegratedCadViewportWidgetState();
}

class _IntegratedCadViewportWidgetState
    extends State<IntegratedCadViewportWidget> {
  late final NativeViewportBridge native;
  int _tapGeneration = 0;
  late final OperationalEntityRegistry operationalEntities;
  late final OperationalEntityResolver operationalResolver;
  late final OperationalSelectionManager operationalSelection;
  bool _ownsOperationalState = false;
  ViewportBackend backend = Platform.isWindows
      ? ViewportBackend.nativeGpu
      : ViewportBackend.flutterCanvas;
  late ViewportBackend _requestedBackend = backend;
  String? get _unsupportedReason =>
      nativeSceneUnsupportedReason(widget.scene, style: native.renderStyle);
  bool get _nativeSupportsMode => _unsupportedReason == null;
  Size? _nativeSize;
  bool _initializing = false;
  bool _switching = false;
  int _backendGeneration = 0;
  int _cameraRevision = 0;
  Future<void>? _nativeWork;
  Future<void> _handoff = Future<void>.value();
  String? _backendNotice;
  bool get _nativeActive =>
      backend == ViewportBackend.nativeGpu && native.available && !_switching;
  Timer? _deltaDebounce;
  NativeViewportPick? _nativeHover;
  OperationalResolution? _operationalHover;
  bool _hoverRequestActive = false;
  bool _nativeNavigating = false;
  CadRenderStyle _renderStyle = CadRenderStyle.shaded;
  Offset? _pendingHover;
  Offset? _lastHoverPosition;

  void _setRenderStyle(CadRenderStyle style) {
    _tapGeneration++;
    setState(() {
      _renderStyle = style;
      native.renderStyle = style == CadRenderStyle.hiddenLine
          ? 1
          : style == CadRenderStyle.wireframe
          ? 2
          : style == CadRenderStyle.transparent
          ? 3
          : 0;
    });
    final next =
        _requestedBackend == ViewportBackend.nativeGpu && !_nativeSupportsMode
        ? ViewportBackend.flutterCanvas
        : _requestedBackend;
    if (next != backend) {
      _switchBackend(next, modeFallback: next != _requestedBackend);
    } else if (_nativeActive) {
      native.setCamera(widget.camera);
    }
  }

  bool _canPublishTap(int token, CadSceneGraph scene) =>
      mounted &&
      token == _tapGeneration &&
      identical(scene, widget.scene) &&
      backend == ViewportBackend.nativeGpu &&
      native.available &&
      !_switching &&
      !_nativeNavigating;

  Future<void> _pickNativeTap(Offset position) async {
    final token = ++_tapGeneration;
    final scene = widget.scene;
    final additive = HardwareKeyboard.instance.isShiftPressed;
    final toggle = HardwareKeyboard.instance.isControlPressed;
    if (!_canPublishTap(token, scene)) return;
    final result = await native.pick(position.dx, position.dy);
    if (!_canPublishTap(token, scene)) return;
    // No hit (or an unresolvable hit) leaves selection unchanged, just as
    // Canvas picking does. Never substitute the last hover for this click.
    if (result == null || result.kind == NativePickKind.none) return;
    final source = scene.find(result.entityId);
    if (source == null || !source.visible) return;
    // Normal entity selection must not segment a STEP display mesh into regions.
    final resolved =
        !widget.enableInspectionHover && source.kind == CadSceneEntityKind.mesh
        ? _entityResolution(source)
        : await operationalResolver.resolve(result, scene);
    if (!_canPublishTap(token, scene) || resolved == null) return;
    operationalSelection.select(
      resolved.entity.id,
      additive: additive,
      toggle: toggle,
    );
    final point = result.point;
    if (point.length >= 3 && point.take(3).every((value) => value.isFinite)) {
      widget.camera.focusOn(Vector3(point[0], point[1], point[2]));
      widget.onPick?.call(
        CadViewportPick(
          entityId: resolved.entity.ownerId,
          hit: MeshHit(
            triangleIndex: -1,
            point: Vector3(point[0], point[1], point[2]),
            distance: 0,
          ),
        ),
      );
    }
  }

  OperationalResolution _entityResolution(CadSceneEntity source) {
    final entity = OperationalEntity(
      id: 'operational:${source.id}',
      type: OperationalEntityType.meshRegion,
      ownerId: source.id,
      ownerDomain: 'entity',
      documentId: source.id,
      revision: 1,
      label: source.id,
      capabilities: const {OperationalCapability.selectable},
      properties: const {'presentationOnly': true},
    );
    operationalEntities.replaceOwner(source.id, [entity]);
    return OperationalResolution(entity: entity, triangleIndices: const []);
  }

  Future<void> _updateNativeHover(Offset position) async {
    if (!widget.enableInspectionHover) return;
    _lastHoverPosition = position;
    _pendingHover = position;
    if (_hoverRequestActive || !_nativeActive || _nativeNavigating) return;
    final generation = _backendGeneration;
    _hoverRequestActive = true;
    while (_pendingHover != null && _nativeActive) {
      final current = _pendingHover!;
      _pendingHover = null;
      final result = await native.pick(current.dx, current.dy);
      final resolved = result == null
          ? null
          : await operationalResolver.resolve(result, widget.scene);
      if (!mounted ||
          !_nativeActive ||
          generation != _backendGeneration ||
          !widget.enableInspectionHover ||
          _pendingHover != null ||
          _nativeNavigating) {
        continue;
      }
      if (resolved == null) {
        await native.clearHover();
      } else {
        await native.setOperationalHover(
          operationalEntityId: resolved.entity.id,
          entityId: resolved.entity.ownerId,
          triangleIndices: resolved.triangleIndices,
        );
      }
      if (mounted) {
        setState(() {
          _nativeHover = result;
          _operationalHover = resolved;
        });
      }
    }
    _hoverRequestActive = false;
  }

  MouseCursor get _nativeCursor => switch (_nativeHover?.kind) {
    NativePickKind.vertex => SystemMouseCursors.precise,
    NativePickKind.edge => SystemMouseCursors.click,
    NativePickKind.face => SystemMouseCursors.click,
    _ => MouseCursor.defer,
  };

  @override
  void initState() {
    super.initState();
    native = widget.nativeBridgeFactory?.call() ?? NativeViewportBridge();
    native.addListener(_changed);
    operationalEntities =
        widget.operationalEntities ?? OperationalEntityRegistry();
    operationalResolver =
        widget.operationalResolver ??
        OperationalEntityResolver(operationalEntities);
    operationalSelection =
        widget.operationalSelection ??
        OperationalSelectionManager(operationalEntities);
    _ownsOperationalState = widget.operationalEntities == null;
    widget.scene.addListener(_sceneChanged);
    widget.camera.addListener(_cameraChanged);
    operationalSelection.addListener(_operationalSelectionChanged);
    if (widget.enableInspectionHover) operationalResolver.prepare(widget.scene);
    _requestedBackend = backend;
  }

  @override
  void didUpdateWidget(covariant IntegratedCadViewportWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enableInspectionHover && !widget.enableInspectionHover) {
      _pendingHover = null;
      _nativeHover = null;
      _operationalHover = null;
      native.clearHover();
    }
    if (oldWidget.scene != widget.scene) {
      _tapGeneration++;
      if (widget.enableInspectionHover) {
        operationalResolver.prepare(widget.scene);
      }
      oldWidget.scene.removeListener(_sceneChanged);
      widget.scene.addListener(_sceneChanged);
      if (_nativeActive && !_initializing) {
        if (_nativeSupportsMode) {
          native.sendDelta(widget.scene);
        } else {
          _switchBackend(ViewportBackend.flutterCanvas, modeFallback: true);
        }
      }
    }
    if (oldWidget.camera != widget.camera) {
      _tapGeneration++;
      oldWidget.camera.removeListener(_cameraChanged);
      widget.camera.addListener(_cameraChanged);
    }
  }

  void _changed() {
    if (!native.available) _tapGeneration++;
    if (mounted &&
        !native.available &&
        !_initializing &&
        !_switching &&
        backend == ViewportBackend.nativeGpu) {
      _switchBackend(ViewportBackend.flutterCanvas, recovery: true);
      return;
    }
    if (mounted) setState(() {});
  }

  void _sceneChanged() {
    _tapGeneration++;
    if (widget.enableInspectionHover) operationalResolver.prepare(widget.scene);
    if (backend == ViewportBackend.flutterCanvas &&
        _requestedBackend == ViewportBackend.nativeGpu &&
        _nativeSupportsMode) {
      _switchBackend(ViewportBackend.nativeGpu);
      return;
    }
    if (backend == ViewportBackend.nativeGpu && !_nativeSupportsMode) {
      _switchBackend(ViewportBackend.flutterCanvas, modeFallback: true);
      return;
    }
    if (!_nativeActive || _initializing) return;
    native.sendDelta(widget.scene);
  }

  void _cameraChanged() {
    ++_cameraRevision;
    _tapGeneration++;
    CameraPanAudit.record(
      'Componente IntegratedCadViewportWidget._cameraChanged consome\n'
      '${widget.camera.auditState()}',
    );
    if (_nativeActive && !_initializing) {
      CameraPanAudit.record(
        'NativeViewportBridge.setCamera() publica sem modificar\n'
        '${widget.camera.auditState()}',
      );
      native.setCamera(widget.camera);
      CameraPanAudit.record(
        'NativeViewportHost.SetCamera() -> Render solicitado',
      );
    } else {
      CameraPanAudit.record('Render Flutter Canvas');
    }
  }

  void _operationalSelectionChanged() {
    if (!_nativeActive) return;
    final activeId = operationalSelection.activeId;
    final presentation = activeId == null
        ? null
        : operationalResolver.presentation(activeId);
    if (presentation == null) {
      native.clearOperationalSelection();
      return;
    }
    native.setOperationalSelection(
      operationalEntityId: presentation.entity.id,
      entityId: presentation.entity.ownerId,
      triangleIndices: presentation.triangleIndices,
    );
  }

  Future<void> _ensureNative(Size size) async {
    if (!mounted ||
        backend != ViewportBackend.nativeGpu ||
        _initializing ||
        !Platform.isWindows ||
        !size.width.isFinite ||
        !size.height.isFinite ||
        size.width <= 1 ||
        size.height <= 1) {
      return;
    }
    if (native.available) {
      if (_nativeSize != size) {
        _nativeSize = size;
        await native.resize(size.width, size.height);
      }
      return;
    }
    if (!_nativeSupportsMode) {
      _switchBackend(ViewportBackend.flutterCanvas, modeFallback: true);
      return;
    }
    _nativeWork = _initializeNative(size);
    await _nativeWork;
  }

  Future<void> _initializeNative(Size size) async {
    _initializing = true;
    final generation = _backendGeneration;
    final ready = await native.initialize(size.width, size.height);
    if (!mounted ||
        generation != _backendGeneration ||
        backend != ViewportBackend.nativeGpu) {
      _initializing = false;
      return;
    }
    _nativeSize = size;
    if (ready) {
      await native.sendInitial(widget.scene);
      if (mounted && generation == _backendGeneration && native.available) {
        await native.sendDelta(widget.scene);
        int revision;
        do {
          revision = _cameraRevision;
          await native.setCamera(widget.camera);
        } while (mounted &&
            generation == _backendGeneration &&
            native.available &&
            revision != _cameraRevision);
      }
    }
    _initializing = false;
    if (mounted && generation == _backendGeneration && !native.available) {
      // Queue cleanup after this initialization has drained.
      _switchBackend(ViewportBackend.flutterCanvas, recovery: true);
    } else if (mounted && !_switching) {
      _operationalSelectionChanged();
      setState(() {});
      await _viewportReady();
    }
  }

  void _switchBackend(
    ViewportBackend next, {
    bool recovery = false,
    bool modeFallback = false,
  }) {
    if (!mounted) return;
    final generation = ++_backendGeneration;
    ++_tapGeneration;
    _deltaDebounce?.cancel();
    _pendingHover = null;
    _nativeHover = null;
    _operationalHover = null;
    _nativeNavigating = false;
    setState(() {
      if (recovery) _requestedBackend = ViewportBackend.flutterCanvas;
      backend = next;
      _switching = true;
      _backendNotice = recovery
          ? 'Native GPU indisponível. Recuperando com Flutter Canvas.'
          : modeFallback
          ? 'Flutter Canvas para toda a cena: ${_unsupportedReason ?? 'modo não suportado'}'
          : null;
    });
    _handoff = _handoff.then((_) async {
      await _nativeWork;
      await native.deactivate();
      if (!mounted || generation != _backendGeneration) return;
      // The preceding frame drops Canvas caches before a native snapshot exists.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || generation != _backendGeneration) return;
      if (next == ViewportBackend.nativeGpu) {
        await _ensureNative(
          Size(widget.camera.viewportWidth, widget.camera.viewportHeight),
        );
      }
      if (!mounted || generation != _backendGeneration) return;
      setState(() {
        _switching = false;
        if (recovery) {
          _backendNotice = 'Native GPU indisponível. Flutter Canvas ativo.';
        }
      });
      _operationalSelectionChanged();
      await _viewportReady();
    });
  }

  @override
  void dispose() {
    ++_backendGeneration;
    _tapGeneration++;
    _deltaDebounce?.cancel();
    widget.scene.removeListener(_sceneChanged);
    widget.camera.removeListener(_cameraChanged);
    native.removeListener(_changed);
    operationalSelection.removeListener(_operationalSelectionChanged);
    native.dispose();
    if (_ownsOperationalState) {
      operationalSelection.dispose();
      operationalEntities.dispose();
    }
    super.dispose();
  }

  Future<void> _viewportReady() async {
    final generation = _backendGeneration;
    final scene = widget.scene;
    if (!mounted ||
        _switching ||
        widget.camera.viewportWidth <= 1 ||
        widget.camera.viewportHeight <= 1) {
      return;
    }
    if (backend == ViewportBackend.nativeGpu) {
      if (!native.available || _initializing) return;
      // Publish the scene delta before delivering Fit to the real camera/host.
      await native.sendDelta(widget.scene);
    }
    if (mounted &&
        identical(scene, widget.scene) &&
        !_switching &&
        generation == _backendGeneration &&
        (backend != ViewportBackend.nativeGpu || native.available)) {
      widget.onViewportReady?.call();
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      if (backend == ViewportBackend.nativeGpu && !_switching) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _ensureNative(size),
        );
      }
      final useNative = _nativeActive && !_initializing;
      return MouseRegion(
        cursor:
            widget.onSketchTap != null ||
                widget.onSketchSupportPick != null ||
                widget.onSketchEntityDragStart != null
            ? SystemMouseCursors.precise
            : useNative
            ? _nativeCursor
            : MouseCursor.defer,
        onHover: useNative || widget.onSketchHover != null
            ? (event) {
                widget.onSketchHover?.call(event.localPosition);
                if (useNative) _updateNativeHover(event.localPosition);
              }
            : null,
        onExit: useNative
            ? (_) {
                _pendingHover = null;
                native.clearHover();
                setState(() {
                  _nativeHover = null;
                  _operationalHover = null;
                });
              }
            : null,
        child: Stack(
          children: [
            Positioned.fill(
              child: useNative
                  ? Texture(
                      textureId: native.textureId!,
                      filterQuality: FilterQuality.none,
                    )
                  : const SizedBox.shrink(),
            ),
            Positioned.fill(
              child: IgnorePointer(
                ignoring:
                    _switching ||
                    _initializing ||
                    (backend == ViewportBackend.nativeGpu && !native.available),
                child: ProfessionalCadViewportWidget(
                  onViewportReady: _viewportReady,
                  scene: widget.scene,
                  camera: widget.camera,
                  onPick: widget.onPick,
                  onNormalTap: useNative ? _pickNativeTap : null,
                  onSketchSupportPick: widget.onSketchSupportPick,
                  onSketchEntityPick: widget.onSketchEntityPick,
                  onSketchEntityDoublePick: widget.onSketchEntityDoublePick,
                  onSketchTap: widget.onSketchTap,
                  onSketchSecondaryTap: widget.onSketchSecondaryTap,
                  onSketchHover: widget.onSketchHover,
                  onSketchEntityDragStart: widget.onSketchEntityDragStart,
                  onSketchEntityDragUpdate: widget.onSketchEntityDragUpdate,
                  onSketchEntityDragEnd: widget.onSketchEntityDragEnd,
                  showSketchGrid: widget.showSketchGrid,
                  renderStyle: _renderStyle,
                  onRenderStyleChanged: _setRenderStyle,
                  showRenderControls: false,
                  renderMeshes:
                      backend == ViewportBackend.flutterCanvas && !_switching,
                  paintBackground: !useNative,
                  // Picking remains on in the transparent Flutter interaction
                  // layer even when meshes are rendered by the native GPU.
                  // Sketch profiles and construction geometry do not exist in
                  // the native triangle-only pick buffer.
                  enablePicking: true,
                  enableEntityHover: !useNative,
                  onNavigationChanged: useNative
                      ? (navigating) {
                          _nativeNavigating = navigating;
                          if (navigating) {
                            _tapGeneration++;
                            _pendingHover = null;
                            native.clearHover();
                            if (_nativeHover != null) {
                              setState(() {
                                _nativeHover = null;
                                _operationalHover = null;
                              });
                            }
                          } else if (_lastHoverPosition != null) {
                            _updateNativeHover(_lastHoverPosition!);
                          }
                        }
                      : null,
                ),
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: SegmentedButton<CadRenderStyle>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: CadRenderStyle.shaded,
                    label: Text('Shaded'),
                  ),
                  ButtonSegment(
                    value: CadRenderStyle.wireframe,
                    label: Text('Wireframe'),
                  ),
                  ButtonSegment(
                    value: CadRenderStyle.hiddenLine,
                    label: Text('Arestas'),
                  ),
                  ButtonSegment(
                    value: CadRenderStyle.transparent,
                    label: Text('Transparência'),
                  ),
                ],
                selected: {_renderStyle},
                onSelectionChanged: (value) => _setRenderStyle(value.first),
              ),
            ),
            Positioned(
              bottom: 10,
              right: 10,
              child: SegmentedButton<ViewportBackend>(
                showSelectedIcon: false,
                segments: [
                  const ButtonSegment(
                    value: ViewportBackend.flutterCanvas,
                    label: Text('Flutter Canvas'),
                  ),
                  ButtonSegment(
                    value: ViewportBackend.nativeGpu,
                    label: const Text('Native GPU'),
                    enabled: Platform.isWindows,
                  ),
                ],
                selected: {backend},
                onSelectionChanged: (selection) {
                  _requestedBackend = selection.first;
                  final next =
                      _requestedBackend == ViewportBackend.nativeGpu &&
                          !_nativeSupportsMode
                      ? ViewportBackend.flutterCanvas
                      : _requestedBackend;
                  if (next != backend) {
                    _switchBackend(
                      next,
                      modeFallback: next != _requestedBackend,
                    );
                  } else if (next != _requestedBackend) {
                    setState(
                      () => _backendNotice =
                          'Flutter Canvas para toda a cena: ${_unsupportedReason ?? 'modo não suportado'}',
                    );
                  } else {
                    setState(() => _backendNotice = null);
                  }
                },
              ),
            ),
            if (_backendNotice != null || _switching || _initializing)
              Positioned(
                top: 60,
                left: 10,
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      _backendNotice ?? 'Preparando backend de visualização…',
                    ),
                  ),
                ),
              ),
            if (useNative &&
                !_nativeNavigating &&
                _operationalHover != null &&
                _lastHoverPosition != null)
              Positioned(
                left: (_lastHoverPosition!.dx + 16)
                    .clamp(8.0, (size.width - 236).clamp(8.0, double.infinity))
                    .toDouble(),
                top: (_lastHoverPosition!.dy + 18)
                    .clamp(8.0, (size.height - 112).clamp(8.0, double.infinity))
                    .toDouble(),
                child: IgnorePointer(
                  child: _OperationalHoverCard(
                    entity: _operationalHover!.entity,
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}

class _OperationalHoverCard extends StatelessWidget {
  const _OperationalHoverCard({required this.entity});
  final OperationalEntity entity;

  String get _typeLabel => switch (entity.type) {
    OperationalEntityType.meshRegion => 'Mesh Region',
    OperationalEntityType.plane => 'Plane',
    OperationalEntityType.cylinder => 'Cylinder',
    OperationalEntityType.cone => 'Cone',
    OperationalEntityType.sphere => 'Sphere',
    OperationalEntityType.fillet => 'Fillet',
    OperationalEntityType.freeformRegion => 'Freeform Region',
    OperationalEntityType.cadFace => 'CAD Face',
    OperationalEntityType.topologicalEdge => 'Topological Edge',
    OperationalEntityType.topologicalVertex => 'Topological Vertex',
    OperationalEntityType.sketchEntity => 'Sketch Entity',
    OperationalEntityType.curve => 'Curve',
    OperationalEntityType.section => 'Section',
    OperationalEntityType.surface => 'Surface',
  };

  @override
  Widget build(BuildContext context) {
    final capabilities = entity.capabilities
        .take(3)
        .map((capability) => capability.name)
        .join(' · ');
    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xEE111923),
        border: Border.all(color: const Color(0x6659D8F5)),
        borderRadius: BorderRadius.circular(5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: DefaultTextStyle(
        style: const TextStyle(color: Color(0xFFD8E6F0), fontSize: 11),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _typeLabel,
              style: const TextStyle(
                color: Color(0xFF64DDF5),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text('Owner: ${entity.ownerDomain}'),
            Text(entity.available ? 'Available' : 'Unavailable'),
            if (capabilities.isNotEmpty) Text(capabilities),
          ],
        ),
      ),
    );
  }
}
