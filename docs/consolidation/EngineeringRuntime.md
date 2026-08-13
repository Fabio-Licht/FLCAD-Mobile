# Engineering Runtime 2.0

`EngineeringRuntime` is the single scheduling boundary for CPU work. It provides a bounded worker pool, priority queue, namespace cancellation, global pause/resume, progress callbacks and execution metrics. All isolate-based domain runtimes delegate to it while preserving their public facades.

Cancellation is cooperative: queued work is removed immediately; running isolate work completes but its result is rejected. Task IDs must be unique while active.
