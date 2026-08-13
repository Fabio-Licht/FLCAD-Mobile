import 'package:flutter/material.dart';

class CaptureProgress extends StatelessWidget {
  const CaptureProgress({
    super.key,
    required this.currentPhotos,
    required this.targetPhotos,
  });

  final int currentPhotos;
  final int targetPhotos;

  @override
  Widget build(BuildContext context) {
    final progress = (currentPhotos / targetPhotos).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinearProgressIndicator(
          value: progress,
          minHeight: 8,
          borderRadius: BorderRadius.circular(8),
        ),

        const SizedBox(height: 8),

        Center(
          child: Text(
            "$currentPhotos / $targetPhotos fotos",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
