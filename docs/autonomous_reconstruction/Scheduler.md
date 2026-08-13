# Scheduler

The scheduler exposes only stages whose dependencies are complete. It supports priority ordering, parallel groups, pause, resume, cancellation, failure propagation and restart from persisted workflow state. CAD geometry stage execution throws an explicit unsupported error in 0.9.0.
