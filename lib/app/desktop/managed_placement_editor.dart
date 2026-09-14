import 'package:flutter/material.dart';

import '../runtime/cad_runtime.dart';

/// Incremental world-axis edits; intentionally has no scale or native apply.
class ManagedPlacementEditor extends StatefulWidget {
  const ManagedPlacementEditor({
    super.key,
    required this.runtime,
    required this.entityId,
  });
  final CadRuntime runtime;
  final String entityId;

  @override
  State<ManagedPlacementEditor> createState() => _ManagedPlacementEditorState();
}

class _ManagedPlacementEditorState extends State<ManagedPlacementEditor> {
  final fields = List.generate(6, (_) => TextEditingController(text: '0'));
  bool busy = false;
  String? error;

  @override
  void dispose() {
    for (final field in fields) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> apply({bool reset = false}) async {
    final id = widget.entityId;
    final values = fields.map((f) => double.tryParse(f.text.trim())).toList();
    if (!reset && values.any((v) => v == null || !v.isFinite)) {
      setState(() => error = 'Informe valores numéricos finitos.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (reset) {
        await widget.runtime.resetManagedPlacement(id);
      } else {
        await widget.runtime.transformManagedEntity(
          id,
          translateX: values[0]!,
          translateY: values[1]!,
          translateZ: values[2]!,
          rotateX: values[3]!,
          rotateY: values[4]!,
          rotateZ: values[5]!,
        );
      }
      if (mounted) {
        for (final field in fields) {
          field.text = '0';
        }
      }
    } on FormatException {
      if (mounted) {
        setState(
          () => error = 'Transformação rígida inválida ou limite excedido.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Não foi possível confirmar a transformação.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entity = widget.runtime.document?.entities[widget.entityId];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Placement rígido',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(entity?.data['name'] as String? ?? widget.entityId),
        const Text(
          'Incrementos em eixos de mundo. Translação, depois rotação X → Y → Z. Pivô: centro local original.',
        ),
        for (var row = 0; row < 2; row++)
          Row(
            children: [
              for (var axis = 0; axis < 3; axis++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: TextField(
                      key: ValueKey('placement-${row * 3 + axis}'),
                      controller: fields[row * 3 + axis],
                      enabled: !busy,
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true,
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText:
                            '${row == 0 ? 'Δ' : 'R'}${['X', 'Y', 'Z'][axis]} (${row == 0 ? 'mm' : '°'})',
                      ),
                    ),
                  ),
                ),
            ],
          ),
        if (error != null)
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        FilledButton(
          onPressed: busy ? null : () => apply(),
          child: Text(busy ? 'Confirmando…' : 'Confirmar placement'),
        ),
        TextButton(
          onPressed: busy ? null : () => apply(reset: true),
          child: const Text('Restaurar posição original'),
        ),
        const Text(
          'Geometria e assets originais preservados. Exportação transformada não disponível.',
        ),
      ],
    );
  }
}
