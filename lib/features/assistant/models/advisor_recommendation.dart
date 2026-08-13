class AdvisorRecommendation {
  const AdvisorRecommendation({
    required this.id,
    required this.projectId,
    required this.source,
    required this.title,
    required this.message,
    required this.severity,
    required this.createdAt,
    required this.data,
    this.acknowledged = false,
  });
  final String id;
  final String projectId;
  final String source;
  final String title;
  final String message;
  final String severity;
  final DateTime createdAt;
  final Map<String, dynamic> data;
  final bool acknowledged;
  Map<String, dynamic> toJson() => {
    'id': id,
    'projectId': projectId,
    'source': source,
    'title': title,
    'message': message,
    'severity': severity,
    'createdAt': createdAt.toIso8601String(),
    'data': data,
    'acknowledged': acknowledged,
  };
  factory AdvisorRecommendation.fromJson(Map<String, dynamic> json) =>
      AdvisorRecommendation(
        id: json['id'] as String,
        projectId: json['projectId'] as String,
        source: json['source'] as String,
        title: json['title'] as String,
        message: json['message'] as String,
        severity: json['severity'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        data: (json['data'] as Map).cast<String, dynamic>(),
        acknowledged: json['acknowledged'] as bool? ?? false,
      );
}
