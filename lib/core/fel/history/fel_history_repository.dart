import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

class FELHistoryRepository {
  Future<void> append({
    required String projectPath,
    required String source,
    required String command,
    required String description,
  }) async {
    final file = File(path.join(projectPath, 'FEL', 'fel_history.json'));
    await file.parent.create(recursive: true);
    final entries = await load(projectPath);
    entries.add({
      'source': source,
      'command': command,
      'description': description,
      'timestamp': DateTime.now().toIso8601String(),
    });
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(
      const JsonEncoder.withIndent(
        '  ',
      ).convert({'version': 1, 'entries': entries}),
      flush: true,
    );
    if (await file.exists()) await file.delete();
    await temp.rename(file.path);
  }

  Future<List<Map<String, dynamic>>> load(String projectPath) async {
    final file = File(path.join(projectPath, 'FEL', 'fel_history.json'));
    if (!await file.exists()) return [];
    try {
      final data =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return (data['entries'] as List)
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList();
    } catch (_) {
      return [];
    }
  }
}
