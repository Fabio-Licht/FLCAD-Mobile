class InteractiveReversePanel {
  const InteractiveReversePanel(this.name);
  final String name;
}

class InteractiveReverseStudio {
  const InteractiveReverseStudio();
  List<InteractiveReversePanel> get panels => const [
    InteractiveReversePanel('Interactive Reverse Workspace'),
    InteractiveReversePanel('Selection Inspector'),
    InteractiveReversePanel('Context Actions'),
    InteractiveReversePanel('Interactive Advisor'),
    InteractiveReversePanel('Selection Analytics'),
  ];
}
