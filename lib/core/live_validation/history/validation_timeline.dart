import '../../utils/id_generator.dart';

class ValidationTimelineEntry {
  ValidationTimelineEntry({
    required this.sessionId,
    required this.featureId,
    required this.previousError,
    required this.currentError,
    required this.regionId,
    required this.qualityScore,
  }) : id = 'validation-timeline:${IdGenerator.generate()}',
       timestamp = DateTime.now().toUtc();
  final String id, sessionId, featureId, regionId;
  final DateTime timestamp;
  final double previousError, currentError, qualityScore;
  double get difference => currentError - previousError;
  double get gains => difference < 0 ? -difference : 0;
  double get losses => difference > 0 ? difference : 0;
  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'featureId': featureId,
    'regionId': regionId,
    'timestamp': timestamp.toIso8601String(),
    'previousError': previousError,
    'currentError': currentError,
    'difference': difference,
    'gains': gains,
    'losses': losses,
    'qualityScore': qualityScore,
  };
}

class ValidationTimeline {
  final List<ValidationTimelineEntry> entries = [];
  void add(ValidationTimelineEntry entry) => entries.add(entry);
}
