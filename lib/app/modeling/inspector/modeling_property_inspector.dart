import 'package:flutter/material.dart';

import '../interaction/interaction_context.dart';
import '../parameters/parameter_panel.dart';

class ModelingPropertyInspector extends StatelessWidget {
  const ModelingPropertyInspector({
    super.key,
    required this.context,
    required this.onParameterChanged,
  });
  final InteractionContext context;
  final void Function(String key, Object? value) onParameterChanged;
  @override
  Widget build(BuildContext context_) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (context.selection.isNotEmpty) ...[
        Text(
          context.selection.first.name,
          style: Theme.of(context_).textTheme.titleMedium,
        ),
        Text(
          '${context.selection.first.type.name} · ${context.selection.first.id}',
        ),
      ],
      if (context.parameters.isNotEmpty) ...[
        const SizedBox(height: 12),
        ParameterPanel(
          values: context.parameters,
          onChanged: onParameterChanged,
        ),
      ],
      if (context.preview case final preview?) ...[
        Text('Confidence ${(preview.confidence * 100).toStringAsFixed(1)}%'),
        Text(preview.justification),
        for (final evidence in preview.evidence) Text('• $evidence'),
      ],
    ],
  );
}
