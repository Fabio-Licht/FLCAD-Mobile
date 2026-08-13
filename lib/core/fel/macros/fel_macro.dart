class FELMacro {
  const FELMacro({
    required this.name,
    required this.source,
    required this.createdAt,
    required this.parameters,
  });
  final String name, source;
  final DateTime createdAt;
  final List<String> parameters;
  Map<String, dynamic> toJson() => {
    'name': name,
    'source': source,
    'createdAt': createdAt.toIso8601String(),
    'parameters': parameters,
  };
}

class FELMacroRecorder {
  final List<String> _commands = [];
  bool _recording = false;
  void start() {
    _commands.clear();
    _recording = true;
  }

  void record(String command) {
    if (_recording) _commands.add(command);
  }

  FELMacro stop(String name, {List<String> parameters = const []}) {
    _recording = false;
    return FELMacro(
      name: name,
      source: _commands.join('\n'),
      createdAt: DateTime.now(),
      parameters: parameters,
    );
  }
}
