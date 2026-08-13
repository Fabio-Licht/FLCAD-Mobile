# Performance Audit

## Measured in this audit environment

- Full `flutter test --coverage`: two audit runs exited 0 in 21.3 and 16.7 seconds wall-clock; Flutter reported approximately 13 and 9 seconds of test execution respectively. This variation reinforces the need for controlled benchmark runs.
- 133 tests passed in that run.
- Line coverage before AR-001 reporting: 6,455 of 9,245 instrumented lines, 69.82%.
- The storage suite writes and reloads 200 sequential captures successfully.

These figures describe a Windows development host and synthetic test fixtures. They are not mobile-device service-level objectives.

## Not measured

No profile-mode harness currently records cold/warm startup, frame timing, resident set size, Dart heap, allocation rate, isolate peak count, serialization throughput, event fan-out latency or large-mesh behavior. Claims for those dimensions would be speculative.

## Static observations

- App startup awaits `AIBootstrap.initialize` and `ProjectManager.initialize` sequentially before the first product screen.
- Gallery widgets construct `File`-backed images; thumbnail decoding/cache bounds are not explicitly controlled in the reviewed code.
- Domain caches are unbounded in memory unless their owner explicitly invalidates them.
- Each `Isolate.run` may create scheduling/startup overhead; no shared pool or concurrency limit exists.
- Project listing reads every project JSON and derives disk statistics, which scales linearly with project and file count.
- Event buses retain replay/history in memory without configured limits.

## Required Professional 1.0 benchmarks

1. Profile-mode cold and warm startup on low/mid/high Android devices.
2. 200/500/1,000-image capture sessions with heap and frame-time traces.
3. 100k/1M triangle observation, cognition and planning datasets.
4. JSON size/encode/decode throughput for every persisted schema.
5. Event fan-out with 1/10/100 subscribers and bounded replay.
6. Cache growth, eviction and hit-rate tests over an eight-hour session.

## Performance gate proposal

Define device-specific budgets only after baseline measurement. CI should detect regression percentages, not invent absolute thresholds from this desktop audit.
