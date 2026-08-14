import 'dart:io';
import 'package:flcad_mobile/core/cad_kernel/opencascade/open_cascade_ffi.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.length != 1) {
    stderr.writeln('Usage: dart run tool/native_certification.dart <flcad_opencascade.dll>');
    exitCode = 64;
    return;
  }
  final bridge = OpenCascadeFFI.load(path: arguments.single);
  await bridge.initialize();
  final version = await bridge.version();
  final capabilities = await bridge.capabilities();
  final diagnostics = await bridge.diagnostics();
  stdout.writeln('OpenCascade version: $version');
  stdout.writeln('Capabilities: ${capabilities.toList()..sort()}');
  stdout.writeln('Diagnostics: $diagnostics');
  await bridge.shutdown();
}
