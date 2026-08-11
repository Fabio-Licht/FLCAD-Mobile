enum ScanSessionStatus {
  created,
  capturing,
  processing,
  completed,
}

class ScanSession {
  final String id;
  final String projectId;
  final String name;
  final DateTime createdAt;
  final ScanSessionStatus status;

  const ScanSession({
    required this.id,
    required this.projectId,
    required this.name,
    required this.createdAt,
    required this.status,
  });

  ScanSession copyWith({
    String? id,
    String? projectId,
    String? name,
    DateTime? createdAt,
    ScanSessionStatus? status,
  }) {
    return ScanSession(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}