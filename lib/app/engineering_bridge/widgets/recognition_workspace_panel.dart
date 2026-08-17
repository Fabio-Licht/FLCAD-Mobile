import 'package:flutter/material.dart';

import '../../engineering_bridge/operational_reverse_engineering_controller.dart';
import '../../../core/adaptive_surface/models/surface_geometry.dart';

class RecognitionWorkspacePanel extends StatelessWidget {
  const RecognitionWorkspacePanel({
    super.key,
    required this.controller,
    this.onApplyAlignment,
  });
  final OperationalReverseEngineeringController controller;
  final Future<void> Function()? onApplyAlignment;

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
          if (controller.canAlign) ...[
            Text(
              'Alignment Workbench',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.straighten),
                  label: const Text('Axis'),
                  onPressed: controller.createAxis,
                ),
                ActionChip(
                  avatar: const Icon(Icons.adjust),
                  label: const Text('Origin'),
                  onPressed: controller.createPoint,
                ),
                ActionChip(
                  avatar: const Icon(Icons.threed_rotation),
                  label: const Text('CSYS'),
                  onPressed: controller.createCoordinateSystem,
                ),
              ],
            ),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'XY', label: Text('XY')),
                ButtonSegment(value: 'XZ', label: Text('XZ')),
                ButtonSegment(value: 'YZ', label: Text('YZ')),
              ],
              emptySelectionAllowed: true,
              selected: {
                if (controller.alignmentTarget != null)
                  controller.alignmentTarget!,
              },
              onSelectionChanged: (value) {
                if (value.isNotEmpty) {
                  controller.previewAlignment(value.first);
                }
              },
            ),
            if (controller.alignmentTransform != null)
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: onApplyAlignment ?? controller.applyAlignment,
                      child: const Text('Apply Alignment'),
                    ),
                  ),
                  TextButton(
                    onPressed: controller.cancelAlignment,
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            const Divider(),
          ],
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
              'Select the mesh in the viewport to grow a homogeneous region.',
            ),
          if (controller.activeContext?.region case final region?) ...[
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recognition MeshRegion',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text('${region.triangleIndices.length} triangles'),
                    Text('Area ${region.area.toStringAsFixed(3)}'),
                    if (controller.hypotheses.isNotEmpty)
                      Text(
                        'Confidence ${(controller.hypotheses.first.recognition.dna.confidence * 100).toStringAsFixed(1)}%',
                      ),
                  ],
                ),
              ),
            ),
          ],
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
            if (controller.hypotheses.any(
              (item) => item.recognition.winner.type.name == 'plane',
            ))
              FilledButton.icon(
                onPressed: controller.busy
                    ? null
                    : () async {
                        final plane = controller.hypotheses.firstWhere(
                          (item) =>
                              item.recognition.winner.type.name == 'plane',
                        );
                        controller.decide(
                          plane.recognition.id,
                          RecognitionDecision.accepted,
                        );
                        await controller.createRecognizedPlane();
                      },
                icon: const Icon(Icons.verified_outlined),
                label: const Text('Accept Plane & Create Reference'),
              ),
            if (controller.hypotheses.any(
              (item) => item.recognition.winner.type.name != 'plane',
            ))
              FilledButton.icon(
                onPressed: controller.busy
                    ? null
                    : () async {
                        final primitive = controller.hypotheses.firstWhere(
                          (item) =>
                              item.recognition.winner.type.name != 'plane',
                        );
                        controller.decide(
                          primitive.recognition.id,
                          RecognitionDecision.accepted,
                        );
                        await controller.createRecognizedReference();
                      },
                icon: const Icon(Icons.verified_outlined),
                label: Text(
                  'Accept ${controller.hypotheses.firstWhere((item) => item.recognition.winner.type.name != 'plane').recognition.winner.type.name} & Create Reference',
                ),
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
                  SurfaceKind.cone,
                  SurfaceKind.sphere,
                  SurfaceKind.torus,
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
            if (controller.hypotheses.any(
              (item) =>
                  item.recognition.winner.type.name == 'plane' &&
                  controller.decisions[item.recognition.id] ==
                      RecognitionDecision.accepted,
            ))
              FilledButton.icon(
                onPressed: controller.busy
                    ? null
                    : controller.createRecognizedPlane,
                icon: const Icon(Icons.crop_16_9),
                label: const Text('Create Plane Reference'),
              ),
          ],
          if (controller.canAlign) ...[
            const Divider(),
            Text(
              'Alignment Workbench',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Text(
              'Create the axis, origin and coordinate system from the approved plane.',
            ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                OutlinedButton.icon(
                  onPressed: controller.createAxis,
                  icon: const Icon(Icons.straighten),
                  label: const Text('Create Axis'),
                ),
                OutlinedButton.icon(
                  onPressed: controller.createPoint,
                  icon: const Icon(Icons.adjust),
                  label: const Text('Create Origin'),
                ),
                OutlinedButton.icon(
                  onPressed: controller.createCoordinateSystem,
                  icon: const Icon(Icons.threed_rotation),
                  label: const Text('Create CSYS'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Align approved plane to:'),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'XY', label: Text('XY')),
                ButtonSegment(value: 'XZ', label: Text('XZ')),
                ButtonSegment(value: 'YZ', label: Text('YZ')),
              ],
              emptySelectionAllowed: true,
              selected: {
                if (controller.alignmentTarget != null)
                  controller.alignmentTarget!,
              },
              onSelectionChanged: (value) {
                if (value.isNotEmpty) controller.previewAlignment(value.first);
              },
            ),
            if (controller.alignmentTransform != null)
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: controller.busy
                          ? null
                          : (onApplyAlignment ?? controller.applyAlignment),
                      icon: const Icon(Icons.check),
                      label: const Text('Apply Alignment'),
                    ),
                  ),
                  TextButton(
                    onPressed: controller.cancelAlignment,
                    child: const Text('Cancel'),
                  ),
                ],
              ),
          ],
        ],
      );
    },
  );
}
