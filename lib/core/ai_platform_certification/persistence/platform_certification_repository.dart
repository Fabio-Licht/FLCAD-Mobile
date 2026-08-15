import 'dart:convert';
import 'dart:io';

import '../models/platform_certification_models.dart';

class PlatformCertificationRepository {
  PlatformCertificationRepository(this.projectDirectory) {
    if (!projectDirectory.isAbsolute) {
      throw ArgumentError('Project First requires an absolute directory');
    }
  }
  final Directory projectDirectory;
  Future<File> emit(AIEngineeringPlatformCertificate certificate) async {
    if (certificate.status != CertificationStatus.approved) {
      throw StateError('Rejected certificate cannot be emitted');
    }
    final file = File(
      '${projectDirectory.path}${Platform.pathSeparator}AIEngineeringPlatformCertificate.json',
    );
    await file.parent.create(recursive: true);
    return file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(certificate.toJson()),
    );
  }

  Future<File> emitAudit(AIEngineeringPlatformCertificate certificate) async {
    final directory = Directory(
      '${projectDirectory.path}${Platform.pathSeparator}CAD${Platform.pathSeparator}AIPlatformCertification',
    );
    await directory.create(recursive: true);
    return File(
      '${directory.path}${Platform.pathSeparator}ArchitectureAudit.json',
    ).writeAsString(
      const JsonEncoder.withIndent(
        '  ',
      ).convert(certificate.architecture.toJson()),
    );
  }
}
