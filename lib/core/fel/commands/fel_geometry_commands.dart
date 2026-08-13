import 'dart:math' as math;

import '../../geometric_kernel/curves/curves.dart';
import '../../geometric_kernel/geometry/primitives.dart';
import '../../geometric_kernel/geometry/vectors.dart';
import '../../geometric_kernel/surfaces/surfaces.dart';
import '../runtime/fel_context.dart';
import '../types/fel_type.dart';
import 'fel_command.dart';

class DistanceCommand implements FELCommand {
  @override
  String get name => 'DISTANCE';
  @override
  List<FELType> get argumentTypes => const [FELType.point, FELType.point];
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> args,
  ) async {
    final a = args[0].value as Vector3,
        b = args[1].value as Vector3,
        value = a.distanceTo(b);
    return FELCommandResult(
      value: FELValue(FELType.number, value),
      description: 'DISTANCE = $value',
    );
  }
}

class AngleCommand implements FELCommand {
  @override
  String get name => 'ANGLE';
  @override
  List<FELType> get argumentTypes => const [FELType.vector, FELType.vector];
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> args,
  ) async {
    final a = args[0].value as Vector3, b = args[1].value as Vector3;
    if (a.length == 0 || b.length == 0) {
      throw StateError('Angle requires non-zero vectors');
    }
    final value = (a.dot(b) / (a.length * b.length)).clamp(-1, 1).toDouble(),
        angle = math.acos(value);
    return FELCommandResult(
      value: FELValue(FELType.number, angle),
      description: 'ANGLE = $angle',
    );
  }
}

class ProjectPointCommand implements FELCommand {
  @override
  String get name => 'PROJECT';
  @override
  List<FELType> get argumentTypes => const [FELType.point, FELType.plane];
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> args,
  ) async {
    final result = (args[1].value as Plane3).project(args[0].value as Vector3);
    return FELCommandResult(
      value: FELValue(FELType.point, result),
      description: 'Point projected',
    );
  }
}

class EvaluateCurveCommand implements FELCommand {
  @override
  String get name => 'EVALUATE CURVE';
  @override
  List<FELType> get argumentTypes => const [FELType.curve, FELType.number];
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> args,
  ) async {
    final result = (args[0].value as ParametricCurve3).evaluate(
      (args[1].value as num).toDouble(),
    );
    return FELCommandResult(
      value: FELValue(FELType.point, result),
      description: 'Curve evaluated',
    );
  }
}

class EvaluateSurfaceCommand implements FELCommand {
  @override
  String get name => 'EVALUATE SURFACE';
  @override
  List<FELType> get argumentTypes => const [
    FELType.surface,
    FELType.number,
    FELType.number,
  ];
  @override
  Future<FELCommandResult> execute(
    FELExecutionContext context,
    List<FELValue> args,
  ) async {
    final result = (args[0].value as ParametricSurface3).evaluate(
      (args[1].value as num).toDouble(),
      (args[2].value as num).toDouble(),
    );
    return FELCommandResult(
      value: FELValue(FELType.point, result.position),
      description: 'Surface evaluated',
    );
  }
}

List<FELCommand> createGeometryFELCommands() => [
  DistanceCommand(),
  AngleCommand(),
  ProjectPointCommand(),
  EvaluateCurveCommand(),
  EvaluateSurfaceCommand(),
];
