import 'dart:io';
import 'package:flcad_mobile/app/bootstrap/engineering_bootstrap.dart';
import 'package:flcad_mobile/core/engineering_studio/properties/property_inspector.dart';
import 'package:flcad_mobile/core/profile_recognition/analytics/profile_analytics.dart';
import 'package:flcad_mobile/core/profile_recognition/api/profile_recognition_api.dart';
import 'package:flcad_mobile/core/profile_recognition/commands/fel_profile_commands.dart';
import 'package:flcad_mobile/core/profile_recognition/history/profile_history.dart';
import 'package:flcad_mobile/core/profile_recognition/integration/profile_factory.dart';
import 'package:flcad_mobile/core/profile_recognition/integration/profile_studio.dart';
import 'package:flcad_mobile/core/profile_recognition/models/profile_models.dart';
import 'package:flcad_mobile/core/profile_recognition/repository/profile_repository.dart';
import 'package:flcad_mobile/core/profile_recognition/runtime/profile_runtime.dart';
import 'package:flcad_mobile/core/profile_recognition/validation/profile_validation.dart';
import 'package:flcad_mobile/core/sketch_engine/entities/sketch_entities.dart';
import 'package:flcad_mobile/core/sketch_engine/api/sketch_engine_api.dart';
import 'package:flcad_mobile/core/sketch_engine/integration/sketch_factory.dart';
import 'package:flcad_mobile/core/sketch_engine/models/sketch_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory project;
  late SketchEngineApi sketch;
  late ProfileRecognitionApi api;
  setUp(() async {
    project = await Directory.systemTemp.createTemp('flcad_profiles_');
    sketch = const SketchEngineFactory().create(project)
      ..createSketch('Profiles');
    api = const ProfileRecognitionFactory().create(
      projectDirectory: project,
      sketch: sketch,
    );
  });
  tearDown(() async {
    if (await project.exists()) await project.delete(recursive: true);
  });
  test(
    'recognizes closed rectangle loop region intent topology and readiness',
    () {
      final b = sketch.builders.line;
      b.build(const SketchVector(0, 0), const SketchVector(4, 0));
      b.build(const SketchVector(4, 0), const SketchVector(4, 3));
      b.build(const SketchVector(4, 3), const SketchVector(0, 3));
      b.build(const SketchVector(0, 3), const SketchVector(0, 0));
      api.recognize();
      expect(api.profiles.single.type, ProfileType.closed);
      expect(api.profiles.single.area, 12);
      expect(api.loops.single.orientation, LoopOrientation.counterClockwise);
      expect(api.regions.single.type, RegionType.closed);
      expect(api.intent.intent, GeometricIntent.rectangle);
      expect(api.readiness!.extrude, isTrue);
      expect(api.engine.graphs.topology.nodes, hasLength(3));
    },
  );
  test(
    'recognizes 1000 profiles loops regions including nested holes and islands',
    () {
      for (var i = 0; i < 1000; i++) {
        final circle = SketchCircle(
          SketchVector(i.toDouble() * 3, 0),
          1 + i / 10000,
        );
        sketch.engine.entities[circle.id] = circle;
      }
      api.recognize();
      expect(api.profiles, hasLength(1000));
      expect(api.loops, hasLength(1000));
      expect(api.regions, hasLength(1000));
      expect(api.loops.any((l) => l.type == LoopType.hole), isTrue);
      expect(api.loops.any((l) => l.type == LoopType.island), isTrue);
      expect(
        api.profiles.where((p) => p.type == ProfileType.nested),
        hasLength(999),
      );
    },
  );
  test(
    'detects micro gaps open profiles multiple profiles and invalid topology',
    () {
      sketch.builders.line.build(
        const SketchVector(0, 0),
        const SketchVector(1, 0),
      );
      sketch.builders.line.build(
        const SketchVector(1.00001, 0),
        const SketchVector(2, 0),
      );
      sketch.builders.line.build(
        const SketchVector(10, 0),
        const SketchVector(11, 0),
      );
      api.recognize();
      final kinds = api.validation.issues.map((i) => i.type);
      expect(kinds, contains(ProfileIssueType.microGap));
      expect(kinds, contains(ProfileIssueType.openEnd));
      expect(api.profiles.length, greaterThan(1));
      expect(api.readiness!.extrude, isFalse);
    },
  );
  test('detects self intersections and crossings', () {
    final b = sketch.builders.line;
    b.build(const SketchVector(0, 0), const SketchVector(2, 2));
    b.build(const SketchVector(2, 2), const SketchVector(0, 2));
    b.build(const SketchVector(0, 2), const SketchVector(2, 0));
    b.build(const SketchVector(2, 0), const SketchVector(0, 0));
    api.recognize();
    expect(
      api.validation.issues.map((i) => i.type),
      contains(ProfileIssueType.selfIntersection),
    );
    expect(api.profiles.single.type, ProfileType.selfIntersecting);
    expect(api.quality!.topology, lessThan(100));
  });
  test('region merge split undo redo and rollback safety', () {
    final c1 = SketchCircle(const SketchVector(0, 0), 3),
        c2 = SketchCircle(const SketchVector(0, 0), 1);
    sketch.engine.entities.clear();
    sketch.engine.entities[c1.id] = c1;
    sketch.engine.entities[c2.id] = c2;
    api.recognize();
    final ids = api.regions.map((r) => r.id).toList();
    final merged = api.engine.merge(ids[0], ids[1]);
    expect(merged.loopIds, hasLength(2));
    expect(api.engine.undo(), isTrue);
    expect(api.engine.regions, hasLength(2));
    expect(api.engine.redo(), isTrue);
    expect(api.engine.regions, contains(merged.id));
    expect(api.engine.split(merged.id), hasLength(2));
    final before = api.engine.regions.length;
    expect(() => api.engine.merge('missing', ids.first), throwsStateError);
    expect(api.engine.regions, hasLength(before));
  });
  test('advisor quality and feature readiness are advisory only', () {
    sketch.builders.line.build(
      const SketchVector(0, 0),
      const SketchVector(1, 0),
    );
    api.recognize();
    final recommendations = api.recommendations();
    expect(recommendations, isNotEmpty);
    expect(
      recommendations.every((r) => r.confidence >= 0 && r.confidence <= 100),
      isTrue,
    );
    expect(api.quality!.score, inInclusiveRange(0, 100));
    expect(
      api.readiness!.toJson().keys,
      containsAll([
        'extrudeReady',
        'revolveReady',
        'sweepReady',
        'loftReady',
        'booleanReady',
        'shellReady',
        'draftReady',
        'filletReady',
      ]),
    );
    expect(sketch.engine.entities, hasLength(1));
  });
  test(
    'repository analytics history runtime factory bootstrap FEL and Studio integrate',
    () async {
      final c = sketch.builders.circle.build(const SketchVector(0, 0), 2);
      api.recognize();
      await api.engine.persist();
      for (final path in ProfileRepository.paths) {
        expect(
          Directory(
            '${project.path}${Platform.pathSeparator}${path.replaceAll('/', Platform.pathSeparator)}',
          ).existsSync(),
          isTrue,
        );
      }
      expect(
        createProfileFelCommands(api).map((e) => e.name).toSet(),
        hasLength(35),
      );
      expect(api.engine.analytics.profiles, 1);
      expect(api.engine.history.entries, isNotEmpty);
      expect(api.engine.runtime.isInitialized, isFalse);
      final node = const ProfileStudioAdapter()
          .buildTree(api.engine, 'project')
          .firstWhere((n) => n.id == api.profiles.single.id);
      final section = const PropertyInspector()
          .inspect(node)
          .firstWhere((s) => s.name == 'Profile Recognition');
      expect(
        section.values.keys,
        containsAll([
          'profileType',
          'loopCount',
          'regionCount',
          'area',
          'perimeter',
          'orientation',
          'topologyStatus',
          'readiness',
          'quality',
          'intent',
          'confidence',
          'persistentId',
        ]),
      );
      expect(c.id, isNotEmpty);
      final bootstrap = EngineeringBootstrap.instance..initialize();
      expect(bootstrap.services.get<ProfileRecognitionFactory>(), isNotNull);
      expect(bootstrap.services.get<ProfileRecognitionRuntime>(), isNotNull);
      expect(bootstrap.services.get<ProfileRepository>(), isNotNull);
      expect(bootstrap.services.get<ProfileAnalytics>(), isNotNull);
      expect(bootstrap.services.get<ProfileHistory>(), isNotNull);
    },
  );
}
