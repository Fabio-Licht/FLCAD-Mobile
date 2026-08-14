# Incremental Solver

Every constraint change marks the constraint dirty and propagates that state through the dependency graph. A solve drains only requested or dirty work, ordered by priority. Constraint groups provide organizational subsets, while explicit `only` IDs provide partial execution.
