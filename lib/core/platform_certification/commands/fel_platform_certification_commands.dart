import '../../fel/commands/fel_command.dart';
import '../../fel/runtime/fel_context.dart';
import '../../fel/types/fel_type.dart';
import '../api/platform_certification_api.dart';

class PlatformCertificationFelCommand implements FELCommand {
  const PlatformCertificationFelCommand(this.name, this.api);
  @override
  final String name;
  final PlatformCertificationApi api;
  @override
  List<FELType> get argumentTypes => const [];
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> arguments,
  ) async {
    final report = api.engine.history.reports.isEmpty
        ? null
        : api.engine.history.reports.last;
    Object? value;
    switch (name) {
      case 'SHOW PLATFORM STATUS':
      case 'SHOW CERTIFICATION':
        value = report?.status.name ?? 'pending';
      case 'SHOW ARCHITECTURE SCORE':
        value = report?.scores.architecture;
      case 'SHOW HEALTH':
      case 'SHOW PLATFORM REPORT':
      case 'SHOW CERTIFICATION REPORT':
        value = report?.toJson();
      case 'SHOW READINESS':
        value = report?.audit.readyForG010;
      case 'SHOW AUDIT':
        value = report?.audit.toJson();
      default:
        value = {
          'command': name,
          'status': 'available',
          'automaticCadExecution': false,
        };
    }
    return FELCommandResult(
      value: FELValue(FELType.dynamicType, value),
      description: name,
    );
  }
}

List<FELCommand> createPlatformCertificationFelCommands(
  PlatformCertificationApi api,
) {
  const names = [
    'RUN PLATFORM CERTIFICATION',
    'SHOW PLATFORM STATUS',
    'SHOW CERTIFICATION',
    'SHOW ARCHITECTURE SCORE',
    'SHOW HEALTH',
    'SHOW READINESS',
    'SHOW AUDIT',
    'SHOW PLATFORM REPORT',
    'SHOW CERTIFICATION REPORT',
    'RUN INTEGRATION TEST',
    'RUN ARCHITECTURE AUDIT',
    'RUN WORKFLOW AUDIT',
    'RUN VALIDATION AUDIT',
    'RUN PROJECT FIRST AUDIT',
    'RUN KERNEL API AUDIT',
    'RUN OPENCASCADE ADAPTER AUDIT',
    'RUN BOOTSTRAP AUDIT',
    'RUN LAZY LOADING AUDIT',
    'RUN SINGLETON AUDIT',
    'RUN TIMER AUDIT',
    'RUN ISOLATE AUDIT',
    'RUN WORKER AUDIT',
    'RUN DLL LOAD AUDIT',
    'RUN GEOMETRY SIMULATION AUDIT',
    'RUN FALLBACK AUDIT',
    'RUN DIRECT KERNEL ACCESS AUDIT',
    'RUN DEPENDENCY CYCLE AUDIT',
    'RUN DOMAIN DUPLICATION AUDIT',
    'SHOW WORKFLOW SCORE',
    'SHOW INTEGRATION SCORE',
    'SHOW VALIDATION SCORE',
    'SHOW UX SCORE',
    'SHOW PERFORMANCE SCORE',
    'SHOW STABILITY SCORE',
    'SHOW MAINTAINABILITY SCORE',
    'SHOW ENGINEERING SCORE',
    'SHOW OVERALL PLATFORM SCORE',
    'SHOW STRENGTHS',
    'SHOW WEAKNESSES',
    'SHOW COUPLINGS',
    'SHOW DUPLICATIONS',
    'SHOW SUGGESTED IMPROVEMENTS',
    'SHOW G010 READY MODULES',
    'SHOW BLOCKING MODULES',
    'RUN REAL PART DEMO',
    'SHOW DEMO STATUS',
    'SHOW DEMO PART',
    'SHOW DEMO STEPS',
    'SHOW DEMO DIAGNOSTICS',
    'SHOW DEMO HISTORY',
    'RUN SESSION LOAD',
    'RUN RESTORE LOAD',
    'RUN VALIDATION LOAD',
    'RUN REPLAY LOAD',
    'RUN DASHBOARD LOAD',
    'RUN QUICK ACTION LOAD',
    'RUN SELECTION LOAD',
    'RUN ENGINEERING REVIEW LOAD',
    'SHOW CERTIFICATION ANALYTICS',
    'SHOW CERTIFICATION HISTORY',
    'SHOW CERTIFICATION CHECKS',
    'SHOW FAILED CHECKS',
    'SHOW BLOCKED CHECKS',
    'SHOW PASSED CHECKS',
    'SHOW RECOGNITION CERTIFICATION',
    'SHOW REFERENCE CERTIFICATION',
    'SHOW ALIGNMENT CERTIFICATION',
    'SHOW VALIDATION CERTIFICATION',
    'SHOW WORKFLOW CERTIFICATION',
    'SHOW STUDIO CERTIFICATION',
    'SHOW INTERACTIVE CERTIFICATION',
    'SHOW SKETCH CERTIFICATION',
    'SHOW CONSTRAINT CERTIFICATION',
    'SHOW FEATURE CERTIFICATION',
    'SHOW EXTRUDE CERTIFICATION',
    'SHOW REVOLVE CERTIFICATION',
    'SHOW TRANSITION CERTIFICATION',
    'SHOW INTELLIGENCE CERTIFICATION',
    'SHOW SESSION CERTIFICATION',
    'SHOW PROJECT FIRST CERTIFICATION',
    'SHOW KERNEL CERTIFICATION',
    'SHOW OPENCASCADE CERTIFICATION',
    'PERSIST CERTIFICATION',
    'PERSIST CERTIFICATION REPORT',
    'PERSIST ARCHITECTURE AUDIT',
    'PERSIST PLATFORM HEALTH',
    'PERSIST READINESS',
    'EXPORT CERTIFICATION',
    'EXPORT PLATFORM REPORT',
    'VALIDATE CERTIFICATION EVIDENCE',
    'VALIDATE REAL PART DEMO',
  ];
  return [for (final name in names) PlatformCertificationFelCommand(name, api)];
}
