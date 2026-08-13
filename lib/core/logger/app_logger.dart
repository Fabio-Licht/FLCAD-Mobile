import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

abstract final class AppLogger {
  static void log(
    String message, {
    LogLevel level = LogLevel.info,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kReleaseMode) return;
    debugPrint('[${level.name.toUpperCase()}] $message');
    if (error != null) debugPrint('  $error');
    if (stackTrace != null) debugPrintStack(stackTrace: stackTrace);
  }
}
