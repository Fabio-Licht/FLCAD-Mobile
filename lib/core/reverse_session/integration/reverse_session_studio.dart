class ReverseSessionPanel {
  const ReverseSessionPanel(this.name);
  final String name;
}

class ReverseSessionStudio {
  const ReverseSessionStudio();
  String get workspace => 'Professional Session Workspace';
  List<ReverseSessionPanel> get panels => const [
    ReverseSessionPanel('Session Overview'),
    ReverseSessionPanel('Journal'),
    ReverseSessionPanel('Milestones'),
    ReverseSessionPanel('Snapshots'),
    ReverseSessionPanel('Recovery'),
    ReverseSessionPanel('Analytics'),
    ReverseSessionPanel('Current Session'),
  ];
}
