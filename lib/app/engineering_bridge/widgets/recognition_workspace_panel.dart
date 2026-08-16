import 'package:flutter/material.dart';

import '../../engineering_bridge/operational_reverse_engineering_controller.dart';
import '../../../core/adaptive_surface/models/surface_geometry.dart';

class RecognitionWorkspacePanel extends StatelessWidget {
  const RecognitionWorkspacePanel({super.key, required this.controller});
  final OperationalReverseEngineeringController controller;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      if (controller.busy) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.error != null) {
        return Text(
          controller.error!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (controller.canDetect)
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final type in const [
                  'plane',
                  'cylinder',
                  'cone',
                  'sphere',
                  'torus',
                ])
                  ActionChip(
                    label: Text(
                      'Detect ${type[0].toUpperCase()}${type.substring(1)}',
                    ),
                    onPressed: () => controller.detect(type),
                  ),
              ],
            )
          else
            const Text(
              'Select a mesh triangle in the viewport before running detection.',
            ),
          if (controller.hypotheses.isEmpty && controller.canDetect) ...[
            const SizedBox(height: 8),
            const Text('No hypothesis of the selected type was detected.'),
          ],
          if (controller.hypotheses.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${controller.hypotheses.length} hypotheses',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            for (final primitive in controller.hypotheses)
              Card(
                child: ExpansionTile(
                  title: Text(primitive.recognition.winner.type.name),
                  subtitle: Text(
                    'Confidence ${(primitive.recognition.dna.confidence * 100).toStringAsFixed(1)}% · Score ${(primitive.recognition.explanation.score * 100).toStringAsFixed(1)}%',
                  ),
                  childrenPadding: const EdgeInsets.all(12),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(primitive.recognition.explanation.why),
                    ),
                    for (final evidence
                        in primitive.recognition.explanation.evidence)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '• ${evidence.description}: ${evidence.value.toStringAsFixed(4)}',
                        ),
                      ),
                    if (primitive.recognition.alternatives.isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Alternatives: ${primitive.recognition.alternatives.map((item) => item.type.name).join(', ')}',
                        ),
                      ),
                    SegmentedButton<RecognitionDecision>(
                      segments: const [
                        ButtonSegment(
                          value: RecognitionDecision.pending,
                          label: Text('Pending'),
                        ),
                        ButtonSegment(
                          value: RecognitionDecision.accepted,
                          label: Text('Accept'),
                        ),
                        ButtonSegment(
                          value: RecognitionDecision.rejected,
                          label: Text('Reject'),
                        ),
                      ],
                      selected: {
                        controller.decisions[primitive.recognition.id] ??
                            RecognitionDecision.pending,
                      },
                      onSelectionChanged: (value) => controller.decide(
                        primitive.recognition.id,
                        value.first,
                      ),
                    ),
                  ],
                ),
              ),
            Wrap(
              spacing: 6,
              children: [
                for (final kind in const [
                  SurfaceKind.cylinder,
                  SurfaceKind.sphere,
                ])
                  if (controller.canCreateRecognizedSurface(kind))
                    FilledButton(
                      onPressed: controller.busy
                          ? null
                          : () => controller.createRecognizedSurface(kind),
                      child: Text('Create ${kind.name} Surface'),
                    ),
              ],
            ),
          ],
        ],
      );
    },
  );
}
