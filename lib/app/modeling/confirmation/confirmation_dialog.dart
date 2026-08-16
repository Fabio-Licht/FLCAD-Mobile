import 'package:flutter/material.dart';

import '../interaction/interaction_context.dart';

class EngineeringConfirmationDialog extends StatelessWidget {
  const EngineeringConfirmationDialog({super.key, required this.preview});
  final EngineeringPreview preview;
  static Future<bool> show(
    BuildContext context,
    EngineeringPreview preview,
  ) async =>
      await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => EngineeringConfirmationDialog(preview: preview),
      ) ??
      false;
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Confirm ${preview.kind}'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(preview.justification),
        const SizedBox(height: 8),
        Text('Confidence: ${(preview.confidence * 100).toStringAsFixed(1)}%'),
        const SizedBox(height: 8),
        for (final evidence in preview.evidence) Text('• $evidence'),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, true),
        child: const Text('Accept'),
      ),
    ],
  );
}
