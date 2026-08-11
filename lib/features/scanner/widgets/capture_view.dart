import 'package:flutter/material.dart';

import '../data/camera_service_impl.dart';
import 'camera_preview_widget.dart';

class CaptureView extends StatefulWidget {
  const CaptureView({super.key});

  @override
  State<CaptureView> createState() => _CaptureViewState();
}

class _CaptureViewState extends State<CaptureView> {
  final CameraServiceImpl _camera = CameraServiceImpl();

  late Future<void> _initializeCamera;

  @override
  void initState() {
    super.initState();
    _initializeCamera = _camera.initialize();
  }

  @override
  void dispose() {
    _camera.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializeCamera,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (_camera.controller == null) {
          return const Center(
            child: Text("Camera não disponível"),
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: CameraPreviewWidget(
            controller: _camera.controller!,
          ),
        );
      },
    );
  }
}