# Runtime

Planning can run in a Dart isolate with cooperative cancellation before and after computation. The scheduler remains stateful on the controlling isolate. CPU-intensive future enrichers connect through plugins without changing workflow semantics.
