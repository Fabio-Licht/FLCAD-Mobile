import 'dart:io';
import 'package:flcad_mobile/app/bootstrap/engineering_bootstrap.dart';
import 'package:flcad_mobile/core/cad_kernel/api/geometry_kernel_api.dart';
import 'package:flcad_mobile/core/interactive_reverse/commands/fel_interactive_reverse_commands.dart';
import 'package:flcad_mobile/core/interactive_reverse/integration/interactive_reverse_factory.dart';
import 'package:flcad_mobile/core/interactive_reverse/integration/interactive_reverse_studio.dart';
import 'package:flcad_mobile/core/interactive_reverse/models/interactive_models.dart';
import 'package:flcad_mobile/core/interactive_reverse/repository/interactive_reverse_repository.dart';
import 'package:flcad_mobile/core/interactive_reverse/runtime/interactive_reverse_runtime.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  setUp(() => directory = Directory.systemTemp.createTempSync('flcad-g009c-'));
  tearDown(() => directory.deleteSync(recursive: true));

  InteractiveSelection selection(
    int index, [
    SelectionType type = SelectionType.recognizedPlane,
  ]) => InteractiveSelection(
    objectId: 'object-$index',
    type: type,
    workflowStep: 'recognition',
    quality: .92,
    confidence: .91,
    bounds: const SelectionBounds(1, 2, 3),
    area: 12,
    radius: 4,
    curvature: .2,
    relatedFeature: 'feature-$index',
    localError: .04,
    references: ['reference-$index'],
    dependencies: ['dependency-$index'],
  );

  test(
    'supports every interactive selection type without creating geometry',
    () {
      final api = const InteractiveReverseFactory().create(
        projectDirectory: directory,
        kernel: const UnavailableGeometryKernel(),
      );
      for (final (index, type) in SelectionType.values.indexed) {
        final selected = api.select(selection(index, type));
        expect(api.engine.previews[selected.id], isNotNull);
        expect(api.engine.suggestions[selected.id], isNotEmpty);
      }
      expect(api.engine.intents, isEmpty);
    },
  );

  test('plane, cylinder and critical region receive the required context', () {
    final api = const InteractiveReverseFactory().create(
      projectDirectory: directory,
      kernel: const UnavailableGeometryKernel(),
    );
    final plane = api.select(selection(1));
    final cylinder = api.select(selection(2, SelectionType.recognizedCylinder));
    final critical = api.select(selection(3, SelectionType.criticalRegion));
    expect(
      api.engine.suggestions[plane.id]!.map((e) => e.operation),
      containsAll([
        InteractiveOperation.createDatum,
        InteractiveOperation.createSketch,
        InteractiveOperation.alignment,
        InteractiveOperation.validation,
      ]),
    );
    expect(
      api.engine.suggestions[cylinder.id]!.map((e) => e.operation),
      containsAll([
        InteractiveOperation.createDatum,
        InteractiveOperation.alignment,
        InteractiveOperation.revolve,
        InteractiveOperation.validation,
      ]),
    );
    expect(
      api.engine.suggestions[critical.id]!.map((e) => e.operation),
      containsAll([
        InteractiveOperation.showCause,
        InteractiveOperation.engineeringReview,
        InteractiveOperation.validationReplay,
      ]),
    );
  });

  test('preview exposes evidence and never a geometry handle', () {
    final api = const InteractiveReverseFactory().create(
      projectDirectory: directory,
      kernel: const UnavailableGeometryKernel(),
    );
    final selected = api.select(selection(1));
    final json = api.engine.previews[selected.id]!.toJson();
    expect(json['highlight'], 'error-overlay');
    expect(json.keys, isNot(contains('geometry')));
    expect(json.keys, isNot(contains('shapeHandle')));
  });

  test(
    'interaction intent remains consultative after acceptance or ignore',
    () {
      final api = const InteractiveReverseFactory().create(
        projectDirectory: directory,
        kernel: const UnavailableGeometryKernel(),
      );
      final selected = api.select(selection(1));
      final before = selected.toJson();
      final suggestions = api.engine.suggestions[selected.id]!;
      final accepted = api.requestAction(selected.id, suggestions.first.id);
      api.decide(accepted.id, InteractionDecision.accepted);
      final ignored = api.requestAction(selected.id, suggestions.last.id);
      api.decide(ignored.id, InteractionDecision.ignored);
      expect(selected.toJson(), before);
      expect(api.engine.analytics.accepted, 1);
      expect(api.engine.analytics.ignored, 1);
    },
  );

  test(
    '1000 selections update preview, context, timeline, advisor and dashboard deterministically',
    () {
      final api = const InteractiveReverseFactory().create(
        projectDirectory: directory,
        kernel: const UnavailableGeometryKernel(),
      );
      for (var index = 0; index < 1000; index++) {
        final selected = api.select(
          selection(
            index,
            SelectionType.values[index % SelectionType.values.length],
          ),
        );
        expect(api.showContext(selected.id), isNotEmpty);
        expect(api.engine.previews[selected.id]!.highlight, isNotEmpty);
        expect(api.engine.advice[selected.id], isNotNull);
        expect(api.engine.dashboard.selectedObject, selected.objectId);
      }
      expect(api.engine.selectionManager.selections, hasLength(1000));
      expect(api.engine.previews, hasLength(1000));
      expect(api.engine.advice, hasLength(1000));
      expect(api.engine.analytics.contextChanges, 1000);
      expect(api.engine.timeline.entries, hasLength(2000));
    },
  );

  test('persists all Project First interactive paths', () async {
    final api = const InteractiveReverseFactory().create(
      projectDirectory: directory,
      kernel: const UnavailableGeometryKernel(),
    );
    api.select(selection(1));
    await api.persist();
    for (final path in InteractiveReverseRepository.paths) {
      expect(
        Directory(
          '${directory.path}${Platform.pathSeparator}${path.replaceAll('/', Platform.pathSeparator)}',
        ).existsSync(),
        isTrue,
      );
    }
  });

  test('studio and FEL expose the professional interaction surface', () {
    final api = const InteractiveReverseFactory().create(
      projectDirectory: directory,
      kernel: const UnavailableGeometryKernel(),
    );
    final panels = const InteractiveReverseStudio().panels.map((e) => e.name);
    expect(
      panels,
      containsAll([
        'Interactive Reverse Workspace',
        'Selection Inspector',
        'Context Actions',
        'Interactive Advisor',
        'Selection Analytics',
      ]),
    );
    final commands = createInteractiveReverseFelCommands(api);
    expect(commands.length, greaterThanOrEqualTo(120));
    expect(
      commands.map((e) => e.name),
      containsAll([
        'SELECT REGION',
        'CREATE DATUM FROM SELECTION',
        'VALIDATE SELECTION',
        'SHOW SELECTION ANALYTICS',
      ]),
    );
  });

  test('bootstrap only registers the passive runtime', () {
    final bootstrap = EngineeringBootstrap.instance;
    bootstrap.initialize();
    final runtime = bootstrap.services.get<InteractiveReverseRuntime>();
    expect(runtime.isInitialized, isFalse);
  });
}
