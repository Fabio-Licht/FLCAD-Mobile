import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/storage/image_storage_service.dart';
import '../../../models/captured_image.dart';
import '../../projects/data/project_repository.dart';
import '../../projects/domain/project_manager.dart';
import '../../projects/models/project.dart';
import '../../projects/models/project_summary.dart';
import '../../projects/models/project_status.dart';
import '../../projects/widgets/project_summary_card.dart';
import '../../assistant/domain/smart_assistant_service.dart';
import '../data/camera_service_impl.dart';
import '../domain/camera_service.dart';
import '../domain/capture_manager.dart';
import 'camera_grid_overlay.dart';
import 'camera_preview_widget.dart';
import 'capture_gallery.dart';

class CaptureView extends StatefulWidget {
  const CaptureView({
    super.key,
    required this.project,
    this.cameraService,
    this.projectRepository,
    this.imageStorage,
    this.projectManager,
  });
  final Project project;
  final CameraService? cameraService;
  final ProjectRepository? projectRepository;
  final ImageStorageService? imageStorage;
  final ProjectManager? projectManager;

  @override
  State<CaptureView> createState() => _CaptureViewState();
}

class _CaptureViewState extends State<CaptureView> {
  late final CameraService _camera;
  late final ProjectRepository _projects;
  late final ImageStorageService _images;
  late final ProjectManager _projectManager;
  late final CaptureManager _captureManager;
  late Future<void> _initialization;
  Directory? _jobDirectory;
  List<CapturedImage> _gallery = [];
  double _minZoom = 1;
  double _maxZoom = 1;
  double _zoom = 1;
  double _zoomAtGestureStart = 1;
  bool _processingCapture = false;
  final SmartAssistantService _assistant = SmartAssistantService();
  String? _scaleMethod;
  double? _lastQualityScore;

  @override
  void initState() {
    super.initState();
    _camera = widget.cameraService ?? CameraServiceImpl();
    _projects = widget.projectRepository ?? ProjectRepository();
    _images = widget.imageStorage ?? ImageStorageService.instance;
    _projectManager = widget.projectManager ?? ProjectManager.instance;
    _captureManager = CaptureManager(cameraService: _camera);
    _initialization = _initialize();
  }

  Future<void> _initialize() async {
    _jobDirectory = await _projects.directoryFor(widget.project.id);
    _gallery = await _images.loadImages(_jobDirectory!);
    await _camera.initialize();
    _minZoom = await _camera.getMinZoomLevel();
    _maxZoom = await _camera.getMaxZoomLevel();
    _zoom = _minZoom;
    await _projectManager.setStatus(ProjectStatus.capturing);
  }

  @override
  void dispose() {
    _camera.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (_processingCapture) return;
    if (_scaleMethod == null) {
      final method = await _selectScaleMethod();
      if (method == null) return;
      _scaleMethod = method;
      final scale = await _assistant.analyzeScale(
        projectId: widget.project.id,
        method: method,
      );
      await _projectManager.recordAIAnalysis(
        scale: scale.score,
        confidence: scale.confidence,
      );
    }
    setState(() => _processingCapture = true);
    final temporary = await _captureManager.capture();
    if (temporary == null || _jobDirectory == null) {
      if (mounted) setState(() => _processingCapture = false);
      return;
    }
    try {
      final savedPath = await _images.saveImage(
        sourcePath: temporary.path,
        projectDirectory: _jobDirectory!,
      );
      final saved = CapturedImage(
        id: savedPath.split(Platform.pathSeparator).last,
        path: savedPath,
        capturedAt: temporary.capturedAt,
      );
      if (!mounted) return;
      setState(() => _gallery = [..._gallery, saved]);
      await _projectManager.recordCapture(savedPath);
      await _analyzeSavedCapture(savedPath);
    } catch (error, stackTrace) {
      AppLogger.log(
        'Unable to store capture',
        level: LogLevel.error,
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível salvar a foto.')),
        );
      }
    } finally {
      try {
        await File(temporary.path).delete();
      } catch (_) {}
      if (mounted) {
        setState(() => _processingCapture = false);
      }
    }
  }

  Future<void> _analyzeSavedCapture(String savedPath) async {
    try {
      final quality = await _assistant.analyzeCapture(
        projectId: widget.project.id,
        imagePath: savedPath,
        photoCount: _gallery.length,
      );
      final coverage = await _assistant.analyzeCoverage(
        projectId: widget.project.id,
        photoCount: _gallery.length,
      );
      await _projectManager.recordAIAnalysis(
        quality: quality.score,
        coverage: coverage.score,
        confidence: (quality.confidence + coverage.confidence) / 2,
      );
      if (!mounted) return;
      setState(() => _lastQualityScore = quality.score);
      if (quality.recommendations.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Score ${quality.score.round()}: ${quality.recommendations.first}',
            ),
          ),
        );
      }
    } catch (error, stackTrace) {
      AppLogger.log(
        'Smart Capture analysis failed',
        level: LogLevel.warning,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _deleteImage(CapturedImage image) async {
    try {
      await _images.deleteImage(image);
      if (!mounted) return;
      setState(
        () => _gallery = _gallery
            .where((item) => item.path != image.path)
            .toList(),
      );
      await _projectManager.recordImageDeleted(
        thumbnailPath: _gallery.isEmpty ? null : _gallery.last.path,
      );
    } catch (error, stackTrace) {
      AppLogger.log(
        'Unable to delete image',
        level: LogLevel.error,
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível excluir a foto.')),
        );
      }
    }
  }

  Future<void> _setZoom(double value) async {
    final next = value.clamp(_minZoom, _maxZoom).toDouble();
    _zoom = next;
    if (mounted) setState(() {});
    try {
      await _camera.setZoomLevel(next);
    } catch (error) {
      AppLogger.log(
        'Unable to change zoom',
        level: LogLevel.warning,
        error: error,
      );
    }
  }

  Future<String?> _selectScaleMethod() => showDialog<String>(
    context: context,
    builder: (_) => SimpleDialog(
      title: const Text('Como deseja definir a escala?'),
      children: [
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context, 'markers'),
          child: const Text('Marcadores'),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context, 'calibrated_table'),
          child: const Text('Mesa calibrada'),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context, 'measurements'),
          child: const Text('Medidas'),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context, 'later'),
          child: const Text('Depois'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Câmera não disponível: ${snapshot.error}'),
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final last = _gallery.isEmpty ? 'Nenhuma' : _gallery.last.id;
        return Column(
          children: [
            ProjectSummaryCard(
              project: ProjectSummary.fromProject(widget.project),
              isCurrent: true,
              onOpen: () {},
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: GestureDetector(
                  onScaleStart: (_) => _zoomAtGestureStart = _zoom,
                  onScaleUpdate: (details) =>
                      _setZoom(_zoomAtGestureStart * details.scale),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CameraPreviewWidget(controller: _camera.controller!),
                      const CameraGridOverlay(),
                    ],
                  ),
                ),
              ),
            ),
            if (_maxZoom > _minZoom)
              Slider(
                value: _zoom,
                min: _minZoom,
                max: _maxZoom,
                label: '${_zoom.toStringAsFixed(1)}x',
                onChanged: _setZoom,
              ),
            Text(
              'Última captura: $last',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (_lastQualityScore != null)
              Text('Qualidade inteligente: ${_lastQualityScore!.round()}/100'),
            const SizedBox(height: 8),
            CaptureGallery(images: _gallery, onDelete: _deleteImage),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton.filledTonal(
                  onPressed: () {},
                  icon: const Icon(Icons.photo_library),
                  tooltip: 'Galeria',
                ),
                IconButton.filled(
                  onPressed: _processingCapture ? null : _capture,
                  iconSize: 36,
                  icon: const Icon(Icons.camera_alt),
                  tooltip: 'Capturar',
                ),
                IconButton.filledTonal(
                  onPressed: () {},
                  icon: const Icon(Icons.settings),
                  tooltip: 'Configurações',
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
