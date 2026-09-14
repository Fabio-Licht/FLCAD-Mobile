import 'dart:async';

import 'package:flcad_mobile/app/desktop/managed_placement_editor.dart';
import 'package:flcad_mobile/app/runtime/cad_runtime.dart';
import 'package:flcad_mobile/core/cad_kernel/manager/kernel_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingRuntime extends CadRuntime {
  _RecordingRuntime() : super(kernels: KernelManager());
  final calls = <(String, List<double>)>[];
  final completed = Completer<void>();
  String? reset;
  @override
  Future<void> transformManagedEntity(
    String id, {
    double translateX = 0,
    double translateY = 0,
    double translateZ = 0,
    double rotateX = 0,
    double rotateY = 0,
    double rotateZ = 0,
  }) {
    calls.add((
      id,
      [translateX, translateY, translateZ, rotateX, rotateY, rotateZ],
    ));
    return completed.future;
  }

  @override
  Future<void> resetManagedPlacement(String id) async {
    reset = id;
  }
}

void main() {
  testWidgets(
    'editor sends mm/degrees for its selected target once and blocks invalid inputs',
    (tester) async {
      final runtime = _RecordingRuntime();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ManagedPlacementEditor(runtime: runtime, entityId: 'part'),
          ),
        ),
      );
      await tester.enterText(find.byKey(const ValueKey('placement-0')), 'NaN');
      await tester.tap(find.text('Confirmar placement'));
      await tester.pump();
      expect(runtime.calls, isEmpty);
      await tester.enterText(find.byKey(const ValueKey('placement-0')), '5');
      await tester.enterText(find.byKey(const ValueKey('placement-1')), '-2.5');
      await tester.enterText(find.byKey(const ValueKey('placement-5')), '90');
      await tester.tap(find.text('Confirmar placement'));
      await tester.pump();
      expect(runtime.calls, hasLength(1));
      expect(runtime.calls.single.$1, 'part');
      expect(runtime.calls.single.$2, [5.0, -2.5, 0.0, 0.0, 0.0, 90.0]);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      runtime.completed.complete();
      await tester.pump();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('placement-0')))
            .controller!
            .text,
        '0',
      );
      await tester.tap(find.text('Restaurar posição original'));
      await tester.pump();
      expect(runtime.reset, 'part');
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(runtime.shutdown);
    },
  );
}
