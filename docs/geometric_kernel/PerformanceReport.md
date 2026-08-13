# Performance Report

G-002 supplies `GeometryBenchmark` for repeatable microbenchmarks and operation metrics for production telemetry. The Alpha baseline favors correctness and bounded allocation. Spatial queries currently use an exact linear baseline, documented as such; optimized trees must demonstrate identical query semantics before replacement.

Performance acceptance should be recorded per device and dataset rather than asserted from development-host timings.
