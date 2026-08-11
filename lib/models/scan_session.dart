import 'captured_image.dart';

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
  final List<CapturedImage> images;

  const ScanSession({
    required this.id,
    required this.projectId,
    required this.name,
    required this.createdAt,
    required this.status,
    required this.images,
  });

  ScanSession copyWith({
    String? id,
    String? projectId,
    String? name,
    DateTime? createdAt,
    ScanSessionStatus? status,
    List<CapturedImage>? images,
  }) {
    return ScanSession(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      images: images ?? this.images,
    );
  }

  int get imageCount => images.length;

  bool get isEmpty => images.isEmpty;

  bool get isNotEmpty => images.isNotEmpty;
}