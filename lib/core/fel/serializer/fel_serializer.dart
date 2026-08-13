import 'dart:io';
import '../ast/ast_nodes.dart';

class FELSerializer {
  const FELSerializer();
  Future<void> save(String source, String path) async {
    if (!path.toLowerCase().endsWith('.fel')) {
      throw ArgumentError('Scripts FEL devem usar extensão .fel');
    }
    final file = File(path), temp = File('$path.tmp');
    await file.parent.create(recursive: true);
    await temp.writeAsString(source, flush: true);
    if (await file.exists()) await file.delete();
    await temp.rename(file.path);
  }

  Future<String> load(String path) => File(path).readAsString();
  String astJson(ProgramNode program) => program.toJson().toString();
}
