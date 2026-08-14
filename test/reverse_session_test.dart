import 'dart:io';
import 'package:flcad_mobile/app/bootstrap/engineering_bootstrap.dart';
import 'package:flcad_mobile/core/cad_kernel/api/geometry_kernel_api.dart';
import 'package:flcad_mobile/core/reverse_session/commands/fel_reverse_session_commands.dart';
import 'package:flcad_mobile/core/reverse_session/integration/reverse_session_factory.dart';
import 'package:flcad_mobile/core/reverse_session/integration/reverse_session_studio.dart';
import 'package:flcad_mobile/core/reverse_session/models/session_models.dart';
import 'package:flcad_mobile/core/reverse_session/repository/reverse_session_repository.dart';
import 'package:flcad_mobile/core/reverse_session/runtime/reverse_session_runtime.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  setUp(() => directory = Directory.systemTemp.createTempSync('flcad-g009d-'));
  tearDown(() => directory.deleteSync(recursive: true));
  SessionContext context(int index) => SessionContext(
    projectId: 'project-$index',
    state: {for (final field in SessionContext.fields) field: '$field-$index'},
  );

  test(
    'session lifecycle supports create open pause resume close archive and delete',
    () {
      final api = const ReverseSessionFactory().create(
        projectDirectory: directory,
        kernel: const UnavailableGeometryKernel(),
      );
      final session = api.create(
        name: 'Reverse',
        user: 'engineer',
        context: context(1),
      );
      api.open(session.id);
      expect(session.status, ReverseSessionStatus.open);
      api.pause(session.id);
      expect(session.status, ReverseSessionStatus.paused);
      api.resume(session.id);
      expect(session.status, ReverseSessionStatus.open);
      api.close(session.id);
      expect(session.status, ReverseSessionStatus.closed);
      api.archive(session.id);
      expect(session.status, ReverseSessionStatus.archived);
      api.delete(session.id);
      expect(session.status, ReverseSessionStatus.deleted);
    },
  );

  test('snapshot deep copies and restores the complete session context', () {
    final api = const ReverseSessionFactory().create(
      projectDirectory: directory,
      kernel: const UnavailableGeometryKernel(),
    );
    final session = api.create(
      name: 'Reverse',
      user: 'engineer',
      context: context(1),
    );
    api.open(session.id);
    session.progress = .4;
    final snapshot = api.snapshot(session.id);
    session.context.state['camera'] = 'changed';
    session.progress = .9;
    api.restore(session.id, snapshot.id);
    expect(session.context.state['camera'], 'camera-1');
    expect(session.progress, .4);
    expect(session.context.state.keys, containsAll(SessionContext.fields));
  });

  test('duplicate and merge preserve independent Project First state', () {
    final api = const ReverseSessionFactory().create(
      projectDirectory: directory,
      kernel: const UnavailableGeometryKernel(),
    );
    final first = api.create(name: 'First', user: 'a', context: context(1));
    final copy = api.duplicate(first.id);
    copy.context.state['camera'] = 'copy';
    expect(first.context.state['camera'], 'camera-1');
    final second = api.create(
      name: 'Second',
      user: 'b',
      context: SessionContext(
        projectId: 'project-1',
        state: {'validation': 'ready'},
      ),
    );
    api.engine.merge(first.id, second.id);
    expect(first.context.state['validation'], 'ready');
  });

  test('journal milestones advisor and replay are consultative', () {
    final api = const ReverseSessionFactory().create(
      projectDirectory: directory,
      kernel: const UnavailableGeometryKernel(),
    );
    final session = api.create(
      name: 'Reverse',
      user: 'engineer',
      context: SessionContext(projectId: 'p', state: {'activeSketch': 's'}),
    );
    api.engine.record(session.id, 'Import STL', result: 'imported');
    api.engine.milestone(session.id, 'STL imported');
    expect(
      api.replay(session.id).map((e) => e.activity),
      contains('Import STL'),
    );
    expect(
      api.engine.recommendations(session.id),
      containsAll([
        'Session incomplete',
        'Validation pending',
        'Alignment pending',
        'Unused sketch',
      ]),
    );
  });

  test('recovery validates and restores state without CAD execution', () {
    final api = const ReverseSessionFactory().create(
      projectDirectory: directory,
      kernel: const UnavailableGeometryKernel(),
    );
    final session = api.create(
      name: 'Reverse',
      user: 'engineer',
      context: context(1),
    );
    final recovery = api.recover(session.id);
    expect(api.engine.recovery.validate(recovery), isEmpty);
    session.context.state['viewport'] = 'damaged';
    api.restoreRecovery(session.id);
    expect(session.context.state['viewport'], 'viewport-1');
  });

  test('1000 complete session cycles are deterministic and geometry-free', () {
    final api = const ReverseSessionFactory().create(
      projectDirectory: directory,
      kernel: const UnavailableGeometryKernel(),
    );
    for (var index = 0; index < 1000; index++) {
      final session = api.create(
        name: 'Session $index',
        user: 'engineer',
        context: context(index),
      );
      api.open(session.id);
      final snapshot = api.snapshot(session.id);
      session.context.state['camera'] = 'changed';
      api.restore(session.id, snapshot.id);
      api.engine.record(
        session.id,
        'Recognition',
        elapsed: const Duration(milliseconds: 1),
      );
      api.engine.milestone(session.id, 'Recognition completed');
      api.recover(session.id);
      session.context.state['camera'] = 'crash';
      api.restoreRecovery(session.id);
      expect(session.context.state['camera'], 'camera-$index');
    }
    expect(api.engine.sessions, hasLength(1000));
    expect(api.engine.snapshotManager.snapshots, hasLength(1000));
    expect(api.engine.recovery.states, hasLength(1000));
    expect(api.engine.milestones.length, 2000);
    expect(api.engine.analytics.snapshots, 1000);
    expect(api.engine.analytics.updates, greaterThanOrEqualTo(7000));
  });

  test(
    'repository workspace and FEL expose the professional session surface',
    () async {
      final api = const ReverseSessionFactory().create(
        projectDirectory: directory,
        kernel: const UnavailableGeometryKernel(),
      );
      api.create(name: 'Reverse', user: 'engineer', context: context(1));
      await api.persist();
      for (final path in ReverseSessionRepository.paths) {
        expect(
          Directory(
            '${directory.path}${Platform.pathSeparator}${path.replaceAll('/', Platform.pathSeparator)}',
          ).existsSync(),
          isTrue,
        );
      }
      final studio = const ReverseSessionStudio();
      expect(studio.workspace, 'Professional Session Workspace');
      expect(studio.panels, hasLength(7));
      final commands = createReverseSessionFelCommands(api);
      expect(commands.length, greaterThanOrEqualTo(120));
      expect(
        commands.map((e) => e.name),
        containsAll([
          'CREATE SESSION',
          'RESTORE SESSION',
          'SHOW JOURNAL',
          'MERGE SESSION',
        ]),
      );
    },
  );

  test('bootstrap registers only a passive session runtime', () {
    EngineeringBootstrap.instance.initialize();
    expect(
      EngineeringBootstrap.instance.services
          .get<ReverseSessionRuntime>()
          .isInitialized,
      isFalse,
    );
  });
}
