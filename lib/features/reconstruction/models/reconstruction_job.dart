import 'pipeline_event.dart';
import 'reconstruction_status.dart';

class ReconstructionJob {
  const ReconstructionJob({
    required this.projectId,
    required this.status,
    required this.progress,
    required this.currentStep,
    required this.logs,
    required this.cancelRequested,
    this.startTime,
    this.endTime,
    this.resultPath,
    this.error,
  });
  final String projectId;
  final ReconstructionStatus status;
  final DateTime? startTime;
  final DateTime? endTime;
  final double progress;
  final String currentStep;
  final List<PipelineEvent> logs;
  final bool cancelRequested;
  final String? resultPath;
  final String? error;

  bool get canResume =>
      status == ReconstructionStatus.running ||
      status == ReconstructionStatus.waiting ||
      status == ReconstructionStatus.paused;

  ReconstructionJob copyWith({
    ReconstructionStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    double? progress,
    String? currentStep,
    List<PipelineEvent>? logs,
    bool? cancelRequested,
    String? resultPath,
    String? error,
  }) => ReconstructionJob(
    projectId: projectId,
    status: status ?? this.status,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    progress: progress ?? this.progress,
    currentStep: currentStep ?? this.currentStep,
    logs: logs ?? this.logs,
    cancelRequested: cancelRequested ?? this.cancelRequested,
    resultPath: resultPath ?? this.resultPath,
    error: error ?? this.error,
  );

  Map<String, dynamic> toJson() => {
    'projectId': projectId,
    'status': status.name,
    'startTime': startTime?.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'progress': progress,
    'currentStep': currentStep,
    'logs': logs.map((event) => event.toJson()).toList(),
    'cancelRequested': cancelRequested,
    'resultPath': resultPath,
    'error': error,
  };
  factory ReconstructionJob.fromJson(Map<String, dynamic> json) =>
      ReconstructionJob(
        projectId: json['projectId'] as String,
        status: ReconstructionStatus.values.firstWhere(
          (value) => value.name == json['status'],
          orElse: () => ReconstructionStatus.failed,
        ),
        startTime: _date(json['startTime']),
        endTime: _date(json['endTime']),
        progress: (json['progress'] as num? ?? 0).toDouble(),
        currentStep: json['currentStep'] as String? ?? '',
        logs: ((json['logs'] as List?) ?? const [])
            .map(
              (item) =>
                  PipelineEvent.fromJson((item as Map).cast<String, dynamic>()),
            )
            .toList(),
        cancelRequested: json['cancelRequested'] as bool? ?? false,
        resultPath: json['resultPath'] as String?,
        error: json['error'] as String?,
      );
  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}
