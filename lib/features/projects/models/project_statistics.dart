class ProjectStatistics {
  const ProjectStatistics({
    this.photoCount = 0,
    this.reconstructionCount = 0,
    this.reconstructionProgress = 0,
    this.currentReconstructionStep,
    this.qualityScore = 0,
    this.coverageScore = 0,
    this.scaleScore = 0,
    this.aiConfidence = 0,
  });

  final int photoCount;
  final int reconstructionCount;
  final double reconstructionProgress;
  final String? currentReconstructionStep;
  final double qualityScore;
  final double coverageScore;
  final double scaleScore;
  final double aiConfidence;

  ProjectStatistics copyWith({
    int? photoCount,
    int? reconstructionCount,
    double? reconstructionProgress,
    String? currentReconstructionStep,
    bool clearCurrentStep = false,
    double? qualityScore,
    double? coverageScore,
    double? scaleScore,
    double? aiConfidence,
  }) => ProjectStatistics(
    photoCount: photoCount ?? this.photoCount,
    reconstructionCount: reconstructionCount ?? this.reconstructionCount,
    reconstructionProgress:
        reconstructionProgress ?? this.reconstructionProgress,
    currentReconstructionStep: clearCurrentStep
        ? null
        : currentReconstructionStep ?? this.currentReconstructionStep,
    qualityScore: qualityScore ?? this.qualityScore,
    coverageScore: coverageScore ?? this.coverageScore,
    scaleScore: scaleScore ?? this.scaleScore,
    aiConfidence: aiConfidence ?? this.aiConfidence,
  );
}
