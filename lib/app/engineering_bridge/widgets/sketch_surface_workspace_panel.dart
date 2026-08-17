import 'package:flutter/material.dart';

import '../../../core/sketch_editor/models/editor_models.dart';
import '../../../core/sketch_constraints/models/constraint_models.dart';
import '../../../core/professional_surface/models/professional_surface_models.dart';

import '../operational_reverse_engineering_controller.dart';

class SketchSurfaceWorkspacePanel extends StatelessWidget {
  const SketchSurfaceWorkspacePanel({
    super.key,
    required this.controller,
    this.onOpenSketch,
    this.onFinishSketch,
  });
  final OperationalReverseEngineeringController controller;
  final Future<void> Function()? onOpenSketch;
  final Future<void> Function()? onFinishSketch;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Stage: ${controller.stage.name}'),
        const SizedBox(height: 8),
        if (controller.error != null)
          Text(
            controller.error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        if (controller.stage == SketchSurfaceStage.idle)
          FilledButton.icon(
            onPressed: controller.busy
                ? null
                : controller.createRecognizedPlane,
            icon: const Icon(Icons.layers_outlined),
            label: const Text('Create approved plane'),
          ),
        if (controller.stage == SketchSurfaceStage.referenceReady) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              OutlinedButton.icon(
                onPressed: controller.busy ? null : controller.createAxis,
                icon: const Icon(Icons.straighten),
                label: const Text('Create Axis'),
              ),
              OutlinedButton.icon(
                onPressed: controller.busy ? null : controller.createPoint,
                icon: const Icon(Icons.adjust),
                label: const Text('Create Point'),
              ),
              OutlinedButton.icon(
                onPressed: controller.busy
                    ? null
                    : controller.createCoordinateSystem,
                icon: const Icon(Icons.threed_rotation),
                label: const Text('Create Coordinate System'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: controller.busy
                ? null
                : (onOpenSketch ?? controller.openSketch),
            icon: const Icon(Icons.edit_note),
            label: const Text('New Sketch'),
          ),
        ],
        if (controller.stage == SketchSurfaceStage.sketchActive) ...[
          Wrap(
            spacing: 4,
            children: [
              for (final tool in const [
                SketchToolType.line,
                SketchToolType.arc,
                SketchToolType.circle,
                SketchToolType.rectangle,
                SketchToolType.spline,
              ])
                ChoiceChip(
                  label: Text(tool.name),
                  selected: controller.activeTool == tool,
                  onSelected: (_) => controller.selectSketchTool(tool),
                ),
            ],
          ),
          Text('${controller.activeTool.name} tool active'),
          Text(
            controller.previewPoints.isEmpty
                ? 'Click the first point in the viewport.'
                : '${controller.previewPoints.length} point(s) captured.',
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: controller.sketchEntities.length < 4 || controller.busy
                ? null
                : controller.constrainRectangle,
            icon: const Icon(Icons.square_foot),
            label: Text(
              'Apply rectangle constraints (${controller.constraints.length})',
            ),
          ),
          Text(
            '${controller.selectedSketchEntityIds.length} Sketch entities selected',
          ),
          Wrap(
            spacing: 4,
            children: [
              for (final type in const [
                SketchConstraintType.coincident,
                SketchConstraintType.parallel,
                SketchConstraintType.perpendicular,
                SketchConstraintType.tangent,
                SketchConstraintType.horizontal,
                SketchConstraintType.vertical,
                SketchConstraintType.equal,
                SketchConstraintType.radius,
                SketchConstraintType.diameter,
                SketchConstraintType.distance,
                SketchConstraintType.angle,
              ])
                ActionChip(
                  label: Text(type.name),
                  onPressed: controller.selectedSketchEntityIds.isEmpty
                      ? null
                      : () => controller.applyConstraint(
                          type,
                          value: switch (type) {
                            SketchConstraintType.radius ||
                            SketchConstraintType.diameter ||
                            SketchConstraintType.distance => 10,
                            SketchConstraintType.angle => 1.5707963267948966,
                            _ => null,
                          },
                        ),
                ),
            ],
          ),
          FilledButton.icon(
            onPressed: controller.sketchEntities.isEmpty || controller.busy
                ? null
                : (onFinishSketch ?? controller.finishSketch),
            icon: const Icon(Icons.done),
            label: const Text('Finish Sketch'),
          ),
        ],
        if (controller.stage == SketchSurfaceStage.sketchFinished)
          FilledButton.icon(
            onPressed: controller.busy ? null : controller.previewPlanarSurface,
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('Generate Surface Preview'),
          ),
        if (controller.stage == SketchSurfaceStage.surfacePreview) ...[
          if (controller.surfacePlan != null) ...[
            Text(
              'Quality: ${(controller.surfacePlan!.candidates.first.quality * 100).toStringAsFixed(1)}%',
            ),
            Text(
              'Continuity: ${controller.surfacePlan!.candidates.first.predictedContinuity.name}',
            ),
            Text(controller.surfacePlan!.candidates.first.justification),
          ],
          FilledButton.icon(
            onPressed: controller.busy ? null : controller.confirmSurface,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Confirm Surface'),
          ),
        ],
        if (controller.stage == SketchSurfaceStage.surfaceGenerated)
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.check_circle),
            title: Text('CAD Surface generated'),
            subtitle: Text('Registered, persisted and visible in the scene.'),
          ),
        if (controller.geometrySelection.shapeHandles.isNotEmpty) ...[
          const Divider(),
          Text(
            '${controller.geometrySelection.shapeHandles.length} kernel shape(s) selected',
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tool in const [
                ProfessionalSurfaceTool.loft,
                ProfessionalSurfaceTool.sweep,
                ProfessionalSurfaceTool.fill,
                ProfessionalSurfaceTool.patch,
                ProfessionalSurfaceTool.blend,
              ])
                if (controller.canPreviewProfessional(tool))
                  OutlinedButton(
                    onPressed: controller.busy
                        ? null
                        : () => controller.previewProfessionalSurface(tool),
                    child: Text(
                      tool.name[0].toUpperCase() + tool.name.substring(1),
                    ),
                  ),
            ],
          ),
        ],
        if (controller.professionalSurfacePreview != null)
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: controller.busy
                      ? null
                      : controller.confirmProfessionalSurface,
                  child: const Text('Confirm Surface'),
                ),
              ),
              TextButton(
                onPressed: controller.busy
                    ? null
                    : controller.cancelProfessionalSurface,
                child: const Text('Cancel'),
              ),
            ],
          ),
        const Divider(),
        Wrap(
          spacing: 6,
          children: [
            IconButton(
              tooltip: 'Undo',
              onPressed: controller.busy ? null : controller.undo,
              icon: const Icon(Icons.undo),
            ),
            IconButton(
              tooltip: 'Redo',
              onPressed: controller.busy ? null : controller.redo,
              icon: const Icon(Icons.redo),
            ),
            IconButton(
              tooltip: 'Save Project',
              onPressed: controller.busy ? null : controller.saveProject,
              icon: const Icon(Icons.save_outlined),
            ),
          ],
        ),
        if (controller.busy) const LinearProgressIndicator(),
      ],
    ),
  );
}
