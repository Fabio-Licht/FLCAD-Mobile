# ADR-004 — Flutter test runner stabilization

## Status

Accepted — 2026-08-14.

## Context and root cause

The apparent test-suite hang occurred before project loading. Even `flutter --version` produced no output. The blocking code was the Flutter SDK bootstrap at `C:\flutter\bin\internal\shared.bat`, in the `:acquire_lock` and `:do_snapshot` flow. Its `git rev-parse HEAD` could not read the SDK repository under the sandbox identity because Git rejected its ownership as unsafe. A stale Flutter tool rebuild then held `flutter.bat.lock` while attempting `dart pub upgrade` in a network-restricted process.

No FLCAD import, singleton, bootstrap, timer, isolate, stream, receive port, zone, or test hook had executed when the wait occurred. This was proven by `flutter --version` exhibiting the same behavior and by process inspection showing only the Flutter tool snapshot/cache processes.

Separately, the first deterministic bisect found a normal assertion failure in `test/cad_kernel_foundation_test.dart:152`, caused by removal of the legacy `SHOW CAPABILITIES` FEL alias. It did not block discovery or completion and was corrected by retaining the alias.

## Decision

- OpenCascade registration remains side-effect free. The DLL loader is constructed only by explicit initialization or the first CAD operation.
- Studio inspection of an uninitialized kernel reports pending lazy loading without a health check.
- Test-runner diagnosis uses `tool/test_runner_diagnostics.ps1`, runs every file independently with `--machine`, and enforces a 30-second process timeout.
- CI and sandbox environments must mark their Flutter SDK checkout as a Git safe directory or run under the SDK owner. Flutter SDK cache repair must occur outside a network-restricted sandbox.
- The diagnostic markers are emitted by the diagnostic tool only; production imports remain silent and side-effect free.

## Consequences

Tests unrelated to CAD do not load OpenCascade. A missing native backend is observed only when explicitly initialized or used. Runner failures now distinguish SDK bootstrap failure, missing first protocol event, per-file timeout, assertion failure, and missing final `done` event.

## Root Cause: Duplicate Decision IDs

Engineering Decision previously derived identity from `DateTime.now().microsecondsSinceEpoch`. On Windows, the effective clock resolution can return the same value to sequential operations, so two distinct decisions could receive the same ID. `DecisionGraph.add()` would then overwrite the existing entry and attempt a self-edge, which the cycle detector correctly rejected.

Decision identity now uses the existing UUID-backed `IdGenerator`; `DateTime.now()` remains the decision timestamp and no longer participates in identity. `DecisionGraph.add()` also rejects duplicate IDs before any mutation. If a later graph connection fails, all decision, node, and edge mutations from that add operation are rolled back. Cycle detection and graph traversal remain unchanged.
