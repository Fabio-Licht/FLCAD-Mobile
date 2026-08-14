import 'dart:convert';
import 'dart:io';
import '../analytics/certification_analytics.dart';
import '../reports/certification_models.dart';

class PlatformCertificationRepository {
  PlatformCertificationRepository(this.projectDirectory);
  final Directory projectDirectory;
  static const paths = [
    'CAD/Certification',
    'CAD/CertificationReports',
    'CAD/ArchitectureAudit',
    'CAD/PlatformHealth',
    'CAD/Readiness',
  ];
  Directory _dir(String path) => Directory(
    '${projectDirectory.path}${Platform.pathSeparator}${path.replaceAll('/', Platform.pathSeparator)}',
  );
  Future<void> save({
    required Iterable<CertificationReport> reports,
    required Iterable<DemonstrationResult> demonstrations,
    required CertificationAnalytics analytics,
  }) async {
    for (final path in paths) {
      await _dir(path).create(recursive: true);
    }
    final reportList = reports.toList(), demoList = demonstrations.toList();
    await File(
      '${_dir(paths[0]).path}${Platform.pathSeparator}certification.json',
    ).writeAsString(
      jsonEncode({
        'reports': reportList.map((e) => e.toJson()).toList(),
        'demonstrations': demoList.map((e) => e.toJson()).toList(),
      }),
    );
    await File(
      '${_dir(paths[1]).path}${Platform.pathSeparator}reports.json',
    ).writeAsString(jsonEncode(reportList.map((e) => e.toJson()).toList()));
    await File(
      '${_dir(paths[2]).path}${Platform.pathSeparator}audit.json',
    ).writeAsString(
      jsonEncode(reportList.isEmpty ? {} : reportList.last.audit.toJson()),
    );
    await File(
      '${_dir(paths[3]).path}${Platform.pathSeparator}health.json',
    ).writeAsString(
      jsonEncode(reportList.isEmpty ? {} : reportList.last.scores.toJson()),
    );
    await File(
      '${_dir(paths[4]).path}${Platform.pathSeparator}readiness.json',
    ).writeAsString(
      jsonEncode({
        'status': reportList.isEmpty ? 'pending' : reportList.last.status.name,
        'analytics': analytics.toJson(),
      }),
    );
  }
}

class PlatformCertificationRepositoryFactory {
  const PlatformCertificationRepositoryFactory();
  PlatformCertificationRepository create(Directory project) =>
      PlatformCertificationRepository(project);
}
