import '../models/studio_models.dart';

abstract interface class StudioRenderBackend {
  String get id;
  bool get available;
  Future<RenderFrameMetrics> render(
    StudioViewport viewport,
    List<RenderLayer> layers,
    List<OverlayState> overlays,
  );
}

class RenderFrameMetrics {
  const RenderFrameMetrics(this.drawCalls, this.triangles, this.elapsed);
  final int drawCalls, triangles;
  final Duration elapsed;
}

class StudioRenderPipeline {
  StudioRenderPipeline({StudioRenderBackend? backend})
    : backend = backend ?? const UnavailableRenderBackend();
  final StudioRenderBackend backend;
  final layers = [for (final t in RenderLayerType.values) RenderLayer(t)];
  final overlays = [for (final t in OverlayType.values) OverlayState(t)];
  Future<RenderFrameMetrics> render(StudioViewport viewport) {
    if (!backend.available) {
      throw UnsupportedError('GPU render backend is not installed');
    }
    return backend.render(viewport, layers, overlays);
  }

  void overlay(OverlayType type, bool enabled) {
    final i = overlays.indexWhere((e) => e.type == type);
    overlays[i] = OverlayState(
      type,
      enabled: enabled,
      opacity: overlays[i].opacity,
    );
  }
}

class UnavailableRenderBackend implements StudioRenderBackend {
  const UnavailableRenderBackend();
  @override
  String get id => 'unavailable';
  @override
  bool get available => false;
  @override
  Future<RenderFrameMetrics> render(
    StudioViewport v,
    List<RenderLayer> l,
    List<OverlayState> o,
  ) => throw UnsupportedError('No GPU backend');
}
