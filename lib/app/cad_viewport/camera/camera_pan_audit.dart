import 'dart:io';

/// Temporary R2-007 runtime trace. It buffers one gesture and writes once at
/// the end so instrumentation cannot change pointer-event timing.
class CameraPanAudit {
  CameraPanAudit._();

  static final List<String> _lines = <String>[];
  static bool active = false;
  static String get path =>
      '${Directory.systemTemp.path}${Platform.pathSeparator}flcad-r2-007-pan-audit.log';

  static void begin() {
    active = true;
    _lines
      ..clear()
      ..add('Pan iniciado')
      ..add('↓');
  }

  static void record(String value) {
    if (!active) return;
    _lines
      ..add(value)
      ..add('↓');
  }

  static void end() {
    if (!active) return;
    _lines.add('Pan encerrado');
    File(path).writeAsStringSync('${_lines.join('\r\n')}\r\n');
    active = false;
  }
}
