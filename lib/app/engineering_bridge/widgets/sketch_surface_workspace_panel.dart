import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/sketch_editor/models/editor_models.dart';
import '../../../core/sketch_editor/snapping/editor_snapping.dart';
import '../../../core/sketch_constraints/models/constraint_models.dart';
import '../../../core/professional_surface/models/professional_surface_models.dart';

import '../operational_reverse_engineering_controller.dart';

class SketchSurfaceWorkspacePanel extends StatefulWidget {
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
  State<SketchSurfaceWorkspacePanel> createState() =>
      _SketchSurfaceWorkspacePanelState();
}

class _SketchSurfaceWorkspacePanelState
    extends State<SketchSurfaceWorkspacePanel> {
  bool showSnapManager = false;
  bool showConstraintGlyphs = true;
  bool snapMesh = false;
  bool snapSection = true;
  bool snapSketch = true;
  bool snapReferences = true;
  bool snapGrid = true;

  OperationalReverseEngineeringController get controller => widget.controller;

  void _toggleSnap(EditorSnapType type, bool enabled) {
    final settings = controller.editorApi?.engine.snapping.settings;
    if (settings == null) return;
    setState(() {
      enabled ? settings.enabled.add(type) : settings.enabled.remove(type);
    });
  }

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
                : (widget.onOpenSketch ?? controller.openSketch),
            icon: const Icon(Icons.edit_note),
            label: const Text('New Sketch'),
          ),
        ],
        if (controller.stage == SketchSurfaceStage.sketchActive) ...[
          _ProfessionalSketchToolbar(
            controller: controller,
            onSnapManager: () =>
                setState(() => showSnapManager = !showSnapManager),
          ),
          if (showSnapManager)
            _SnapManager(
              controller: controller,
              mesh: snapMesh,
              section: snapSection,
              sketch: snapSketch,
              references: snapReferences,
              grid: snapGrid,
              onMesh: (value) => setState(() => snapMesh = value),
              onSection: (value) => setState(() => snapSection = value),
              onSketch: (value) => setState(() => snapSketch = value),
              onReferences: (value) => setState(() => snapReferences = value),
              onGrid: (value) {
                setState(() => snapGrid = value);
                _toggleSnap(EditorSnapType.grid, value);
              },
              onCoreSnap: _toggleSnap,
            ),
          _SketchHeadsUpDisplay(controller: controller),
          _ConstraintStateBanner(controller: controller),
          SwitchListTile.adaptive(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Constraint glyphs'),
            subtitle: const Text(
              'Tangent · Parallel · Coincident · Equal · H/V',
            ),
            value: showConstraintGlyphs,
            onChanged: (value) => setState(() => showConstraintGlyphs = value),
          ),
          if (showConstraintGlyphs)
            _ConstraintGlyphSummary(controller: controller),
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
                : (widget.onFinishSketch ?? controller.finishSketch),
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

class _ProfessionalSketchToolbar extends StatelessWidget {
  const _ProfessionalSketchToolbar({
    required this.controller,
    required this.onSnapManager,
  });
  final OperationalReverseEngineeringController controller;
  final VoidCallback onSnapManager;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text('Sketch', style: TextStyle(fontWeight: FontWeight.w700)),
      for (final group in <String, List<(SketchToolType, IconData)>>{
        'Draw': [
          (SketchToolType.line, Icons.show_chart),
          (SketchToolType.arc, Icons.architecture),
          (SketchToolType.circle, Icons.circle_outlined),
          (SketchToolType.rectangle, Icons.crop_square),
          (SketchToolType.spline, Icons.gesture),
        ],
        'Edit': [
          (SketchToolType.move, Icons.open_with),
          (SketchToolType.rotate, Icons.rotate_right),
          (SketchToolType.scale, Icons.aspect_ratio),
        ],
        'Modify': [
          (SketchToolType.offset, Icons.content_copy),
          (SketchToolType.trim, Icons.content_cut),
          (SketchToolType.extend, Icons.trending_flat),
          (SketchToolType.fillet, Icons.rounded_corner),
          (SketchToolType.chamfer, Icons.change_history),
        ],
      }.entries)
        ExpansionTile(
          dense: true,
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          title: Text(group.key),
          children: [
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final item in group.value)
                  IconButton.filledTonal(
                    tooltip: item.$1.name,
                    isSelected: controller.activeTool == item.$1,
                    onPressed: () => controller.selectSketchTool(item.$1),
                    icon: Icon(item.$2, size: 18),
                  ),
              ],
            ),
          ],
        ),
      ExpansionTile(
        dense: true,
        tilePadding: EdgeInsets.zero,
        title: const Text('Constraints'),
        trailing: const Icon(Icons.rule, size: 18),
        children: [
          Text('${controller.constraints.length} applied constraints'),
        ],
      ),
      ExpansionTile(
        dense: true,
        tilePadding: EdgeInsets.zero,
        title: const Text('Reverse Engineering'),
        trailing: const Icon(Icons.auto_fix_high, size: 18),
        children: const [Text('Section → Polyline → Best Fit Spline')],
      ),
      OutlinedButton.icon(
        onPressed: onSnapManager,
        icon: const Icon(Icons.gps_fixed),
        label: const Text('Snap Manager'),
      ),
    ],
  );
}

class _SnapManager extends StatelessWidget {
  const _SnapManager({
    required this.controller,
    required this.mesh,
    required this.section,
    required this.sketch,
    required this.references,
    required this.grid,
    required this.onMesh,
    required this.onSection,
    required this.onSketch,
    required this.onReferences,
    required this.onGrid,
    required this.onCoreSnap,
  });
  final OperationalReverseEngineeringController controller;
  final bool mesh, section, sketch, references, grid;
  final ValueChanged<bool> onMesh, onSection, onSketch, onReferences, onGrid;
  final void Function(EditorSnapType, bool) onCoreSnap;

  @override
  Widget build(BuildContext context) {
    final enabled =
        controller.editorApi?.engine.snapping.settings.enabled ?? {};
    Widget toggle(String label, bool value, ValueChanged<bool> changed) =>
        FilterChip(label: Text(label), selected: value, onSelected: changed);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Snap sources'),
            Wrap(
              spacing: 4,
              children: [
                toggle('Mesh', mesh, onMesh),
                toggle('Section', section, onSection),
                toggle('Sketch', sketch, onSketch),
                toggle('References', references, onReferences),
                toggle('Grid', grid, onGrid),
              ],
            ),
            const Text('Smart cursor'),
            Wrap(
              spacing: 4,
              children: [
                for (final type in const [
                  EditorSnapType.endpoint,
                  EditorSnapType.midpoint,
                  EditorSnapType.center,
                  EditorSnapType.tangent,
                  EditorSnapType.perpendicular,
                  EditorSnapType.intersection,
                  EditorSnapType.nearest,
                ])
                  FilterChip(
                    label: Text(type.name),
                    selected: enabled.contains(type),
                    onSelected: (value) => onCoreSnap(type, value),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SketchHeadsUpDisplay extends StatelessWidget {
  const _SketchHeadsUpDisplay({required this.controller});
  final OperationalReverseEngineeringController controller;
  @override
  Widget build(BuildContext context) {
    final points = controller.previewPoints;
    final snap = controller.editorApi?.engine.snapping.preview;
    double dx = 0, dy = 0, length = 0, angle = 0;
    if (points.length >= 2) {
      dx = points.last.x - points.first.x;
      dy = points.last.y - points.first.y;
      length = math.sqrt(dx * dx + dy * dy);
      angle = math.atan2(dy, dx) * 180 / math.pi;
    }
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${controller.activeTool.name.toUpperCase()} · HEADS-UP'),
            Text(
              'X ${points.isEmpty ? '0.000' : points.last.x.toStringAsFixed(3)}  '
              'Y ${points.isEmpty ? '0.000' : points.last.y.toStringAsFixed(3)}',
            ),
            Text(
              'Length ${length.toStringAsFixed(3)} mm  ·  '
              'Angle ${angle.toStringAsFixed(2)}°',
            ),
            Text('Snap: ${snap?.type.name ?? 'grid'}'),
            const Text('ENTER confirm  ·  ESC cancel  ·  type value to edit'),
          ],
        ),
      ),
    );
  }
}

class _ConstraintStateBanner extends StatelessWidget {
  const _ConstraintStateBanner({required this.controller});
  final OperationalReverseEngineeringController controller;
  @override
  Widget build(BuildContext context) {
    final dof = controller.editorApi?.dof.remaining ?? 0;
    final quality = controller.editorApi?.quality;
    final over = quality?.factors['overdefined']?.toInt() ?? 0;
    final label = over > 0
        ? 'Over Constrained'
        : dof == 0
        ? 'Fully Constrained'
        : 'Under Constrained · $dof DOF';
    final color = over > 0
        ? Colors.red
        : dof == 0
        ? Colors.green
        : Colors.blue;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.circle, color: color, size: 14),
      title: Text(label),
      subtitle: const Text('Green fully · Blue under · Red over constrained'),
    );
  }
}

class _ConstraintGlyphSummary extends StatelessWidget {
  const _ConstraintGlyphSummary({required this.controller});
  final OperationalReverseEngineeringController controller;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 4,
    runSpacing: 4,
    children: [
      for (final constraint in controller.constraints)
        Tooltip(
          message: constraint.type.name,
          child: Chip(
            avatar: const Icon(Icons.link, size: 14, color: Colors.green),
            label: Text(
              constraint.type.name,
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ),
    ],
  );
}
