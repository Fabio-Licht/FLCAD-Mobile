class AIResult {
  const AIResult({
    required this.pluginId,
    required this.task,
    required this.score,
    required this.confidence,
    required this.data,
    required this.recommendations,
    required this.createdAt,
    this.fromCache = false,
  });
  final String pluginId;
  final String task;
  final double score;
  final double confidence;
  final Map<String, dynamic> data;
  final List<String> recommendations;
  final DateTime createdAt;
  final bool fromCache;

  AIResult copyWith({bool? fromCache}) => AIResult(
    pluginId: pluginId,
    task: task,
    score: score,
    confidence: confidence,
    data: data,
    recommendations: recommendations,
    createdAt: createdAt,
    fromCache: fromCache ?? this.fromCache,
  );
  Map<String, dynamic> toJson() => {
    'pluginId': pluginId,
    'task': task,
    'score': score,
    'confidence': confidence,
    'data': data,
    'recommendations': recommendations,
    'createdAt': createdAt.toIso8601String(),
  };
  factory AIResult.fromJson(Map<String, dynamic> json) => AIResult(
    pluginId: json['pluginId'] as String,
    task: json['task'] as String,
    score: (json['score'] as num).toDouble(),
    confidence: (json['confidence'] as num).toDouble(),
    data: (json['data'] as Map).cast<String, dynamic>(),
    recommendations: (json['recommendations'] as List).cast<String>(),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
