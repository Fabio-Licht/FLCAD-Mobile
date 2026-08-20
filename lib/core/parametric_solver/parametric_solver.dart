/// Completely domain-neutral contract shared by Sketch and every current or
/// future parametric feature. Entity semantics belong exclusively to adapters.
class ParametricDegreeOfFreedom {
  const ParametricDegreeOfFreedom(
    this.id, {
    this.parameterIds = const <String>{},
    this.fixed = false,
  });
  final String id;
  final Set<String> parameterIds;
  final bool fixed;
}

class ParametricParameter {
  const ParametricParameter(this.id, this.value, {this.driving = true});
  final String id;
  final double value;
  final bool driving;
}

class ParametricDependency {
  const ParametricDependency(this.id, this.members, {this.enabled = true});
  final String id;
  final Set<String> members;
  final bool enabled;
}

/// Adapters evaluate geometric meaning and expose only affected freedoms.
class ParametricRestriction {
  const ParametricRestriction(
    this.id,
    this.members, {
    this.enabled = true,
    this.blocking = false,
  });
  final String id;
  final Set<String> members;
  final bool enabled;
  final bool blocking;
}

class ParametricPriority {
  const ParametricPriority(this.referenceId, this.weight);
  final String referenceId;
  final double weight;
}

class ParametricSolveRequest {
  const ParametricSolveRequest({
    required this.first,
    required this.second,
    required this.degreesOfFreedom,
    this.parameters = const <ParametricParameter>[],
    this.dependencies = const <ParametricDependency>[],
    this.anchors = const <String>{},
    this.restrictions = const <ParametricRestriction>[],
    this.priorities = const <ParametricPriority>[],
    this.preferredAnchor,
  });
  final String first;
  final String second;
  final Iterable<ParametricDegreeOfFreedom> degreesOfFreedom;
  final Iterable<ParametricParameter> parameters;
  final Iterable<ParametricDependency> dependencies;
  final Set<String> anchors;
  final Iterable<ParametricRestriction> restrictions;
  final Iterable<ParametricPriority> priorities;
  final String? preferredAnchor;
}

class ParametricMotionPlan {
  const ParametricMotionPlan({
    required this.anchor,
    required this.moving,
    required this.propagated,
  });
  final String anchor;
  final String moving;
  final Set<String> propagated;
}

class ParametricSolveConflict implements Exception {
  const ParametricSolveConflict(this.message, {this.blockingIds = const []});
  final String message;
  final List<String> blockingIds;
  @override
  String toString() => message;
}

/// Selects the lowest-cost legal propagation set. No entity types enter here.
class ParametricPropagationSolver {
  const ParametricPropagationSolver();

  ParametricMotionPlan solve(ParametricSolveRequest request) {
    final dofs = {
      for (final freedom in request.degreesOfFreedom) freedom.id: freedom,
    };
    if (!dofs.containsKey(request.first) || !dofs.containsKey(request.second)) {
      throw const ParametricSolveConflict('Unknown parametric reference.');
    }
    final parameterIds = request.parameters.map((item) => item.id).toSet();
    for (final freedom in dofs.values) {
      final unknown = freedom.parameterIds.difference(parameterIds);
      if (unknown.isNotEmpty) {
        throw ParametricSolveConflict(
          'A degree of freedom references an unknown parameter.',
          blockingIds: unknown.toList(),
        );
      }
    }
    final adjacency = {
      for (final id in dofs.keys) id: <String>{id},
    };
    for (final dependency in request.dependencies.where(
      (item) => item.enabled,
    )) {
      for (final member in dependency.members) {
        adjacency
            .putIfAbsent(member, () => {member})
            .addAll(dependency.members);
      }
    }
    Set<String> group(String seed) {
      final result = <String>{}, queue = <String>[seed];
      while (queue.isNotEmpty) {
        final current = queue.removeLast();
        if (!result.add(current)) continue;
        queue.addAll(adjacency[current] ?? const <String>{});
      }
      return result;
    }

    final fixed = <String>{
      ...request.anchors,
      ...dofs.values.where((item) => item.fixed).map((item) => item.id),
    };
    final restrictions = request.restrictions
        .where((item) => item.enabled && item.blocking)
        .toList(growable: false);
    bool blocked(String id) =>
        fixed.contains(id) ||
        restrictions.any((item) => item.members.contains(id));
    final firstGroup = group(request.first),
        secondGroup = group(request.second);
    final firstFixed = firstGroup.any(blocked),
        secondFixed = secondGroup.any(blocked);
    if (firstFixed && secondFixed) {
      throw ParametricSolveConflict(
        'Both parametric references are anchored or restricted.',
        blockingIds: {
          ...firstGroup.where(blocked),
          ...secondGroup.where(blocked),
        }.toList(),
      );
    }
    final weights = {
      for (final priority in request.priorities)
        priority.referenceId: priority.weight,
    };
    double cost(Set<String> members) =>
        members.fold<double>(0, (total, id) => total + (weights[id] ?? 1));
    final anchor =
        request.preferredAnchor ??
        (firstFixed
            ? request.first
            : secondFixed
            ? request.second
            : cost(firstGroup) < cost(secondGroup)
            ? request.second
            : request.first);
    if (anchor != request.first && anchor != request.second) {
      throw const ParametricSolveConflict(
        'The selected anchor is not part of this parameter.',
      );
    }
    final moving = anchor == request.first ? request.second : request.first;
    final propagated = group(moving);
    final blockers = propagated.where(blocked).toList();
    if (blockers.isNotEmpty) {
      throw ParametricSolveConflict(
        'The requested parameter would move anchored references.',
        blockingIds: blockers,
      );
    }
    return ParametricMotionPlan(
      anchor: anchor,
      moving: moving,
      propagated: Set.unmodifiable(propagated),
    );
  }
}
