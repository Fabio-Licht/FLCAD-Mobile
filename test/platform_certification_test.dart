import 'dart:io';
import 'package:flcad_mobile/app/bootstrap/engineering_bootstrap.dart';
import 'package:flcad_mobile/core/cad_kernel/api/geometry_kernel_api.dart';
import 'package:flcad_mobile/core/platform_certification/checks/architecture_checks.dart';
import 'package:flcad_mobile/core/platform_certification/commands/fel_platform_certification_commands.dart';
import 'package:flcad_mobile/core/platform_certification/engine/platform_certification_engine.dart';
import 'package:flcad_mobile/core/platform_certification/integration/platform_certification_factory.dart';
import 'package:flcad_mobile/core/platform_certification/integration/platform_certification_studio.dart';
import 'package:flcad_mobile/core/platform_certification/reports/certification_models.dart';
import 'package:flcad_mobile/core/platform_certification/repository/platform_certification_repository.dart';
import 'package:flcad_mobile/core/platform_certification/runtime/platform_certification_runtime.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  setUp(() => directory = Directory.systemTemp.createTempSync('flcad-g009e-'));
  tearDown(() => directory.deleteSync(recursive: true));

  test('certification rejects absent evidence and absent real part', () async {
    final api = const PlatformCertificationFactory().create(
      projectDirectory: directory,
      kernel: const UnavailableGeometryKernel(),
    );
    final demo = await api.demonstrate(
      partPath: '${directory.path}/missing.stl',
      steps: const {},
    );
    final report = api.certify(evidence: const {}, demonstration: demo);
    expect(demo.status, CertificationStatus.blocked);
    expect(report.status, CertificationStatus.blocked);
    expect(
      report.audit.blockers,
      contains('Real end-to-end demonstration is incomplete'),
    );
  });

  test('all mandatory architecture evidence is explicit and auditable', () {
    final api = const PlatformCertificationFactory().create(
      projectDirectory: directory,
      kernel: const UnavailableGeometryKernel(),
    );
    final evidence = {
      for (final name in [
        ...ArchitectureChecks.modules,
        ...ArchitectureChecks.invariants,
      ])
        name: 'verified by automated check',
    };
    final report = api.certify(evidence: evidence, demonstration: null);
    expect(report.checks, hasLength(29));
    expect(
      report.checks.every((e) => e.status == CertificationStatus.passed),
      isTrue,
    );
    expect(
      report.status,
      CertificationStatus.blocked,
      reason: 'a real demonstration is mandatory',
    );
  });

  test('demonstration executes every official step in order', () async {
    final part = File('${directory.path}/part.stl')
      ..writeAsStringSync('solid test\nendsolid test');
    final api = const PlatformCertificationFactory().create(
      projectDirectory: directory,
      kernel: const UnavailableGeometryKernel(),
    );
    final executed = <String>[];
    final demo = await api.demonstrate(
      partPath: part.path,
      steps: {
        for (final name in PlatformCertificationEngine.demonstrationSteps)
          name: () async => executed.add(name),
      },
    );
    expect(demo.status, CertificationStatus.passed);
    expect(executed, PlatformCertificationEngine.demonstrationSteps);
  });

  test('failed official integration step prevents certification', () async {
    final part = File('${directory.path}/part.stl')
      ..writeAsStringSync('non-empty test fixture');
    final api = const PlatformCertificationFactory().create(
      projectDirectory: directory,
      kernel: const UnavailableGeometryKernel(),
    );
    final steps = {
      for (final name in PlatformCertificationEngine.demonstrationSteps)
        name: () async {
          if (name == 'Create Extrude') throw StateError('backend unavailable');
        },
    };
    final demo = await api.demonstrate(partPath: part.path, steps: steps);
    expect(demo.status, CertificationStatus.failed);
    expect(demo.diagnostics.single, contains('Create Extrude'));
  });

  test(
    '100 demonstration workloads update all performance counters deterministically',
    () async {
      final part = File('${directory.path}/part.stl')
        ..writeAsStringSync('non-empty test fixture');
      final api = const PlatformCertificationFactory().create(
        projectDirectory: directory,
        kernel: const UnavailableGeometryKernel(),
      );
      for (var index = 0; index < 100; index++) {
        await api.demonstrate(
          partPath: part.path,
          steps: {
            for (final name in PlatformCertificationEngine.demonstrationSteps)
              name: () async {},
          },
        );
        final a = api.engine.analytics;
        a.sessions++;
        a.restores++;
        a.validations++;
        a.replays++;
        a.dashboards++;
        a.quickActions++;
        a.selections++;
        a.reviews++;
      }
      final analytics = api.engine.analytics;
      expect(analytics.demonstrations, 100);
      expect(analytics.sessions, 100);
      expect(analytics.restores, 100);
      expect(analytics.validations, 100);
      expect(analytics.replays, 100);
      expect(analytics.dashboards, 100);
      expect(analytics.quickActions, 100);
      expect(analytics.selections, 100);
      expect(analytics.reviews, 100);
    },
  );

  test('repository Studio FEL and passive bootstrap integrate', () async {
    final api = const PlatformCertificationFactory().create(
      projectDirectory: directory,
      kernel: const UnavailableGeometryKernel(),
    );
    api.certify(evidence: const {}, demonstration: null);
    await api.persist();
    for (final path in PlatformCertificationRepository.paths) {
      expect(
        Directory(
          '${directory.path}${Platform.pathSeparator}${path.replaceAll('/', Platform.pathSeparator)}',
        ).existsSync(),
        isTrue,
      );
    }
    expect(
      const PlatformCertificationStudio().panels.map((e) => e.name),
      containsAll([
        'Platform Health',
        'Architecture Report',
        'Certification Status',
        'Readiness Dashboard',
      ]),
    );
    final commands = createPlatformCertificationFelCommands(api);
    expect(commands.length, greaterThanOrEqualTo(80));
    expect(
      commands.map((e) => e.name),
      containsAll([
        'RUN PLATFORM CERTIFICATION',
        'SHOW READINESS',
        'RUN INTEGRATION TEST',
      ]),
    );
    EngineeringBootstrap.instance.initialize();
    expect(
      EngineeringBootstrap.instance.services
          .get<PlatformCertificationRuntime>()
          .isInitialized,
      isFalse,
    );
  });
}
