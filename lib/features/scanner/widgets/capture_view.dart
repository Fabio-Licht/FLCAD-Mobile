import 'package:flutter/material.dart';

import '../../../models/scan_session.dart';
import '../data/camera_service_impl.dart';
import '../domain/capture_manager.dart';
import 'camera_preview_widget.dart';

class CaptureView extends StatefulWidget {
  const CaptureView({super.key});

  @override
  State<CaptureView> createState() => _CaptureViewState();
}

class _CaptureViewState extends State<CaptureView> {
  final CameraServiceImpl _camera = CameraServiceImpl();

  late Future<void> _initializeCamera;
  late CaptureManager _captureManager;

  @override
  void initState() {
    super.initState();

    _initializeCamera = _initialize();
  }

  Future<void> _initialize() async {
    await _camera.initialize();

    final session = ScanSession(
      id: "session_001",
      projectId: "project_001",
      name: "Nova Sessão",
      createdAt: DateTime.now(),
      status: ScanSessionStatus.created,
      images: const [],
    );

    _captureManager = CaptureManager(session: session, cameraService: _camera);
  }

  @override
  void dispose() {
    _camera.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    final image = await _captureManager.capture();

    if (image == null) {
      debugPrint("Falha ao capturar imagem.");
      return;
    }

    debugPrint("Imagem capturada:");
    debugPrint(image.path);

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Imagem capturada:\n${image.path}")));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializeCamera,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_camera.controller == null) {
          return const Center(child: Text("Câmera não disponível"));
        }

        return Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CameraPreviewWidget(controller: _camera.controller!),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: _capture,
                icon: const Icon(Icons.camera_alt),
                label: const Text("Capturar"),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Fotos: 0",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        );
      },
    );
  }
}
