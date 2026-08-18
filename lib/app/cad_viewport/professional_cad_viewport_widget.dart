import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui' show PointMode, VertexMode, Vertices;
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';

import '../../core/geometric_kernel/geometry/vectors.dart';
import 'camera/cad_camera_controller.dart';
import 'rendering/cad_canvas_normal_pipeline.dart';
import 'rendering/cad_tonal_separation.dart';
import 'scene/cad_scene_graph.dart';
import 'selection/viewport_picking_controller.dart';

enum CadRenderStyle { shaded, wireframe, hiddenLine, transparent, ghost }

enum _MouseNavigationMode { pan, orbit, zoom }

class ProfessionalCadViewportWidget extends StatefulWidget {
  const ProfessionalCadViewportWidget({
    super.key,
    required this.scene,
    required this.camera,
    this.onPick,
    this.onSketchTap,
    this.showSketchGrid = false,
    this.renderMeshes = true,
    this.paintBackground = true,
  });

  final CadSceneGraph scene;
  final CadCameraController camera;
  final ValueChanged<CadViewportPick>? onPick;
  final ValueChanged<Offset>? onSketchTap;
  final bool showSketchGrid;
  final bool renderMeshes;
  final bool paintBackground;

  @override
  State<ProfessionalCadViewportWidget> createState() =>
      _ProfessionalCadViewportWidgetState();
}

class _ProfessionalCadViewportWidgetState
    extends State<ProfessionalCadViewportWidget> {
  CadRenderStyle style = CadRenderStyle.shaded;
  double previousScale = 1;
  final picking = ViewportPickingController();
  final Map<String, _MeshRenderCache> meshRenderCaches = {};
  String? hoveredEntityId;
  Offset? _middleStart;
  Offset? _middlePrevious;
  bool _middleMoved = false;
  _MouseNavigationMode _mouseNavigationMode = _MouseNavigationMode.pan;
  Vector3? _rotationCenterMarker;
  Timer? _rotationCenterMarkerTimer;
  Vector3? _zoomSessionAnchor;
  Timer? _zoomSessionTimer;
  bool _zoomSessionActive = false;

  bool get _isMouseNavigating => _middleStart != null;

  void _startMouseNavigation(PointerDownEvent event) {
    if ((event.buttons & kMiddleMouseButton) == 0) return;
    if (_isMouseNavigating) {
      if ((event.buttons & (kPrimaryMouseButton | kSecondaryMouseButton)) !=
          0) {
        _mouseNavigationMode = _MouseNavigationMode.orbit;
      }
      return;
    }
    _middleStart = event.localPosition;
    _middlePrevious = event.localPosition;
    _middleMoved = false;
    _mouseNavigationMode = _MouseNavigationMode.pan;
  }

  void _updateMouseNavigation(PointerMoveEvent event) {
    if (!_isMouseNavigating || (event.buttons & kMiddleMouseButton) == 0) {
      return;
    }
    final hasOrbitButton =
        (event.buttons & (kPrimaryMouseButton | kSecondaryMouseButton)) != 0;
    if (_mouseNavigationMode == _MouseNavigationMode.pan && hasOrbitButton) {
      _mouseNavigationMode = _MouseNavigationMode.orbit;
    } else if (_mouseNavigationMode == _MouseNavigationMode.orbit &&
        !hasOrbitButton) {
      _mouseNavigationMode = _MouseNavigationMode.zoom;
    }
    final delta =
        event.localPosition - (_middlePrevious ?? event.localPosition);
    _middlePrevious = event.localPosition;
    if (delta.distanceSquared < .01) return;
    _middleMoved = true;
    switch (_mouseNavigationMode) {
      case _MouseNavigationMode.pan:
        widget.camera.panViewportPixels(delta.dx, delta.dy);
      case _MouseNavigationMode.orbit:
        widget.camera.orbit(delta.dx / 180, delta.dy / 180);
      case _MouseNavigationMode.zoom:
        widget.camera.zoom(math.exp(delta.dy.clamp(-80.0, 80.0) * .008));
    }
  }

  void _endMouseNavigation(PointerUpEvent event) {
    if (!_isMouseNavigating) return;
    if ((event.buttons & kMiddleMouseButton) != 0) {
      if (_mouseNavigationMode == _MouseNavigationMode.orbit) {
        _mouseNavigationMode = _MouseNavigationMode.zoom;
        _middlePrevious = event.localPosition;
      }
      return;
    }
    if (!_middleMoved) {
      final hit = picking.pick(
        position: event.localPosition,
        camera: widget.camera,
        scene: widget.scene,
      );
      if (hit != null) {
        widget.camera.setRotationCenter(hit.hit.point);
        _showRotationCenterMarker(hit.hit.point);
      }
    }
    _middleStart = null;
    _middlePrevious = null;
    _middleMoved = false;
    _mouseNavigationMode = _MouseNavigationMode.pan;
  }

  void _showRotationCenterMarker(Vector3 point) {
    _rotationCenterMarkerTimer?.cancel();
    setState(() => _rotationCenterMarker = point);
    _rotationCenterMarkerTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) setState(() => _rotationCenterMarker = null);
    });
  }

  void _zoomFromWheel(PointerScrollEvent event) {
    if (!_zoomSessionActive) {
      _zoomSessionActive = true;
      final hit = picking.pick(
        position: event.localPosition,
        camera: widget.camera,
        scene: widget.scene,
      );
      _zoomSessionAnchor = hit?.hit.point;
      if (_zoomSessionAnchor != null) {
        widget.camera.focusOn(_zoomSessionAnchor!);
      }
    }
    _zoomSessionTimer?.cancel();
    _zoomSessionTimer = Timer(const Duration(milliseconds: 220), () {
      _zoomSessionActive = false;
      _zoomSessionAnchor = null;
    });
    final normalizedDelta = event.scrollDelta.dy.clamp(-240.0, 240.0);
    widget.camera.zoom(
      math.exp(normalizedDelta * .001),
      anchor: _zoomSessionAnchor,
    );
  }

  @override
  void dispose() {
    _rotationCenterMarkerTimer?.cancel();
    _zoomSessionTimer?.cancel();
    super.dispose();
  }

  void _updateHover(Offset position) {
    final hit = picking.pick(
      position: position,
      camera: widget.camera,
      scene: widget.scene,
    );
    final next = hit?.entityId;
    if (next != hoveredEntityId && mounted) {
      setState(() => hoveredEntityId = next);
    }
  }

  void _fitVisibleScene() {
    var minX = double.infinity, minY = double.infinity, minZ = double.infinity;
    var maxX = double.negativeInfinity;
    var maxY = double.negativeInfinity;
    var maxZ = double.negativeInfinity;

    void include(Object? raw) {
      if (raw is! List || raw.length < 3) return;
      final x = (raw[0] as num).toDouble();
      final y = (raw[1] as num).toDouble();
      final z = (raw[2] as num).toDouble();
      minX = math.min(minX, x);
      minY = math.min(minY, y);
      minZ = math.min(minZ, z);
      maxX = math.max(maxX, x);
      maxY = math.max(maxY, y);
      maxZ = math.max(maxZ, z);
    }

    for (final entity in widget.scene.entities.where((item) => item.visible)) {
      final nodes = entity.geometry['nodes'];
      if (nodes is List) {
        for (var i = 0; i + 2 < nodes.length; i += 3) {
          include([nodes[i], nodes[i + 1], nodes[i + 2]]);
        }
      }
      final points = entity.geometry['points'];
      if (points is List) {
        for (final point in points) {
          include(point);
        }
      }
      final segments = entity.geometry['segments'];
      if (segments is List) {
        for (final segment in segments.whereType<List>()) {
          for (final point in segment) {
            include(point);
          }
        }
      }
    }
    if (!minX.isFinite || !maxX.isFinite) return;
    widget.camera.fit(Vector3(minX, minY, minZ), Vector3(maxX, maxY, maxZ));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) =>
              widget.camera.resize(constraints.maxWidth, constraints.maxHeight),
        );
        final colors = Theme.of(context).colorScheme;
        return MouseRegion(
          cursor: hoveredEntityId == null
              ? MouseCursor.defer
              : SystemMouseCursors.click,
          onHover: (event) {
            if (!_isMouseNavigating) _updateHover(event.localPosition);
          },
          onExit: (_) {
            if (hoveredEntityId != null) {
              setState(() => hoveredEntityId = null);
            }
          },
          child: Listener(
            onPointerDown: _startMouseNavigation,
            onPointerMove: _updateMouseNavigation,
            onPointerUp: _endMouseNavigation,
            onPointerCancel: (_) {
              _middleStart = null;
              _middlePrevious = null;
              _middleMoved = false;
              _mouseNavigationMode = _MouseNavigationMode.pan;
            },
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                _zoomFromWheel(event);
              }
            },
            child: GestureDetector(
              onTapUp: widget.onSketchTap != null
                  ? (event) => widget.onSketchTap!(event.localPosition)
                  : widget.onPick == null
                  ? null
                  : (event) {
                      final hit = picking.pick(
                        position: event.localPosition,
                        camera: widget.camera,
                        scene: widget.scene,
                      );
                      if (hit != null) {
                        widget.camera.focusOn(hit.hit.point);
                        widget.onPick!(hit);
                      }
                    },
              onScaleStart: (event) {
                previousScale = 1;
              },
              onScaleUpdate: (event) {
                if (event.pointerCount > 1 && event.scale != previousScale) {
                  widget.camera.zoom(previousScale / event.scale);
                  previousScale = event.scale;
                }
              },
              onScaleEnd: (_) {
                previousScale = 1;
              },
              child: ColoredBox(
                color: widget.paintBackground
                    ? colors.surfaceContainerLowest
                    : Colors.transparent,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _CadScenePainter(
                          scene: widget.scene,
                          camera: widget.camera,
                          style: style,
                          colors: colors,
                          showGrid: widget.showSketchGrid,
                          meshRenderCaches: meshRenderCaches,
                          hoveredEntityId: hoveredEntityId,
                          rotationCenterMarker: _rotationCenterMarker,
                          renderMeshes: widget.renderMeshes,
                          paintBackground: widget.paintBackground,
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
                            label: Text('Wire'),
                          ),
                          ButtonSegment(
                            value: CadRenderStyle.hiddenLine,
                            label: Text('Hidden line'),
                          ),
                          ButtonSegment(
                            value: CadRenderStyle.transparent,
                            label: Text('X-Ray'),
                          ),
                        ],
                        selected: {style},
                        onSelectionChanged: (value) =>
                            setState(() => style = value.first),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Column(
                        children: [
                          IconButton.filledTonal(
                            tooltip: 'Fit View',
                            onPressed: _fitVisibleScene,
                            icon: const Icon(Icons.fit_screen),
                          ),
                          const SizedBox(height: 6),
                          IconButton.filledTonal(
                            tooltip: widget.camera.projectionMode.name,
                            onPressed: widget.camera.toggleProjection,
                            icon: const Icon(Icons.view_in_ar),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProjectedTriangle {
  const _ProjectedTriangle(
    this.path,
    this.depth,
    this.intensity,
    this.selected,
  );
  final Path path;
  final double depth;
  final double intensity;
  final bool selected;
}

class _MeshRenderChunk {
  _MeshRenderChunk({
    required this.xyz,
    required this.indices,
    required this.normals,
  }) : screen = Float32List(xyz.length ~/ 3 * 2),
       depth = Float32List(xyz.length ~/ 3),
       colors = Int32List(xyz.length ~/ 3),
       drawIndices = Uint16List(indices.length),
       depthBuckets = List.generate(256, (_) => <int>[]);

  final Float64List xyz;
  final Uint16List indices;
  final Float32List normals;
  final Float32List screen;
  final Float32List depth;
  final Int32List colors;
  final Uint16List drawIndices;
  final List<List<int>> depthBuckets;
  int colorKey = -1;
  double averageDepth = 0;

  void updateDepthOrder() {
    if (indices.isEmpty) return;
    var minimum = double.infinity;
    var maximum = double.negativeInfinity;
    var sum = 0.0;
    final faceCount = indices.length ~/ 3;
    final faceDepth = Float32List(faceCount);
    for (var face = 0; face < faceCount; face++) {
      final offset = face * 3;
      final value =
          (depth[indices[offset]] +
              depth[indices[offset + 1]] +
              depth[indices[offset + 2]]) /
          3;
      faceDepth[face] = value;
      minimum = math.min(minimum, value);
      maximum = math.max(maximum, value);
      sum += value;
    }
    averageDepth = sum / math.max(faceCount, 1);
    for (final bucket in depthBuckets) {
      bucket.clear();
    }
    final extent = math.max(maximum - minimum, 1e-12);
    for (var face = 0; face < faceCount; face++) {
      final bucket = (((faceDepth[face] - minimum) / extent) * 255)
          .round()
          .clamp(0, 255);
      depthBuckets[bucket].add(face);
    }
    var output = 0;
    for (var bucket = depthBuckets.length - 1; bucket >= 0; bucket--) {
      for (final face in depthBuckets[bucket]) {
        final offset = face * 3;
        drawIndices[output++] = indices[offset];
        drawIndices[output++] = indices[offset + 1];
        drawIndices[output++] = indices[offset + 2];
      }
    }
  }
}

class _MeshRenderCache {
  _MeshRenderCache._(this.chunks, this.nodesSource, this.trianglesSource);
  final List<_MeshRenderChunk> chunks;
  final Object nodesSource;
  final Object trianglesSource;

  factory _MeshRenderCache.from(CadSceneEntity entity) {
    final nodes = (entity.geometry['nodes'] as List).cast<num>();
    final triangles = (entity.geometry['triangles'] as List).cast<num>();
    final chunks = CadCanvasNormalPipeline.build(nodes, triangles)
        .map(
          (chunk) => _MeshRenderChunk(
            xyz: chunk.xyz,
            indices: chunk.indices,
            normals: chunk.normals,
          ),
        )
        .toList(growable: false);
    return _MeshRenderCache._(
      chunks,
      entity.geometry['nodes'] as Object,
      entity.geometry['triangles'] as Object,
    );
  }
}

class _CadScenePainter extends CustomPainter {
  _CadScenePainter({
    required this.scene,
    required this.camera,
    required this.style,
    required this.colors,
    required this.showGrid,
    required this.meshRenderCaches,
    required this.hoveredEntityId,
    required this.rotationCenterMarker,
    required this.renderMeshes,
    required this.paintBackground,
  }) : super(repaint: Listenable.merge([scene, camera]));
  final CadSceneGraph scene;
  final CadCameraController camera;
  final CadRenderStyle style;
  final ColorScheme colors;
  final bool showGrid;
  final Map<String, _MeshRenderCache> meshRenderCaches;
  final String? hoveredEntityId;
  final Vector3? rotationCenterMarker;
  final bool renderMeshes, paintBackground;

  @override
  void paint(Canvas canvas, Size size) {
    if (paintBackground) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors.brightness == Brightness.dark
                ? const [Color(0xff111923), Color(0xff080d12)]
                : const [Color(0xffeef2f5), Color(0xffd7dde2)],
          ).createShader(Offset.zero & size),
      );
    }
    final currentEntityIds = scene.entities.map((entity) => entity.id).toSet();
    meshRenderCaches.removeWhere((id, _) => !currentEntityIds.contains(id));
    if (showGrid) {
      const spacing = 24.0;
      final center = Offset(size.width / 2, size.height / 2);
      for (var x = center.dx % spacing; x < size.width; x += spacing) {
        final major = ((x - center.dx) / spacing).round() % 5 == 0;
        canvas.drawLine(
          Offset(x, 0),
          Offset(x, size.height),
          Paint()
            ..color = colors.outlineVariant.withValues(alpha: major ? .24 : .10)
            ..strokeWidth = major ? .7 : .4,
        );
      }
      for (var y = center.dy % spacing; y < size.height; y += spacing) {
        final major = ((y - center.dy) / spacing).round() % 5 == 0;
        canvas.drawLine(
          Offset(0, y),
          Offset(size.width, y),
          Paint()
            ..color = colors.outlineVariant.withValues(alpha: major ? .24 : .10)
            ..strokeWidth = major ? .7 : .4,
        );
      }
      canvas.drawLine(
        Offset(center.dx, 0),
        Offset(center.dx, size.height),
        Paint()
          ..color = Colors.greenAccent.withValues(alpha: .42)
          ..strokeWidth = 1,
      );
      canvas.drawLine(
        Offset(0, center.dy),
        Offset(size.width, center.dy),
        Paint()
          ..color = Colors.redAccent.withValues(alpha: .42)
          ..strokeWidth = 1,
      );
    }
    final projected = <_ProjectedTriangle>[];
    for (final entity in scene.entities.where((item) => item.visible)) {
      if (renderMeshes &&
          entity.geometry['nodes'] is List &&
          entity.geometry['triangles'] is List) {
        if (style == CadRenderStyle.shaded ||
            style == CadRenderStyle.transparent) {
          _paintMeshBatched(canvas, entity, size);
        } else {
          _projectMesh(entity, size, projected);
        }
      } else {
        _paintReference(canvas, size, entity);
      }
    }
    projected.sort((a, b) => b.depth.compareTo(a.depth));
    for (final triangle in projected) {
      final selected = triangle.selected ? colors.tertiary : colors.primary;
      final alpha = style == CadRenderStyle.transparent ? .22 : .82;
      if (style != CadRenderStyle.wireframe) {
        canvas.drawPath(
          triangle.path,
          Paint()
            ..style = PaintingStyle.fill
            ..color = Color.lerp(
              colors.surfaceContainer,
              selected,
              triangle.intensity,
            )!.withValues(alpha: alpha),
        );
      }
      if (style != CadRenderStyle.shaded || triangle.selected) {
        canvas.drawPath(
          triangle.path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = triangle.selected ? 1.8 : .65
            ..color = selected.withValues(alpha: .9),
        );
      }
    }
    _paintRotationCenterMarker(canvas, size);
    _paintOrientationTriad(canvas, size);
  }

  void _paintRotationCenterMarker(Canvas canvas, Size size) {
    final marker = rotationCenterMarker;
    if (marker == null) return;
    final point = camera.viewProjectionMatrix.transformPoint(marker);
    if (!point.x.isFinite || !point.y.isFinite) return;
    final center = Offset(
      (point.x + 1) * size.width / 2,
      (1 - point.y) * size.height / 2,
    );
    final paint = Paint()
      ..color = colors.tertiary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..isAntiAlias = true;
    canvas.drawCircle(center, 9, paint);
    canvas.drawLine(
      center - const Offset(13, 0),
      center + const Offset(13, 0),
      paint,
    );
    canvas.drawLine(
      center - const Offset(0, 13),
      center + const Offset(0, 13),
      paint,
    );
  }

  void _paintOrientationTriad(Canvas canvas, Size size) {
    if (size.width < 90 || size.height < 90) return;
    final origin = Offset(62, size.height - 62);
    final viewOrigin = camera.viewMatrix.transformPoint(Vector3.zero);

    Offset direction(Vector3 axis) {
      final viewed = camera.viewMatrix.transformPoint(axis) - viewOrigin;
      final projected = Offset(viewed.x, -viewed.y);
      final length = projected.distance;
      return length < 1e-8 ? Offset.zero : projected / length * 34;
    }

    void axis(Vector3 vector, String label, Color color) {
      final delta = direction(vector);
      final end = origin + delta;
      if (delta == Offset.zero) {
        canvas.drawCircle(
          origin,
          6,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2
            ..isAntiAlias = true,
        );
        canvas.drawCircle(origin, 2, Paint()..color = color);
      } else {
        canvas.drawLine(
          origin,
          end,
          Paint()
            ..color = color
            ..strokeWidth = 2.4
            ..strokeCap = StrokeCap.round
            ..isAntiAlias = true,
        );
      }
      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final labelPosition = delta == Offset.zero
          ? origin + const Offset(8, -18)
          : end + delta / 7 - const Offset(4, 6);
      painter.paint(canvas, labelPosition);
    }

    canvas.drawCircle(
      origin,
      43,
      Paint()
        ..color = colors.surfaceContainerHighest.withValues(alpha: .86)
        ..isAntiAlias = true,
    );
    canvas.drawCircle(
      origin,
      43,
      Paint()
        ..color = colors.outline.withValues(alpha: .38)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..isAntiAlias = true,
    );
    axis(const Vector3(1, 0, 0), 'X', Colors.redAccent);
    axis(const Vector3(0, 1, 0), 'Y', Colors.greenAccent.shade700);
    axis(const Vector3(0, 0, 1), 'Z', Colors.lightBlueAccent);
    canvas.drawCircle(origin, 3, Paint()..color = colors.onSurface);
  }

  void _paintMeshBatched(Canvas canvas, CadSceneEntity entity, Size size) {
    // Shaded is deliberately opaque: partial alpha made dense STL meshes look
    // hollow because Flutter's 2D canvas has no per-triangle depth buffer.
    final alpha = style == CadRenderStyle.transparent
        ? .22
        : entity.transparent || entity.kind == CadSceneEntityKind.preview
        ? .34
        : 1.0;
    var cache = meshRenderCaches[entity.id];
    if (cache == null ||
        !identical(cache.nodesSource, entity.geometry['nodes']) ||
        !identical(cache.trianglesSource, entity.geometry['triangles'])) {
      cache = _MeshRenderCache.from(entity);
      meshRenderCaches[entity.id] = cache;
    }
    final matrix = camera.viewProjectionMatrix.values;
    final isHovered = entity.id == hoveredEntityId;
    final foregroundColor = switch ((
      entity.selected,
      isHovered,
      entity.kind,
      entity.geometry['displayColor'],
    )) {
      (true, _, _, _) => const Color(0xffffb02e),
      (_, true, _, _) => const Color(0xff38d6ff),
      (_, _, _, 'destructiveRed') => Colors.redAccent,
      (_, _, CadSceneEntityKind.preview, _) => const Color(0xffff9f43),
      (_, _, CadSceneEntityKind.surface, _) => const Color(0xff53a8a6),
      (_, _, CadSceneEntityKind.solid, _) => const Color(0xff8296a3),
      _ => const Color(0xff7899ad),
    };
    final foreground = foregroundColor.toARGB32();
    final analysisMode = entity.geometry['surfaceAnalysisMode'] as String?;
    final alphaByte = (alpha * 255).round();
    final forward = (camera.target - camera.eye).normalized;
    final right = forward.cross(camera.up).normalized;
    final cameraUp = right.cross(forward).normalized;
    final towardEye = forward * -1;
    final keyLight =
        (towardEye * .78 + cameraUp * .48 - right * .22).normalized;
    final fillLight =
        (towardEye * .42 - cameraUp * .28 + right * .66).normalized;
    final viewKey = Object.hash(
      forward.x.toStringAsFixed(4),
      forward.y.toStringAsFixed(4),
      forward.z.toStringAsFixed(4),
      cameraUp.x.toStringAsFixed(4),
      cameraUp.y.toStringAsFixed(4),
      cameraUp.z.toStringAsFixed(4),
    );
    final colorKey = Object.hash(foreground, alphaByte, analysisMode, viewKey);
    var minX = double.infinity,
        minY = double.infinity,
        maxX = double.negativeInfinity,
        maxY = double.negativeInfinity;
    for (final chunk in cache.chunks) {
      for (var i = 0, p = 0; i < chunk.xyz.length; i += 3, p += 2) {
        final x = chunk.xyz[i], y = chunk.xyz[i + 1], z = chunk.xyz[i + 2];
        final w = matrix[12] * x + matrix[13] * y + matrix[14] * z + matrix[15];
        final px =
            (matrix[0] * x + matrix[1] * y + matrix[2] * z + matrix[3]) / w;
        final py =
            (matrix[4] * x + matrix[5] * y + matrix[6] * z + matrix[7]) / w;
        final pz =
            (matrix[8] * x + matrix[9] * y + matrix[10] * z + matrix[11]) / w;
        chunk.screen[p] = (px + 1) * size.width / 2;
        chunk.screen[p + 1] = (1 - py) * size.height / 2;
        chunk.depth[i ~/ 3] = pz;
        if (chunk.screen[p].isFinite && chunk.screen[p + 1].isFinite) {
          minX = math.min(minX, chunk.screen[p]);
          maxX = math.max(maxX, chunk.screen[p]);
          minY = math.min(minY, chunk.screen[p + 1]);
          maxY = math.max(maxY, chunk.screen[p + 1]);
        }
      }
      chunk.updateDepthOrder();
    }
    if (style == CadRenderStyle.shaded &&
        minX.isFinite &&
        minY.isFinite &&
        maxX > minX &&
        maxY > minY) {
      final width = (maxX - minX).clamp(12.0, size.width * .75);
      final height = (maxY - minY).clamp(12.0, size.height * .75);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset((minX + maxX) / 2, maxY + height * .025),
          width: width * .72,
          height: math.max(5, height * .11),
        ),
        Paint()
          ..color = Colors.black.withValues(alpha: .24)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
          ..isAntiAlias = true,
      );
    }
    final orderedChunks = cache.chunks.toList(growable: false)
      ..sort((a, b) => b.averageDepth.compareTo(a.averageDepth));
    for (final chunk in orderedChunks) {
      if (chunk.colorKey != colorKey) {
        for (var i = 0; i < chunk.colors.length; i++) {
          final normalOffset = i * 3;
          var normal = Vector3(
            chunk.normals[normalOffset],
            chunk.normals[normalOffset + 1],
            chunk.normals[normalOffset + 2],
          );
          if (normal.dot(towardEye) < 0) normal = normal * -1;
          final key = math.max(0.0, normal.dot(keyLight));
          final fill = math.max(0.0, normal.dot(fillLight));
          final facing = math.max(0.0, normal.dot(towardEye));
          final t = (.13 + .59 * key + .18 * fill + .07 * facing).clamp(
            .10,
            .97,
          );
          if (analysisMode != null) {
            final x = chunk.xyz[i * 3];
            final y = chunk.xyz[i * 3 + 1];
            final z = chunk.xyz[i * 3 + 2];
            final Color analysisColor = switch (analysisMode) {
              'zebra' =>
                math.sin((x + y + z + camera.eye.x * .03) * .12) > 0
                    ? Colors.white
                    : Colors.black,
              'reflection' => Color.lerp(
                Colors.indigo.shade900,
                Colors.white,
                (math.sin(t * 5 + z * .03) * .5 + .5),
              )!,
              'curvature' => Color.lerp(
                Colors.blue,
                Colors.red,
                t.clamp(0.0, 1.0),
              )!,
              'gaussian' =>
                t < .48
                    ? Color.lerp(Colors.blue, Colors.white, t / .48)!
                    : Color.lerp(Colors.white, Colors.red, (t - .48) / .52)!,
              'draft' =>
                t < .35
                    ? Colors.red
                    : t < .58
                    ? Colors.yellow
                    : Colors.green,
              _ => Color(foreground),
            };
            chunk.colors[i] = analysisColor.withValues(alpha: alpha).toARGB32();
            continue;
          }
          chunk.colors[i] = CadTonalSeparation.shade(
            foregroundColor,
            t,
            alpha: alpha,
          ).toARGB32();
        }
        chunk.colorKey = colorKey;
      }
      final renderedVertices = Vertices.raw(
        VertexMode.triangles,
        chunk.screen,
        colors: chunk.colors,
        indices: chunk.drawIndices,
      );
      canvas.drawVertices(
        renderedVertices,
        BlendMode.srcOver,
        Paint()..color = Colors.white,
      );
      renderedVertices.dispose();
    }
  }

  void _projectMesh(
    CadSceneEntity entity,
    Size size,
    List<_ProjectedTriangle> output,
  ) {
    final nodes = (entity.geometry['nodes'] as List).cast<num>();
    final indices = (entity.geometry['triangles'] as List).cast<num>();
    Vector3 vertex(int index) => Vector3(
      nodes[index * 3].toDouble(),
      nodes[index * 3 + 1].toDouble(),
      nodes[index * 3 + 2].toDouble(),
    );
    Offset screen(Vector3 point) {
      final p = camera.viewProjectionMatrix.transformPoint(point);
      return Offset((p.x + 1) * size.width / 2, (1 - p.y) * size.height / 2);
    }

    for (var index = 0; index + 2 < indices.length; index += 3) {
      final a = vertex(indices[index].toInt());
      final b = vertex(indices[index + 1].toInt());
      final c = vertex(indices[index + 2].toInt());
      final viewA = camera.viewMatrix.transformPoint(a);
      final viewB = camera.viewMatrix.transformPoint(b);
      final viewC = camera.viewMatrix.transformPoint(c);
      if (viewA.z >= -camera.nearPlane &&
          viewB.z >= -camera.nearPlane &&
          viewC.z >= -camera.nearPlane) {
        continue;
      }
      final normal = (b - a).cross(c - a).normalized;
      final key = normal.dot(const Vector3(.32, -.48, .81).normalized).abs();
      final fill = normal.dot(const Vector3(-.72, .22, .36).normalized).abs();
      final intensity = (.14 + .61 * key + .19 * fill).clamp(.12, .96);
      final pa = screen(a), pb = screen(b), pc = screen(c);
      if (![pa, pb, pc].every((p) => p.dx.isFinite && p.dy.isFinite)) continue;
      output.add(
        _ProjectedTriangle(
          Path()
            ..moveTo(pa.dx, pa.dy)
            ..lineTo(pb.dx, pb.dy)
            ..lineTo(pc.dx, pc.dy)
            ..close(),
          (viewA.z + viewB.z + viewC.z) / 3,
          intensity,
          entity.selected,
        ),
      );
    }
  }

  void _paintReference(Canvas canvas, Size size, CadSceneEntity entity) {
    Vector3 vector(Object? value) {
      final values = value as List;
      return Vector3(
        (values[0] as num).toDouble(),
        (values[1] as num).toDouble(),
        (values[2] as num).toDouble(),
      );
    }

    Offset project(Vector3 value) {
      final point = camera.viewProjectionMatrix.transformPoint(value);
      return Offset(
        (point.x + 1) * size.width / 2,
        (1 - point.y) * size.height / 2,
      );
    }

    void line(Vector3 from, Vector3 to, Color color, {double width = 1.5}) {
      canvas.drawLine(
        project(from),
        project(to),
        Paint()
          ..color = color
          ..strokeWidth = width,
      );
    }

    final scale = (camera.eye - camera.target).length * .16;
    final isWorld = entity.id.contains(':world:');
    final worldScale = _worldReferenceScale();
    final highlighted = entity.selected || entity.id == hoveredEntityId;
    if ((entity.kind == CadSceneEntityKind.surface ||
            entity.kind == CadSceneEntityKind.preview) &&
        entity.geometry['surfaceKind'] == 'plane') {
      final parameters = (entity.geometry['parameters'] as Map)
          .cast<String, dynamic>();
      final origin = vector(parameters['origin']);
      final normal = vector(parameters['normal']).normalized;
      final x = normal
          .cross(
            normal.z.abs() < .9
                ? const Vector3(0, 0, 1)
                : const Vector3(0, 1, 0),
          )
          .normalized;
      final y = normal.cross(x).normalized;
      final halfWidth =
          ((parameters['width'] as num?)?.toDouble() ?? scale) / 2;
      final halfHeight =
          ((parameters['height'] as num?)?.toDouble() ?? scale) / 2;
      final path = Path()
        ..addPolygon(
          [
            origin - x * halfWidth - y * halfHeight,
            origin + x * halfWidth - y * halfHeight,
            origin + x * halfWidth + y * halfHeight,
            origin - x * halfWidth + y * halfHeight,
          ].map(project).toList(),
          true,
        );
      final preview = entity.kind == CadSceneEntityKind.preview;
      final activeColor = highlighted
          ? (entity.selected
                ? const Color(0xffffb02e)
                : const Color(0xff38d6ff))
          : preview
          ? const Color(0xffff9f43)
          : const Color(0xff53a8a6);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.fill
          ..color = activeColor.withValues(alpha: preview ? .22 : .48),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = highlighted
              ? 1.8
              : preview
              ? 1.25
              : .8
          ..color = activeColor,
      );
      return;
    }
    switch (entity.kind) {
      case CadSceneEntityKind.point:
        canvas.drawCircle(
          project(vector(entity.geometry['position'])),
          entity.selected ? 7 : 5,
          Paint()..color = colors.tertiary,
        );
      case CadSceneEntityKind.axis:
        final origin = vector(entity.geometry['origin']);
        final direction = vector(entity.geometry['direction']).normalized;
        final length = isWorld
            ? worldScale
            : (entity.geometry['visualLength'] as num?)?.toDouble() ??
                  scale * 2;
        final axisColor = switch (entity.geometry['axisColor']) {
          'x' => Colors.red,
          'y' => Colors.green,
          'z' => Colors.blue,
          _ => colors.secondary,
        };
        final start = isWorld ? origin : origin - direction * (length / 2);
        final end = isWorld
            ? origin + direction * length
            : origin + direction * (length / 2);
        line(
          start,
          end,
          highlighted ? colors.tertiary : axisColor,
          width: highlighted ? 2.2 : 1.15,
        );
        if (isWorld) {
          final label = switch (entity.geometry['axisColor']) {
            'x' => 'X',
            'y' => 'Y',
            'z' => 'Z',
            _ => '',
          };
          if (label.isNotEmpty) {
            final text = TextPainter(
              text: TextSpan(
                text: label,
                style: TextStyle(
                  color: highlighted ? colors.tertiary : axisColor,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              textDirection: TextDirection.ltr,
            )..layout();
            text.paint(canvas, project(end) - const Offset(4, 7));
          }
        }
      case CadSceneEntityKind.plane:
        final origin = vector(entity.geometry['origin']);
        final normal = vector(entity.geometry['normal']).normalized;
        final preferred = entity.geometry['xDirection'];
        final x = preferred is List
            ? vector(preferred).normalized
            : normal
                  .cross(
                    normal.z.abs() < .9
                        ? const Vector3(0, 0, 1)
                        : const Vector3(0, 1, 0),
                  )
                  .normalized;
        final y = normal.cross(x).normalized;
        final extent = isWorld
            ? worldScale * .58
            : ((entity.geometry['visualSize'] as num?)?.toDouble() ??
                      scale * 1.4) /
                  2;
        final planeColor = switch (entity.geometry['planeColor']) {
          'xy' => Colors.blue,
          'xz' => Colors.green,
          'yz' => Colors.red,
          _ => colors.secondary,
        };
        final corners = [
          origin - x * extent - y * extent,
          origin + x * extent - y * extent,
          origin + x * extent + y * extent,
          origin - x * extent + y * extent,
        ].map(project).toList();
        final path = Path()..addPolygon(corners, true);
        canvas.drawPath(
          path,
          Paint()
            ..color = planeColor.withValues(alpha: highlighted ? .11 : .024)
            ..style = PaintingStyle.fill,
        );
        canvas.drawPath(
          path,
          Paint()
            ..color = (highlighted ? colors.tertiary : planeColor).withValues(
              alpha: highlighted ? .92 : .25,
            )
            ..strokeWidth = highlighted ? 1.55 : .55
            ..style = PaintingStyle.stroke
            ..isAntiAlias = true,
        );
      case CadSceneEntityKind.coordinateSystem:
        if (isWorld) break;
        final origin = vector(entity.geometry['origin']);
        line(
          origin,
          origin + vector(entity.geometry['xAxis']).normalized * scale,
          Colors.red,
        );
        line(
          origin,
          origin + vector(entity.geometry['yAxis']).normalized * scale,
          Colors.green,
        );
        line(
          origin,
          origin + vector(entity.geometry['zAxis']).normalized * scale,
          Colors.blue,
        );
      case CadSceneEntityKind.curve:
      case CadSceneEntityKind.sketch:
      case CadSceneEntityKind.preview:
        final rawSegments = entity.geometry['segments'];
        if (rawSegments is List) {
          final referenceColor = entity.selected
              ? const Color(0xffffb02e)
              : highlighted
              ? const Color(0xff38d6ff)
              : entity.kind == CadSceneEntityKind.preview
              ? const Color(0xffff9f43)
              : entity.kind == CadSceneEntityKind.sketch
              ? const Color(0xff7cda72)
              : const Color(0xff55b8df);
          final paint = Paint()
            ..color = referenceColor
            ..strokeWidth = entity.selected
                ? 2.1
                : (entity.geometry['strokeWidth'] as num?)?.toDouble() ?? 1.35
            ..strokeCap = StrokeCap.round
            ..isAntiAlias = true;
          for (final raw in rawSegments) {
            final segment = raw as List;
            line(
              vector(segment[0]),
              vector(segment[1]),
              paint.color,
              width: paint.strokeWidth,
            );
          }
          break;
        }
        final points = (entity.geometry['points'] as List? ?? const [])
            .map(vector)
            .map(project)
            .toList();
        if (points.length > 1) {
          final displayColor = switch (entity.geometry['displayColor']) {
            'destructiveRed' => Colors.redAccent,
            'splineMagenta' => const Color(0xffd489ff),
            'sketchGreen' => const Color(0xff7cda72),
            'previewOrange' => const Color(0xffff9f43),
            'sectionBlue' => const Color(0xff4cb9e8),
            _ => const Color(0xff55b8df),
          };
          canvas.drawPoints(
            PointMode.polygon,
            points,
            Paint()
              ..color = entity.selected
                  ? const Color(0xffffb02e)
                  : highlighted
                  ? const Color(0xff38d6ff)
                  : displayColor
              ..strokeWidth =
                  (entity.geometry['strokeWidth'] as num?)?.toDouble() ?? 2
              ..strokeCap = StrokeCap.round
              ..isAntiAlias = true,
          );
        }
      case CadSceneEntityKind.mesh:
      case CadSceneEntityKind.surface:
      case CadSceneEntityKind.solid:
      case CadSceneEntityKind.gizmo:
        break;
    }
  }

  double _worldReferenceScale() {
    var minX = double.infinity, minY = double.infinity, minZ = double.infinity;
    var maxX = double.negativeInfinity;
    var maxY = double.negativeInfinity;
    var maxZ = double.negativeInfinity;
    for (final entity in scene.entities.where(
      (item) => item.visible && !item.id.contains(':world:'),
    )) {
      final nodes = entity.geometry['nodes'];
      if (nodes is! List) continue;
      for (var i = 0; i + 2 < nodes.length; i += 3) {
        final x = (nodes[i] as num).toDouble();
        final y = (nodes[i + 1] as num).toDouble();
        final z = (nodes[i + 2] as num).toDouble();
        minX = math.min(minX, x);
        minY = math.min(minY, y);
        minZ = math.min(minZ, z);
        maxX = math.max(maxX, x);
        maxY = math.max(maxY, y);
        maxZ = math.max(maxZ, z);
      }
    }
    if (minX.isFinite && maxX.isFinite) {
      final diagonal = Vector3(maxX - minX, maxY - minY, maxZ - minZ).length;
      if (diagonal > 1e-9) return diagonal * .12;
    }
    return math.max((camera.eye - camera.target).length * .075, .05);
  }

  @override
  bool shouldRepaint(covariant _CadScenePainter oldDelegate) =>
      oldDelegate.style != style ||
      oldDelegate.colors != colors ||
      oldDelegate.showGrid != showGrid ||
      oldDelegate.hoveredEntityId != hoveredEntityId ||
      oldDelegate.rotationCenterMarker != rotationCenterMarker;
}
