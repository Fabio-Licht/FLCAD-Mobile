import 'dart:io';

import 'package:flutter/material.dart';

class FLCADImageViewer extends StatelessWidget {
  const FLCADImageViewer({super.key, required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          InteractiveViewer(
            minScale: 1,
            maxScale: 6,
            child: Center(
              child: Image.file(File(imagePath), fit: BoxFit.contain),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: IconButton.filled(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.close),
            ),
          ),
        ],
      ),
    );
  }
}
