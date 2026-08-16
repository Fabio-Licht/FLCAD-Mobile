import 'dart:io';

import 'package:flcad_mobile/app/commands/commands.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'validation manager execution undo redo and histories are integrated',
    () async {
      final root = await Directory.systemTemp.createTemp('flcad_commands_');
      addTearDown(() => root.delete(recursive: true));
      final registry = CommandRegistry();
      var value = 0;
      registry.register(
        RegisteredEngineeringCommand(
          id: 'engineering.increment',
          module: 'Engineering',
          validator: CommandValidation.projectRequired,
          execute: (_, parameters) async =>
              value += parameters['value']! as int,
          undo: (_, parameters) async => value -= parameters['value']! as int,
          redo: (_, parameters) async => value += parameters['value']! as int,
        ),
      );
      final manager = CommandManager(
        registry: registry,
        clock: () => DateTime.utc(2026, 8, 15),
        durationProvider: () => 17,
      );
      final dispatcher = CommandDispatcher(
        manager: manager,
        context: CommandContext(projectId: 'project-1', projectDirectory: root),
      );

      await dispatcher.dispatch('engineering.increment', {'value': 3});
      expect(value, 3);
      expect(manager.canUndo, isTrue);
      await dispatcher.undo();
      expect(value, 0);
      await dispatcher.redo();
      expect(value, 3);
      expect(manager.history.map((e) => e.operation), [
        'execute',
        'undo',
        'redo',
      ]);
      expect(manager.history.every((e) => e.durationMicros == 17), isTrue);
      for (final folder in ['CommandHistory', 'UndoHistory', 'RedoHistory']) {
        final file = File('${root.path}/CAD/$folder/history.jsonl');
        expect(await file.exists(), isTrue);
        expect(await file.readAsString(), contains('engineering.increment'));
      }
    },
  );

  test('invalid command never reaches execution or undo stack', () async {
    final registry = CommandRegistry();
    var executed = false;
    registry.register(
      RegisteredEngineeringCommand(
        id: 'requires.project',
        module: 'Project',
        validator: CommandValidation.projectRequired,
        execute: (_, _) async => executed = true,
        undo: (_, _) async => null,
        redo: (_, _) async => null,
      ),
    );
    final manager = CommandManager(registry: registry);
    final dispatcher = CommandDispatcher(
      manager: manager,
      context: CommandContext(projectId: null, projectDirectory: null),
    );
    await expectLater(
      dispatcher.dispatch('requires.project'),
      throwsA(isA<StateError>()),
    );
    expect(executed, isFalse);
    expect(manager.canUndo, isFalse);
    expect(manager.history, isEmpty);
  });

  test('workspace and selection adapters synchronize command state', () {
    final adapter = WorkspaceCommandAdapter();
    adapter.open('Smart References');
    adapter.select({'plane-A', 'axis-1'});
    expect(adapter.state.workspace, 'Smart References');
    expect(adapter.state.selection, {'plane-A', 'axis-1'});
    expect(adapter.state.status, '2 object(s) selected');
  });

  test('registry rejects duplicates and unknown commands', () {
    final registry = CommandRegistry();
    final command = RegisteredEngineeringCommand(
      id: 'one',
      module: 'Test',
      execute: (_, _) async => null,
      undo: (_, _) async => null,
      redo: (_, _) async => null,
    );
    registry.register(command);
    expect(() => registry.register(command), throwsStateError);
    expect(() => registry.resolve('missing'), throwsStateError);
  });
}
