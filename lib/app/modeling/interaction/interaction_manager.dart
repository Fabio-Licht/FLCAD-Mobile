import 'package:flutter/foundation.dart';

import '../preview/engineering_preview_engine.dart';
import '../tools/tool_manager.dart';
import '../viewport/viewport_controller.dart';
import 'interaction_context.dart';

class InteractionManager extends ChangeNotifier {
  InteractionManager({
    required this.viewport,
    required this.tools,
    EngineeringPreviewEngine? previews,
  }) : previews = previews ?? const EngineeringPreviewEngine();
  final ModelingViewportController viewport;
  final ToolManager tools;
  final EngineeringPreviewEngine previews;
  InteractionContext context = const InteractionContext();

  void synchronizeSelection() {
    context = context.copyWith(
      stage: viewport.selection.isEmpty
          ? InteractionStage.idle
          : InteractionStage.selected,
      selection: viewport.selection,
      message: viewport.selection.isEmpty
          ? 'Selection cleared'
          : '${viewport.selection.length} entity selected',
    );
    notifyListeners();
  }

  Future<void> activate(String toolId) async {
    final tool = tools.activate(toolId, viewport.selection);
    context = context.copyWith(
      toolId: tool.id,
      parameters: tool.defaultParameters,
      stage: InteractionStage.parameters,
    );
    await updatePreview();
  }

  Future<void> setParameter(String key, Object? value) async {
    context = context.copyWith(
      parameters: {...context.parameters, key: value},
      stage: InteractionStage.parameters,
    );
    await updatePreview();
  }

  Future<void> updatePreview() async {
    final tool = tools.active;
    if (tool == null) throw StateError('No active tool.');
    final value = await previews.build(
      tool,
      viewport.selection,
      context.parameters,
    );
    viewport.showPreview(value);
    context = context.copyWith(
      preview: value,
      stage: InteractionStage.awaitingConfirmation,
      message: 'Preview ready. Confirm to commit.',
    );
    notifyListeners();
  }

  Future<Object?> confirm() async {
    final tool = tools.active;
    final preview = context.preview;
    if (tool == null ||
        preview == null ||
        context.stage != InteractionStage.awaitingConfirmation) {
      throw StateError('A valid preview is required before confirmation.');
    }
    final result = await tool.commit(preview);
    viewport.clearPreview();
    tools.cancel();
    context = context.copyWith(
      stage: InteractionStage.committed,
      clearPreview: true,
      clearTool: true,
      message: 'Operation committed by explicit user confirmation.',
    );
    notifyListeners();
    return result;
  }

  void cancel() {
    viewport.clearPreview();
    tools.cancel();
    context = context.copyWith(
      stage: InteractionStage.cancelled,
      clearPreview: true,
      clearTool: true,
      message: 'Operation cancelled.',
    );
    notifyListeners();
  }
}
