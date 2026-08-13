# Surface Runtime

`SurfaceGenerationRuntime` delegates operations to Kernel Runtime and Engineering Runtime. Native kernel state remains on the main runtime queue because native handles cannot cross Dart isolate boundaries safely. Cancellation and scheduling remain owned by Engineering Runtime.

