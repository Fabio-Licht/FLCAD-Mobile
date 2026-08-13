# FEL AST

The AST includes Program, Command, Expression, Function Call, Variable Declaration, Pipeline, Loop, Condition, Return, Break, Continue, Region, Mesh and CAD nodes. Every node serializes to a platform-neutral map.

All execution passes through AST. Semantic analysis validates registered commands/functions and variable references. The optimizer currently removes provably redundant saves; future passes can batch independent operations and create parallel plans without changing source semantics.
