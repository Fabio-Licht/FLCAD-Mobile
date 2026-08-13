# Engineering Runtime

`EngineeringRuntime` owns background tasks, isolate execution, task IDs and cooperative cancellation tokens. Domain runtimes remain compatibility adapters until migrated. Runtime metrics should record elapsed time, active tasks and cancellation counts through `EngineeringMetrics`.

Closures submitted to isolates must contain sendable data. GPU, Cloud and kernel processing remain service adapters.
