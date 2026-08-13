import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../models/ai_context.dart';
import '../models/ai_result.dart';

class AICache {
  Future<AIResult?> read(AIContext context, String pluginId) async {
    final file = _file(context, pluginId);
    if (!await file.exists()) return null;
    try {
      return AIResult.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>,
      ).copyWith(fromCache: true);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(AIContext context, AIResult result) async {
    final file = _file(context, result.pluginId);
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(result.toJson()), flush: true);
  }

  File _file(AIContext context, String pluginId) {
    final safeFingerprint = context.fingerprint.codeUnits
        .fold<int>(17, (value, item) => 37 * value + item)
        .toUnsigned(32)
        .toRadixString(16);
    return File(
      path.join(
        context.projectPath,
        'AI',
        'Cache',
        context.task.name,
        '${pluginId}_$safeFingerprint.json',
      ),
    );
  }
}
