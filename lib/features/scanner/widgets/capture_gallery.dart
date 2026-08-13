import 'dart:io';

import 'package:flutter/material.dart';

import '../../../models/captured_image.dart';
import 'image_viewer_screen.dart';

class CaptureGallery extends StatelessWidget {
  const CaptureGallery({
    super.key,
    required this.images,
    required this.onDelete,
  });

  final List<CapturedImage> images;
  final ValueChanged<CapturedImage> onDelete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (context, index) {
          final image = images[index];

          final bool isLast = index == images.length - 1;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ImageViewerScreen(imagePath: image.path),
                  ),
                );
              },

              onLongPress: () async {
                final remove = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Excluir foto"),
                    content: const Text("Deseja realmente excluir esta foto?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancelar"),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Excluir"),
                      ),
                    ],
                  ),
                );

                if (remove == true) {
                  onDelete(image);
                }
              },

              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isLast ? Colors.blueAccent : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(image.path),
                    width: 80,
                    height: 80,
                    cacheWidth: 160,
                    cacheHeight: 160,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox(
                      width: 80,
                      height: 80,
                      child: Icon(Icons.broken_image),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
