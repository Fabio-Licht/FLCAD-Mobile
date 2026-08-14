import '../models/adaptive_studio_models.dart';

class ContextLayout {
  const ContextLayout({
    required this.panels,
    required this.ribbon,
    required this.toolbars,
  });
  final List<String> panels, toolbars;
  final List<RibbonGroup> ribbon;
}

class ContextLayoutCatalog {
  const ContextLayoutCatalog();
  ContextLayout forContext(AdaptiveContext context) => switch (context) {
    AdaptiveContext.importMesh => const ContextLayout(
      panels: ['Project', 'Import', 'Mesh Inspector'],
      ribbon: [
        RibbonGroup('Import Mesh', ['Import STL', 'Mesh Quality', 'Repair']),
      ],
      toolbars: ['Import'],
    ),
    AdaptiveContext.recognition => const ContextLayout(
      panels: ['Recognition', 'Regions', 'Statistics'],
      ribbon: [
        RibbonGroup('Recognition', [
          'Detect Regions',
          'Region Statistics',
          'Recognition Quality',
        ]),
      ],
      toolbars: ['Recognition'],
    ),
    AdaptiveContext.reference => const ContextLayout(
      panels: [
        'Reference Manager',
        'Coordinate Systems',
        'Construction Geometry',
      ],
      ribbon: [
        RibbonGroup('Reference', [
          'Datum Plane',
          'Datum Axis',
          'Datum Point',
          'Coordinate System',
        ]),
      ],
      toolbars: ['Reference'],
    ),
    AdaptiveContext.alignment => const ContextLayout(
      panels: ['Alignment Manager', 'Alignment Preview', 'Reference Mapping'],
      ribbon: [
        RibbonGroup('Alignment', [
          'Plane Alignment',
          'Axis Alignment',
          'Best Fit',
          'ICP',
          'Coordinate Systems',
        ]),
      ],
      toolbars: ['Alignment'],
    ),
    AdaptiveContext.validation => const ContextLayout(
      panels: ['Heat Map', 'Deviation Inspector', 'Tolerance Manager'],
      ribbon: [
        RibbonGroup('Validation', [
          'Heat Map',
          'RMS',
          'Tolerance',
          'Error Inspector',
        ]),
      ],
      toolbars: ['Validation'],
    ),
    AdaptiveContext.sketch => const ContextLayout(
      panels: ['Sketch', 'Constraints', 'Properties'],
      ribbon: [
        RibbonGroup('Sketch', [
          'Line',
          'Arc',
          'Circle',
          'Offset',
          'Constraints',
        ]),
      ],
      toolbars: ['Sketch'],
    ),
    AdaptiveContext.constraints => const ContextLayout(
      panels: ['Constraints', 'Dimensions', 'Solver'],
      ribbon: [
        RibbonGroup('Constraints', [
          'Coincident',
          'Parallel',
          'Dimension',
          'Solve',
        ]),
      ],
      toolbars: ['Constraints'],
    ),
    AdaptiveContext.profiles => const ContextLayout(
      panels: ['Profiles', 'Regions', 'Diagnostics'],
      ribbon: [
        RibbonGroup('Profiles', [
          'Recognize Profile',
          'Validate Profile',
          'Select Region',
        ]),
      ],
      toolbars: ['Profiles'],
    ),
    AdaptiveContext.featureModeling => const ContextLayout(
      panels: ['Feature Tree', 'Timeline', 'Parameters'],
      ribbon: [
        RibbonGroup('Feature', ['Extrude', 'Revolve', 'Sweep', 'Loft']),
      ],
      toolbars: ['Feature'],
    ),
    AdaptiveContext.review => const ContextLayout(
      panels: ['Engineering Score', 'Validation', 'Recommendations'],
      ribbon: [
        RibbonGroup('Review', [
          'Analyze Project',
          'Validation History',
          'Checklist',
        ]),
      ],
      toolbars: ['Review'],
    ),
    AdaptiveContext.finalization => const ContextLayout(
      panels: ['Project Complete', 'Export', 'Report'],
      ribbon: [
        RibbonGroup('Finalization', ['Export', 'Generate Report', 'Archive']),
      ],
      toolbars: ['Finalization'],
    ),
  };
}
