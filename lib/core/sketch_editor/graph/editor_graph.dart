class EditorGraph {
  final Map<String, Set<String>> _operations = {};
  Map<String, Set<String>> get operations => Map.unmodifiable(_operations);
  void record(String operationId, Iterable<String> entityIds) =>
      _operations[operationId] = entityIds.toSet();
  void remove(String operationId) => _operations.remove(operationId);
  Map<String, dynamic> toJson() =>
      _operations.map((k, v) => MapEntry(k, v.toList()));
}
