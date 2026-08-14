class PlatformCertificationPanel {
  const PlatformCertificationPanel(this.name);
  final String name;
}

class PlatformCertificationStudio {
  const PlatformCertificationStudio();
  List<PlatformCertificationPanel> get panels => const [
    PlatformCertificationPanel('Platform Health'),
    PlatformCertificationPanel('Architecture Report'),
    PlatformCertificationPanel('Certification Status'),
    PlatformCertificationPanel('Readiness Dashboard'),
  ];
}
