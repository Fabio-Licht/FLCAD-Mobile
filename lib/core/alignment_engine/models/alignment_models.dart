import '../../cad_kernel/models/kernel_models.dart';
import '../../utils/id_generator.dart';

enum AlignmentType {
  manual,
  threePoint,
  plane,
  axis,
  point,
  planeAxis,
  coordinateSystem,
  bestFit,
  localBestFit,
  regionBestFit,
  icp,
  meshToMesh,
  meshToCad,
  cadToCad,
  sequential,
  hybrid,
}

enum AlignmentStatus {
  prepared,
  previewed,
  applied,
  committed,
  cancelled,
  rolledBack,
  kernelUnavailable,
  unsupportedOperation,
  invalid,
  failed,
}

enum AlignmentReferenceSource {
  datumPlane,
  datumAxis,
  datumPoint,
  coordinateSystem,
  recognizedPlane,
  recognizedCylinder,
  recognizedCone,
  recognizedSphere,
  sketchGeometry,
  featureGeometry,
  persistentId,
  meshRegion,
}

class AlignmentVector {
  const AlignmentVector(this.x, this.y, this.z);
  final double x, y, z;
  bool get finite => x.isFinite && y.isFinite && z.isFinite;
  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'z': z};
}

class AlignmentMatrix {
  const AlignmentMatrix(this.values);
  final List<double> values;
  static const identity = AlignmentMatrix([
    1,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    1,
  ]);
  bool get valid => values.length == 16 && values.every((e) => e.isFinite);
  double get determinant3 => values.length < 11
      ? 0
      : values[0] * (values[5] * values[10] - values[6] * values[9]) -
            values[1] * (values[4] * values[10] - values[6] * values[8]) +
            values[2] * (values[4] * values[9] - values[5] * values[8]);
  List<double> toJson() => List.of(values);
}

class AlignmentReference {
  const AlignmentReference({required this.id, required this.source});
  final String id;
  final AlignmentReferenceSource source;
  Map<String, dynamic> toJson() => {'id': id, 'source': source.name};
}

class AlignmentParameters {
  AlignmentParameters({
    this.translation = const AlignmentVector(0, 0, 0),
    this.rotation = const AlignmentVector(0, 0, 0),
    this.matrix = AlignmentMatrix.identity,
    Set<String>? lockedAxes,
    this.iterations = 50,
    this.tolerance = .001,
  }) : lockedAxes = lockedAxes ?? {};
  AlignmentVector translation, rotation;
  AlignmentMatrix matrix;
  final Set<String> lockedAxes;
  int iterations;
  double tolerance;
  Map<String, dynamic> toJson() => {
    'translation': translation.toJson(),
    'rotation': rotation.toJson(),
    'matrix': matrix.toJson(),
    'lockedAxes': lockedAxes.toList(),
    'iterations': iterations,
    'tolerance': tolerance,
  };
}

class AlignmentInput {
  AlignmentInput({
    required this.movingReferences,
    required this.fixedReferences,
    this.movingShape,
    this.fixedShape,
  });
  final List<AlignmentReference> movingReferences, fixedReferences;
  final ShapeHandle? movingShape, fixedShape;
  Map<String, dynamic> toJson() => {
    'movingReferences': movingReferences.map((e) => e.toJson()).toList(),
    'fixedReferences': fixedReferences.map((e) => e.toJson()).toList(),
    'movingShape': movingShape?.toJson(),
    'fixedShape': fixedShape?.toJson(),
  };
}

class Alignment {
  Alignment({
    required this.type,
    required this.input,
    required this.parameters,
    String? id,
  }) : id = id ?? 'alignment:${IdGenerator.generate()}',
       timestamp = DateTime.now().toUtc();
  final String id;
  AlignmentType type;
  final AlignmentInput input;
  final AlignmentParameters parameters;
  final DateTime timestamp;
  int version = 1;
  AlignmentStatus status = AlignmentStatus.prepared;
  ShapeHandle? output;
  final List<String> dependencies = [], diagnostics = [];
  double rms = 0, maximumError = 0, averageError = 0, confidence = 0;
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'input': input.toJson(),
    'parameters': parameters.toJson(),
    'timestamp': timestamp.toIso8601String(),
    'version': version,
    'status': status.name,
    'output': output?.toJson(),
    'dependencies': dependencies,
    'diagnostics': diagnostics,
    'rms': rms,
    'maximumError': maximumError,
    'averageError': averageError,
    'confidence': confidence,
  };
}

class AlignmentExecutionResult {
  const AlignmentExecutionResult(
    this.status, {
    this.shape,
    this.diagnostics = const [],
  });
  final AlignmentStatus status;
  final ShapeHandle? shape;
  final List<String> diagnostics;
  bool get success => status == AlignmentStatus.committed && shape != null;
}
