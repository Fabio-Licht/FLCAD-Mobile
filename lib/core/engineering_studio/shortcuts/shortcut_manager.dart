class ShortcutBinding {
  const ShortcutBinding(this.keys, this.commandId, this.context, this.profile);
  final String keys, commandId, context, profile;
}

class ShortcutManager {
  final List<ShortcutBinding> _bindings = [];
  void bind(ShortcutBinding binding) {
    _bindings.removeWhere(
      (b) =>
          b.keys == binding.keys &&
          b.context == binding.context &&
          b.profile == binding.profile,
    );
    _bindings.add(binding);
  }

  String? resolve(
    String keys, {
    required String context,
    required String profile,
  }) => _bindings
      .where(
        (b) =>
            b.keys == keys &&
            b.profile == profile &&
            (b.context == context || b.context == 'global'),
      )
      .map((e) => e.commandId)
      .firstOrNull;
  List<ShortcutBinding> get bindings => List.unmodifiable(_bindings);
}
