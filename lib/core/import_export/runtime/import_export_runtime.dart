class ImportExportRuntime {
  bool busy = false;
  double progress = 0;
  String operation = 'idle';
  Future<T> runImport<T>(
    Future<T> Function() action, {
    required double onProgress,
  }) => _run('import', action);
  Future<T> runExport<T>(
    Future<T> Function() action, {
    required double onProgress,
  }) => _run('export', action);
  Future<T> _run<T>(String name, Future<T> Function() action) async {
    if (busy) throw StateError('Import/export runtime is already busy');
    busy = true;
    operation = name;
    progress = .01;
    try {
      final result = await action();
      progress = 1;
      return result;
    } finally {
      busy = false;
      operation = 'idle';
    }
  }
}
