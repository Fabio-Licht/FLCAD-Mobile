class AIModelMetadata {
  const AIModelMetadata({
    required this.id,
    required this.name,
    required this.version,
    required this.hash,
    required this.author,
    required this.releasedAt,
    required this.compatibility,
  });
  final String id;
  final String name;
  final String version;
  final String hash;
  final String author;
  final DateTime releasedAt;
  final List<String> compatibility;
}
