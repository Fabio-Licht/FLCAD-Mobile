import 'package:flutter/material.dart';

class ParameterPanel extends StatelessWidget {
  const ParameterPanel({
    super.key,
    required this.values,
    required this.onChanged,
  });
  final Map<String, Object?> values;
  final void Function(String key, Object? value) onChanged;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final entry in values.entries)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TextFormField(
            key: ValueKey('parameter-${entry.key}'),
            initialValue: '${entry.value ?? ''}',
            decoration: InputDecoration(labelText: entry.key),
            onChanged: (value) =>
                onChanged(entry.key, double.tryParse(value) ?? value),
          ),
        ),
    ],
  );
}
