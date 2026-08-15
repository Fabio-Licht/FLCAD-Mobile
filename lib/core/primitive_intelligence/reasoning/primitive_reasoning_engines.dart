import '../../geometric_recognition/models/recognition_models.dart';
import '../models/primitive_intelligence_models.dart';

class AxisIntelligence {
  const AxisIntelligence();
  AxisHypothesis? analyze(PrimitiveObservation value) {
    final axis = value.vectors['axis'];
    if (axis == null ||
        !const {
          PrimitiveType.cylinder,
          PrimitiveType.cone,
          PrimitiveType.torus,
        }.contains(value.type)) {
      return null;
    }
    final function = value.measures['axisRole'] == 1
        ? 'possible secondary axis'
        : (value.measures['coaxiality'] ?? 0) > 0
        ? 'possible main axis'
        : 'possible revolution axis';
    return AxisHypothesis(
      axis: axis,
      function: function,
      confidence: value.recognitionConfidence,
      relatedPrimitiveIds: [value.id, ...value.adjacentIds],
    );
  }
}

class SymmetryIntelligence {
  const SymmetryIntelligence();
  SymmetryHypothesis? analyze(PrimitiveObservation value) {
    final scores = <SymmetryKind, double>{
      SymmetryKind.x: value.measures['symmetryX'] ?? 0,
      SymmetryKind.y: value.measures['symmetryY'] ?? 0,
      SymmetryKind.z: value.measures['symmetryZ'] ?? 0,
      SymmetryKind.radial: value.measures['radialSymmetry'] ?? 0,
      SymmetryKind.local: value.measures['localSymmetry'] ?? 0,
      SymmetryKind.partial: value.measures['partialSymmetry'] ?? 0,
    };
    final best = scores.entries.reduce((a, b) => a.value >= b.value ? a : b);
    if (best.value == 0) {
      return null;
    }
    return SymmetryHypothesis(
      kind: best.key,
      score: best.value,
      justification: 'Highest explicitly supplied symmetry score.',
    );
  }
}

class PatternIntelligence {
  const PatternIntelligence();
  List<PatternHypothesis> analyze(List<PrimitiveObservation> values) {
    final groups = <String, List<PrimitiveObservation>>{};
    for (final value in values) {
      final group = value.measures['patternGroup'];
      if (group != null) {
        (groups[group.toString()] ??= []).add(value);
      }
    }
    return List.unmodifiable(
      groups.entries.where((e) => e.value.length >= 2).map((entry) {
        final first = entry.value.first;
        final kindIndex = first.measures['patternKind']?.toInt() ?? 0;
        final kind = PatternKind
            .values[kindIndex.clamp(0, PatternKind.values.length - 1)];
        return PatternHypothesis(
          kind: kind,
          memberIds: entry.value.map((e) => e.id),
          score: first.measures['patternScore'] ?? 0,
          justification:
              'Members share recognition pattern group ${entry.key}.',
        );
      }),
    );
  }
}

class ManufacturingIntelligence {
  const ManufacturingIntelligence();
  String suggestion(PrimitiveObservation value, PrimitiveFunction function) =>
      switch ((value.type, function)) {
        (PrimitiveType.plane, PrimitiveFunction.support) =>
          'Possible support surface.',
        (PrimitiveType.cone, PrimitiveFunction.draft) => 'Possible draft.',
        (PrimitiveType.cylinder, PrimitiveFunction.hole) =>
          'Possible deep hole.',
        (PrimitiveType.torus, _) => 'Possible functional radius.',
        (PrimitiveType.cylinder, PrimitiveFunction.mainAxis) =>
          'Possible main axis.',
        _ => 'Review as ${function.name} engineering reference.',
      };
}
