import 'dart:math' as math;
import '../../sketch_engine/entities/sketch_entities.dart';
import '../../sketch_engine/models/sketch_models.dart';
import '../models/profile_models.dart';
import '../validation/profile_validation.dart';

class ProfileRecognitionOutput {
  const ProfileRecognitionOutput(
    this.profiles,
    this.loops,
    this.regions,
    this.validation,
    this.intent,
  );
  final List<RecognizedProfile> profiles;
  final List<ProfileLoop> loops;
  final List<SketchRegion> regions;
  final ProfileValidationResult validation;
  final IntentRecognition intent;
}

class ProfileRecognizer {
  const ProfileRecognizer({this.tolerance = 1e-6, this.tinyThreshold = 1e-4});
  final double tolerance, tinyThreshold;
  ProfileRecognitionOutput recognize(Iterable<SketchEntity> source) {
    final entities = source.where((e) => e.visible && !e.construction).toList(),
        profiles = <RecognizedProfile>[],
        issues = <ProfileIssue>[];
    final lines = entities.whereType<SketchLine>().toList(),
        closedCurves = entities
            .where((e) => e is SketchCircle || e is SketchEllipse)
            .toList();
    final duplicateKeys = <String, String>{};
    for (final line in lines) {
      final a = _point(line, 'start'),
          b = _point(line, 'end'),
          key = [_key(a), _key(b)]..sort();
      final signature = key.join('>');
      if (duplicateKeys.containsKey(signature)) {
        issues.add(
          ProfileIssue(
            ProfileIssueType.duplicatedEntity,
            'Duplicated edge',
            entityIds: [duplicateKeys[signature]!, line.id],
          ),
        );
      } else {
        duplicateKeys[signature] = line.id;
      }
      if (_distance(a, b) < tinyThreshold) {
        issues.add(
          ProfileIssue(
            ProfileIssueType.tinyRegion,
            'Tiny edge',
            entityIds: [line.id],
          ),
        );
      }
    }
    final remaining = lines.toSet();
    while (remaining.isNotEmpty) {
      final component = <SketchLine>[], queue = <SketchLine>[remaining.first];
      remaining.remove(queue.first);
      while (queue.isNotEmpty) {
        final current = queue.removeLast();
        component.add(current);
        final endpoints = [_point(current, 'start'), _point(current, 'end')];
        final touching = remaining
            .where(
              (line) => endpoints.any(
                (p) =>
                    _distance(p, _point(line, 'start')) <= tolerance ||
                    _distance(p, _point(line, 'end')) <= tolerance,
              ),
            )
            .toList();
        queue.addAll(touching);
        remaining.removeAll(touching);
      }
      profiles.add(_lineProfile(component, issues));
    }
    for (var i = 0; i < lines.length; i++) {
      for (var j = i + 1; j < lines.length; j++) {
        if (_crosses(lines[i], lines[j])) {
          final ids = [lines[i].id, lines[j].id];
          issues.add(
            ProfileIssue(
              ProfileIssueType.selfIntersection,
              'Edges cross inside the profile',
              entityIds: ids,
              suggestedFix: 'Split or trim the crossing edges',
            ),
          );
          for (final profile in profiles.where(
            (p) => ids.every(p.entityIds.contains),
          )) {
            profile.type = ProfileType.selfIntersecting;
          }
        }
      }
    }
    final ends = <SketchVector>[];
    for (final line in lines) {
      ends
        ..add(_point(line, 'start'))
        ..add(_point(line, 'end'));
    }
    for (var i = 0; i < ends.length; i++) {
      for (var j = i + 1; j < ends.length; j++) {
        final distance = _distance(ends[i], ends[j]);
        if (distance > tolerance && distance < tinyThreshold) {
          issues.add(
            const ProfileIssue(
              ProfileIssueType.microGap,
              'Micro gap detected',
              suggestedFix: 'Apply a coincident constraint',
            ),
          );
        }
      }
    }
    for (final curve in closedCurves) {
      final area = _curveArea(curve), perimeter = _curvePerimeter(curve);
      profiles.add(
        RecognizedProfile(
          type: ProfileType.closed,
          entityIds: [curve.id],
          area: area,
          perimeter: perimeter,
        ),
      );
    }
    final closed = profiles.where((p) => p.type == ProfileType.closed).toList()
      ..sort((a, b) => b.area.compareTo(a.area));
    final loops = <ProfileLoop>[];
    for (var i = 0; i < closed.length; i++) {
      final p = closed[i];
      if (i > 0) p.type = ProfileType.nested;
      final type = i == 0
          ? LoopType.outer
          : i.isOdd
          ? LoopType.hole
          : LoopType.island;
      loops.add(
        ProfileLoop(
          profileId: p.id,
          type: type,
          entityIds: p.entityIds,
          orientation: type == LoopType.hole
              ? LoopOrientation.clockwise
              : LoopOrientation.counterClockwise,
          area: p.area,
          perimeter: p.perimeter,
        ),
      );
    }
    for (final p in profiles.where(
      (p) => p.type == ProfileType.open || p.type == ProfileType.chain,
    )) {
      loops.add(
        ProfileLoop(
          profileId: p.id,
          type: LoopType.outer,
          entityIds: p.entityIds,
          orientation: LoopOrientation.invalid,
          area: 0,
          perimeter: p.perimeter,
          diagnostics: ['Broken loop'],
        ),
      );
    }
    final regions = <SketchRegion>[];
    for (var i = 0; i < loops.length; i++) {
      final l = loops[i];
      regions.add(
        SketchRegion(
          type: l.orientation == LoopOrientation.invalid
              ? RegionType.open
              : l.type == LoopType.hole
              ? RegionType.hole
              : l.type == LoopType.island
              ? RegionType.island
              : RegionType.closed,
          loopIds: [l.id],
          priority: loops.length - i,
        ),
      );
    }
    if (profiles.length > 1 &&
        profiles.every((p) => p.type == ProfileType.open)) {
      issues.add(
        const ProfileIssue(
          ProfileIssueType.disconnectedIsland,
          'Multiple disconnected open profiles',
        ),
      );
    }
    return ProfileRecognitionOutput(
      profiles,
      loops,
      regions,
      ProfileValidationResult(issues),
      _intent(entities, profiles),
    );
  }

  RecognizedProfile _lineProfile(
    List<SketchLine> lines,
    List<ProfileIssue> issues,
  ) {
    final degrees = <String, int>{};
    for (final l in lines) {
      degrees.update(_key(_point(l, 'start')), (v) => v + 1, ifAbsent: () => 1);
      degrees.update(_key(_point(l, 'end')), (v) => v + 1, ifAbsent: () => 1);
    }
    final open = degrees.entries.where((e) => e.value == 1).toList();
    final closed = open.isEmpty && degrees.values.every((d) => d == 2);
    if (!closed) {
      for (final e in open) {
        issues.add(
          ProfileIssue(
            ProfileIssueType.openEnd,
            'Open profile endpoint ${e.key}',
            entityIds: lines.map((l) => l.id).toList(),
            suggestedFix: 'Close the gap or add a coincident constraint',
          ),
        );
      }
    }
    final ordered = _order(lines),
        points = ordered.map((l) => _point(l, 'start')).toList();
    var area = 0.0, perimeter = 0.0;
    for (final l in lines) {
      perimeter += _distance(_point(l, 'start'), _point(l, 'end'));
    }
    if (closed) {
      for (var i = 0; i < points.length; i++) {
        final a = points[i], b = points[(i + 1) % points.length];
        area += a.x * b.y - b.x * a.y;
      }
      area = area.abs() / 2;
      if (area <= tolerance) {
        issues.add(
          ProfileIssue(
            ProfileIssueType.zeroArea,
            'Closed profile has zero area',
            entityIds: lines.map((l) => l.id).toList(),
          ),
        );
      }
    }
    return RecognizedProfile(
      type: closed
          ? ProfileType.closed
          : lines.length == 1
          ? ProfileType.open
          : ProfileType.chain,
      entityIds: lines.map((e) => e.id),
      area: area,
      perimeter: perimeter,
      diagnostics: [if (!closed) 'Open ends detected'],
    );
  }

  List<SketchLine> _order(List<SketchLine> input) {
    if (input.length < 2) return input;
    final result = <SketchLine>[input.first], unused = input.skip(1).toList();
    while (unused.isNotEmpty) {
      final end = _point(result.last, 'end');
      final index = unused.indexWhere(
        (l) =>
            _distance(end, _point(l, 'start')) <= tolerance ||
            _distance(end, _point(l, 'end')) <= tolerance,
      );
      if (index < 0) {
        result.addAll(unused);
        break;
      }
      result.add(unused.removeAt(index));
    }
    return result;
  }

  IntentRecognition _intent(List<SketchEntity> e, List<RecognizedProfile> p) {
    final lines = e.whereType<SketchLine>().length,
        circles = e.whereType<SketchCircle>().length,
        construction = e.where((x) => x.construction).length,
        references = e.where((x) => x.reference).length;
    if (lines == 4 && p.any((x) => x.type == ProfileType.closed)) {
      return const IntentRecognition(GeometricIntent.rectangle, .95, [
        'Four connected linear edges',
        'Closed profile',
      ]);
    }
    if (circles >= 3) {
      return IntentRecognition(GeometricIntent.holePattern, .85, [
        '$circles circles',
      ]);
    }
    if (construction > e.length / 2) {
      return const IntentRecognition(GeometricIntent.constructionPattern, .8, [
        'Construction majority',
      ]);
    }
    if (references > 0) {
      return const IntentRecognition(GeometricIntent.referencePattern, .75, [
        'Reference geometry',
      ]);
    }
    return IntentRecognition(
      p.any((x) => x.type == ProfileType.closed)
          ? GeometricIntent.baseSketch
          : GeometricIntent.auxiliarySketch,
      .65,
      ['Profile topology'],
    );
  }

  SketchVector _point(SketchEntity e, String key) =>
      SketchVector.fromJson(e.parameters[key]);
  String _key(SketchVector p) =>
      '${(p.x / tolerance).round()}:${(p.y / tolerance).round()}';
  double _distance(SketchVector a, SketchVector b) =>
      math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2));
  double _curveArea(SketchEntity e) {
    if (e is SketchCircle) {
      final r = (e.parameters['radius'] as num).toDouble();
      return math.pi * r * r;
    }
    if (e is SketchEllipse) {
      return math.pi *
          (e.parameters['radiusX'] as num) *
          (e.parameters['radiusY'] as num);
    }
    return 0;
  }

  double _curvePerimeter(SketchEntity e) {
    if (e is SketchCircle) return 2 * math.pi * (e.parameters['radius'] as num);
    if (e is SketchEllipse) {
      final a = (e.parameters['radiusX'] as num),
          b = (e.parameters['radiusY'] as num);
      return math.pi * (3 * (a + b) - math.sqrt((3 * a + b) * (a + 3 * b)));
    }
    return 0;
  }

  bool _crosses(SketchLine first, SketchLine second) {
    final a = _point(first, 'start'),
        b = _point(first, 'end'),
        c = _point(second, 'start'),
        d = _point(second, 'end');
    if ([a, b].any((p) => [c, d].any((q) => _distance(p, q) <= tolerance))) {
      return false;
    }
    double side(SketchVector p, SketchVector q, SketchVector r) =>
        (q.x - p.x) * (r.y - p.y) - (q.y - p.y) * (r.x - p.x);
    return side(a, b, c) * side(a, b, d) < 0 &&
        side(c, d, a) * side(c, d, b) < 0;
  }
}
