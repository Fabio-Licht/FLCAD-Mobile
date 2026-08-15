import 'dart:convert';
import 'dart:io';

import 'package:flcad_mobile/core/ai_platform_certification/ai_platform_certification.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = AIPlatformCertificationEngine();
  AIEngineeringPlatformCertificate certificate() => engine.certify(
    version: '1.0.0',
    certificationDate: '2026-08-15',
    coverage: 'lcov.info generated',
  );

  group('AI Engineering Platform Certification', () {
    test('certifies every G-012A through G-012G capability', () {
      final result = certificate();
      expect(result.status, CertificationStatus.approved);
      expect(result.modules, hasLength(7));
      expect(result.modules.map((e) => e.sprint), [
        'G-012A',
        'G-012B',
        'G-012C',
        'G-012D',
        'G-012E',
        'G-012F',
        'G-012G',
      ]);
      expect(
        result.modules.every(
          (e) =>
              e.evidence.isNotEmpty &&
              e.justification.isNotEmpty &&
              e.origin.isNotEmpty &&
              e.discardedHypotheses.isNotEmpty &&
              e.score == 1,
        ),
        isTrue,
      );
    });

    test(
      'global dependency audit rejects cycles, orphans and invalid edges',
      () {
        final valid = certificate().architecture;
        expect(valid.approved, isTrue);
        expect(valid.hasCycles, isFalse);
        expect(valid.orphanModules, isEmpty);
        expect(valid.invalidDependencies, isEmpty);
        final invalid = ArchitectureAudit(
          modules: const ['a', 'b', 'orphan'],
          dependencies: const [
            DependencyEdge('a', 'b'),
            DependencyEdge('b', 'a'),
            DependencyEdge('a', 'missing'),
          ],
          workspaces: const [],
          propertyInspectors: const [],
          persistenceRoots: const [],
          analytics: const [],
          adrs: const [],
          maxSerializedPipelineBytes: 1,
        );
        expect(invalid.approved, isFalse);
        expect(invalid.hasCycles, isTrue);
        expect(invalid.orphanModules, contains('orphan'));
        expect(invalid.invalidDependencies, hasLength(1));
      },
    );

    test(
      'workspaces, inspectors, analytics, persistence and ADRs are complete',
      () {
        final audit = certificate().architecture;
        expect(audit.workspaces, hasLength(7));
        expect(audit.propertyInspectors, hasLength(7));
        expect(audit.analytics, hasLength(7));
        expect(audit.persistenceRoots, hasLength(7));
        expect(audit.adrs, hasLength(7));
        expect(audit.toJson(), containsPair('timersUsed', false));
      },
    );

    test('2,500 platform pipelines are byte-identical', () {
      expect(
        engine.validateDeterminism(
          version: '1.0.0',
          certificationDate: '2026-08-15',
          coverage: 'lcov.info generated',
          repetitions: 2500,
        ),
        isTrue,
      );
    });

    test('certificate is bounded and excludes mutation and automation', () {
      final result = certificate();
      final encoded = utf8.encode(result.canonicalJson());
      expect(
        encoded.length,
        lessThan(result.architecture.maxSerializedPipelineBytes),
      );
      expect(result.toJson(), containsPair('geometryModified', false));
      expect(result.toJson(), containsPair('automaticDecisions', false));
      expect(result.toJson(), containsPair('externalContextUsed', false));
      expect(result.toJson(), containsPair('timers', false));
    });

    test(
      'Project First emits official certificate and architecture audit',
      () async {
        final directory = await Directory.systemTemp.createTemp('g012h_');
        addTearDown(() => directory.delete(recursive: true));
        final repository = PlatformCertificationRepository(directory);
        final official = await repository.emit(certificate());
        final audit = await repository.emitAudit(certificate());
        expect(
          official.path,
          endsWith('AIEngineeringPlatformCertificate.json'),
        );
        expect(jsonDecode(await official.readAsString())['status'], 'APPROVED');
        expect(jsonDecode(await audit.readAsString())['approved'], isTrue);
      },
    );

    test('rejected certificates cannot be emitted', () async {
      final directory = await Directory.systemTemp.createTemp(
        'g012h_rejected_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final rejected = engine.certify(
        version: '1.0.0',
        certificationDate: '2026-08-15',
        coverage: 'none',
        pipelineCount: 2499,
      );
      expect(rejected.status, CertificationStatus.rejected);
      expect(
        () => PlatformCertificationRepository(directory).emit(rejected),
        throwsStateError,
      );
    });
  });
}
