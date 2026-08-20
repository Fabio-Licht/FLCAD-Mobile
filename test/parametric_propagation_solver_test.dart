import 'package:flcad_mobile/core/parametric_solver/parametric_solver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const solver = ParametricPropagationSolver();

  test('consumes an abstract contract and selects the lowest-cost group', () {
    final plan = solver.solve(
      const ParametricSolveRequest(
        first: 'feature:a',
        second: 'feature:b',
        degreesOfFreedom: [
          ParametricDegreeOfFreedom('feature:a', parameterIds: {'length'}),
          ParametricDegreeOfFreedom('feature:b'),
          ParametricDegreeOfFreedom('dependent:c'),
        ],
        parameters: [ParametricParameter('length', 40)],
        dependencies: [
          ParametricDependency('dependency', {'feature:b', 'dependent:c'}),
        ],
        priorities: [ParametricPriority('feature:a', 0.5)],
      ),
    );

    expect(plan.anchor, 'feature:b');
    expect(plan.moving, 'feature:a');
    expect(plan.propagated, {'feature:a'});
  });

  test(
    'anchors and restrictions govern conflicts without entity semantics',
    () {
      final plan = solver.solve(
        const ParametricSolveRequest(
          first: 'reference:axis',
          second: 'reference:profile',
          degreesOfFreedom: [
            ParametricDegreeOfFreedom('reference:axis'),
            ParametricDegreeOfFreedom('reference:profile'),
          ],
          anchors: {'reference:axis'},
        ),
      );
      expect(plan.anchor, 'reference:axis');
      expect(plan.moving, 'reference:profile');

      expect(
        () => solver.solve(
          const ParametricSolveRequest(
            first: 'reference:outer',
            second: 'reference:inner',
            degreesOfFreedom: [
              ParametricDegreeOfFreedom('reference:outer'),
              ParametricDegreeOfFreedom('reference:inner'),
            ],
            restrictions: [
              ParametricRestriction('locked', {
                'reference:outer',
                'reference:inner',
              }, blocking: true),
            ],
          ),
        ),
        throwsA(isA<ParametricSolveConflict>()),
      );
    },
  );
}
