import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../camera/cad_camera_controller.dart';
import '../professional_cad_viewport_widget.dart';
import '../scene/cad_scene_graph.dart';
import '../selection/viewport_picking_controller.dart';
import 'native_viewport_bridge.dart';

class IntegratedCadViewportWidget extends StatefulWidget {
  const IntegratedCadViewportWidget({
    super.key,
    required this.scene,
    required this.camera,
    this.onPick,
    this.onSketchTap,
    this.showSketchGrid = false,
  });

  final CadSceneGraph scene;
  final CadCameraController camera;
  final ValueChanged<CadViewportPick>? onPick;
  final ValueChanged<Offset>? onSketchTap;
  final bool showSketchGrid;

  @override
  State<IntegratedCadViewportWidget> createState() =>
      _IntegratedCadViewportWidgetState();
}

class _IntegratedCadViewportWidgetState
    extends State<IntegratedCadViewportWidget> {
  final NativeViewportBridge native = NativeViewportBridge();
  ViewportBackend backend = Platform.isWindows
      ? ViewportBackend.nativeGpu
      : ViewportBackend.flutterCanvas;
  Size? _nativeSize;
  bool _initializing = false;
  Timer? _deltaDebounce;

  @override
  void initState() {
    super.initState();
    native.addListener(_changed);
    widget.scene.addListener(_sceneChanged);
    widget.camera.addListener(_cameraChanged);
  }

  @override
  void didUpdateWidget(covariant IntegratedCadViewportWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scene != widget.scene) {
      oldWidget.scene.removeListener(_sceneChanged);
      widget.scene.addListener(_sceneChanged);
      if (native.available) native.sendInitial(widget.scene);
    }
    if (oldWidget.camera != widget.camera) {
      oldWidget.camera.removeListener(_cameraChanged);
      widget.camera.addListener(_cameraChanged);
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _sceneChanged() {
    if (!native.available) return;
    _deltaDebounce?.cancel();
    _deltaDebounce = Timer(const Duration(milliseconds: 16), () {
      native.sendDelta(widget.scene);
    });
  }

  void _cameraChanged() {
    if (native.available) native.setCamera(widget.camera);
  }

  Future<void> _ensureNative(Size size) async {
    if (_initializing || !Platform.isWindows) return;
    if (native.available) {
      if (_nativeSize != size) {
        _nativeSize = size;
        await native.resize(size.width, size.height);
      }
      return;
    }
    _initializing = true;
    final ready = await native.initialize(size.width, size.height);
    _nativeSize = size;
    if (ready) {
      await native.sendInitial(widget.scene);
      await native.setCamera(widget.camera);
    } else if (mounted) {
      setState(() => backend = ViewportBackend.flutterCanvas);
    }
    _initializing = false;
  }

  @override
  void dispose() {
    _deltaDebounce?.cancel();
    widget.scene.removeListener(_sceneChanged);
    widget.camera.removeListener(_cameraChanged);
    native.removeListener(_changed);
    native.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      if (backend == ViewportBackend.nativeGpu) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _ensureNative(size),
        );
      }
      final useNative =
          backend == ViewportBackend.nativeGpu && native.available;
      return Stack(
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
            child: ProfessionalCadViewportWidget(
              scene: widget.scene,
              camera: widget.camera,
              onPick: widget.onPick,
              onSketchTap: widget.onSketchTap,
              showSketchGrid: widget.showSketchGrid,
              renderMeshes: !useNative,
              paintBackground: !useNative,
            ),
          ),
          Positioned(
            top: 10,
            left: 290,
            child: SegmentedButton<ViewportBackend>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: ViewportBackend.flutterCanvas,
                  label: Text('Flutter Canvas'),
                ),
                ButtonSegment(
                  value: ViewportBackend.nativeGpu,
                  label: Text('Native GPU'),
                ),
              ],
              selected: {backend},
              onSelectionChanged: (selection) {
                final next = selection.first;
                setState(() => backend = next);
                if (next == ViewportBackend.nativeGpu) _ensureNative(size);
              },
            ),
          ),
          if (kDebugMode && useNative)
            Positioned(
              left: 10,
              top: 60,
              child: _DiagnosticPanel(
                stats: native.stats,
                onProbe: native.textureProbe,
              ),
            ),
        ],
      );
    },
  );
}

class _DiagnosticPanel extends StatelessWidget {
  const _DiagnosticPanel({required this.stats, required this.onProbe});
  final NativeViewportStats stats;
  final VoidCallback onProbe;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .72),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white70, fontSize: 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${stats.fps.toStringAsFixed(1)} FPS  ${stats.drawCalls} draws  '
              '${stats.triangles} triangles\n'
              'camera=${stats.setCameraCalls} render=${stats.renderCalls} '
              'CB=${stats.constantBufferUpdates} drawIndexed=${stats.drawIndexedCalls}\n'
              'fit=${stats.fitCalls} d=${stats.cameraDistance.toStringAsFixed(6)} '
              'r=${stats.cameraRadius.toStringAsFixed(6)} '
              'near=${stats.cameraNear.toStringAsFixed(6)} '
              'far=${stats.cameraFar.toStringAsFixed(3)}\n'
              'texture=${stats.textureId} registered=${stats.textureRegistered} '
              'callbacks=${stats.textureCallbacks} '
              '${stats.textureCallbackHz.toStringAsFixed(1)}/s\n'
              'marks=${stats.successfulFrameMarks}/${stats.frameMarks} '
              'request=${stats.requestedWidth}x${stats.requestedHeight} '
              'clear=0x${stats.sampledClearBgra.toRadixString(16).padLeft(8, '0')} '
              'draw=0x${stats.sampledBgra.toRadixString(16).padLeft(8, '0')}\n'
              '${stats.gpu}',
            ),
            const SizedBox(height: 6),
            OutlinedButton(
              onPressed: onProbe,
              child: const Text('D3D texture probe'),
            ),
          ],
        ),
      ),
    ),
  );
}
