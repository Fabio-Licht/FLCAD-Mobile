# FEL Runtime

The execution chain is source, lexer, parser, AST, semantic analyzer, optimizer, incremental compiler and runtime. No command runs before semantic validation succeeds.

`FELExecutionContext` owns the Project identity, Smart Regions API, mesh adapters, active selection and variables. Effects are available only through `FELCommand`. Runtime checkpoints provide cooperative pause, resume and cancellation. Debug entries record line, command, duration, result and error.

History stores executed commands and undo closures. Replay recompiles stored FEL. Commands must implement compensating undo where the underlying module supports it.
