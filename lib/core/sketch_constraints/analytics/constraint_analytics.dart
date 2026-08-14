import '../models/constraint_models.dart';

class ConstraintAnalytics {
  int totalConstraints = 0,
      solved = 0,
      conflicts = 0,
      iterations = 0,
      failures = 0,
      solveCount = 0,
      overdefined = 0,
      underdefined = 0;
  int totalSolveMicros = 0;
  final Map<SketchConstraintType, int> constraintTypes = {};
  double get averageSolveTimeMicros =>
      solveCount == 0 ? 0 : totalSolveMicros / solveCount;
  double get failureRate => solveCount == 0 ? 0 : failures / solveCount;
  double get overdefinedRatio =>
      totalConstraints == 0 ? 0 : overdefined / totalConstraints;
  double get underdefinedRatio =>
      totalConstraints == 0 ? 0 : underdefined / totalConstraints;
  Map<String, dynamic> toJson() => {
    'totalConstraints': totalConstraints,
    'solved': solved,
    'conflicts': conflicts,
    'averageSolveTimeMicros': averageSolveTimeMicros,
    'iterations': iterations,
    'constraintTypes': constraintTypes.map((k, v) => MapEntry(k.name, v)),
    'failureRate': failureRate,
    'overdefinedRatio': overdefinedRatio,
    'underdefinedRatio': underdefinedRatio,
  };
}
