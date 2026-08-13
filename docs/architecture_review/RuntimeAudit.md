# Runtime Audit

## Inventory

Twelve runtime/background implementations call `Isolate.run`: Engineering, Geometric Kernel scheduler, Knowledge, Cognition, AREI, Reference, Sketch, Surface, Topology, Parametric Engineering, Smart Regions background operations and the AI heuristic plugin. Autonomous Reconstruction adds another isolate planning runtime.

## Common behavior

- execute a sendable closure in an isolate;
- optionally inspect cancellation before/after execution;
- return one typed result;
- no bounded queue, admission control or shared worker pool.

## Material differences

- `EngineeringRuntime` tracks active tasks by ID.
- Geometric Kernel records operation metrics and accepts sync/async computation.
- Reference, Sketch, Surface, Topology and Parametric runtimes expose domain-specific methods with no cancellation.
- Knowledge, Cognition, AREI and Autonomous runtimes duplicate local boolean cancellation tokens.

## Risks

Repeated isolate startup can dominate small jobs. Cancellation is cooperative and does not terminate work already running inside `Isolate.run`. There is no concurrency ceiling, pause contract, priority queue or memory-pressure feedback.

## Consolidation decision

Do not replace public runtime interfaces in AR-001. Introduce, in a later compatibility release, an adapter-backed `EngineeringTaskScheduler` with task ID, priority, cancellation, metrics and concurrency policy. Existing `*Runtime` types should delegate to it while retaining signatures. Domain algorithms must remain unaware of isolate mechanics.
