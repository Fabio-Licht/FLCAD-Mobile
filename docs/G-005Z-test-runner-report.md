# G-005Z — Test Runner Stabilization Report

## Root cause

The runner was blocked before loading the FLCAD package. The exact wait was the Flutter SDK bootstrap lock in `C:\flutter\bin\internal\shared.bat`, under `:acquire_lock`. The SDK Git revision lookup in the same file failed under the sandbox account with `detected dubious ownership`; the resulting invalid tool stamp caused entry into `:do_snapshot`, which ran `dart pub upgrade` while holding `flutter.bat.lock`. Network restriction left that cache rebuild alive and every later Flutter invocation waited for the same lock.

Evidence:

- `flutter --version` blocked identically, excluding all application imports.
- The waiting processes were Flutter tool/cache Dart processes; no test process had started.
- No `--machine` protocol `start` event existed while the SDK lock was held.
- After repairing the Flutter tool cache under the SDK owner, the kernel test emitted `start` after 4,517 ms and completed successfully.

No library, singleton, timer, isolate, stream, receive port, zone, test hook, or FLCAD bootstrap was executing at the primary blocking point.

## Secondary nondeterminism found by bisect

The per-file bisect found two ordinary test failures, neither of which blocked discovery:

1. `test/cad_kernel_foundation_test.dart:152` expected the compatibility alias `SHOW CAPABILITIES`. The alias was restored alongside `SHOW KERNEL CAPABILITIES`.
2. `ProfessionalWorkflowController` used an asynchronous broadcast stream and fire-and-forget repository saves. Its test relied on a 50 ms delay. Notifications are now synchronous, pending saves are tracked, and `dispose()` waits for them with a five-second timeout. The regression passed 10 consecutive runs.

The reconstruction isolate also had an unbounded receive-port wait. `IsolateAlphaReconstructionBackend.run` now times out after 30 seconds and always cancels subscriptions, closes ports, and kills the isolate in `finally`.

## Import and runtime audit

- `AppBootstrap` and `EngineeringBootstrap` perform no work at import time.
- OpenCascade plugin registration does not call `DynamicLibrary.open`.
- Studio kernel inspection does not health-check an uninitialized backend.
- `EngineeringRuntime`, `DecisionRuntime`, `RecognitionRuntime`, and `SurfaceIntelligenceRuntime` create no workers until an explicit operation is submitted.
- Reconstruction receive ports and isolates are created only inside `run()`.
- No `setUpAll`, `tearDownAll`, import-time timer, import-time listener, or import-time isolate was found in the suite.

## Automated bisect summary

The diagnostic runner executes every `*_test.dart` independently with `--machine` and a 30-second process timeout.

| Group | Result |
|---|---|
| Core | OK |
| Workflow | OK |
| Recognition | OK |
| Decision | OK |
| Kernel | OK |
| Studio | OK |
| Reconstruction | OK |
| Surface | OK |
| Storage and repositories | OK |
| Blocking module | None |

## Final measurements

- Full `flutter test --machine`: first event at 2,786 ms; 927 events; terminal `done(success:true)`; 18,464 ms total.
- `dart analyze lib test`: no issues.
- Full `flutter test --coverage`: 244 tests passed; 22,153 ms test time; `coverage/lcov.info` generated.
- OpenCascade was not required by non-kernel tests.

Use `tool/test_runner_diagnostics.ps1` to repeat the per-file protocol instrumentation.
