import '../../logger/app_logger.dart';

enum EngineeringLogLevel { debug, info, warning, error }

class EngineeringLogRecord {
  const EngineeringLogRecord(
    this.timestamp,
    this.level,
    this.message,
    this.domain,
    this.context,
  );
  final DateTime timestamp;
  final EngineeringLogLevel level;
  final String message, domain;
  final Map<String, dynamic> context;
}

typedef EngineeringLogSink = void Function(EngineeringLogRecord record);

class EngineeringLogger {
  EngineeringLogger({
    this.enabled = true,
    List<EngineeringLogSink> sinks = const [],
  }) : _sinks = [_appSink, ...sinks];
  final bool enabled;
  final List<EngineeringLogSink> _sinks;
  void log(
    String message, {
    String domain = 'engineering',
    EngineeringLogLevel level = EngineeringLogLevel.info,
    Map<String, dynamic> context = const {},
  }) {
    if (!enabled) return;
    final record = EngineeringLogRecord(
      DateTime.now(),
      level,
      message,
      domain,
      context,
    );
    for (final sink in _sinks) {
      sink(record);
    }
  }

  static void _appSink(EngineeringLogRecord r) => AppLogger.log(
    '[${r.domain}] ${r.message}',
    level: switch (r.level) {
      EngineeringLogLevel.debug => LogLevel.debug,
      EngineeringLogLevel.info => LogLevel.info,
      EngineeringLogLevel.warning => LogLevel.warning,
      EngineeringLogLevel.error => LogLevel.error,
    },
  );
}
