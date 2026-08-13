import 'dart:math' as math;

import 'package:flutter/material.dart';

class ReconstructionViewerScreen extends StatefulWidget {
  const ReconstructionViewerScreen({super.key, required this.modelPath});
  final String modelPath;
  @override
  State<ReconstructionViewerScreen> createState() =>
      _ReconstructionViewerScreenState();
}

class _ReconstructionViewerScreenState
    extends State<ReconstructionViewerScreen> {
  final TransformationController _transform = TransformationController();
  double _rotation = 0;
  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _reset() {
    _transform.value = Matrix4.identity();
    setState(() => _rotation = 0);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Reconstruction Viewer'),
      actions: [
        IconButton(
          onPressed: _reset,
          tooltip: 'Reset Camera',
          icon: const Icon(Icons.center_focus_strong),
        ),
      ],
    ),
    body: GestureDetector(
      onHorizontalDragUpdate: (details) =>
          setState(() => _rotation += details.delta.dx * 0.01),
      child: InteractiveViewer(
        transformationController: _transform,
        minScale: 0.4,
        maxScale: 8,
        boundaryMargin: const EdgeInsets.all(200),
        child: Center(
          child: Transform.rotate(
            angle: _rotation,
            child: CustomPaint(
              size: const Size(280, 280),
              painter: _AlphaModelPainter(rotation: _rotation),
            ),
          ),
        ),
      ),
    ),
    bottomNavigationBar: const SafeArea(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          'Arraste para rotacionar • Pinch para zoom • Dois dedos para pan',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}

class _AlphaModelPainter extends CustomPainter {
  const _AlphaModelPainter({required this.rotation});
  final double rotation;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.lightBlueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * .32;
    final points = List.generate(5, (index) {
      final angle = rotation + index * math.pi * 2 / 5 - math.pi / 2;
      return Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
    });
    for (var i = 0; i < points.length; i++) {
      canvas.drawLine(points[i], points[(i + 1) % points.length], paint);
      canvas.drawLine(points[i], center, paint);
    }
    canvas.drawCircle(center, 8, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _AlphaModelPainter oldDelegate) =>
      oldDelegate.rotation != rotation;
}
