# ADR-040 — Professional Reverse Engineering Session Manager

## Status

Accepted.

## Decision

Every reverse-engineering activity is represented by a Project First session aggregate. Its serializable context owns workflow, workspace, UI, selection, active engineering objects, validation, timeline, advisor, analytics and undo/redo state. Snapshots and recovery states are deep immutable captures. Restore replaces the complete context; replay returns journal evidence and never dispatches CAD operations.

The bootstrap registers passive services only. Geometry remains behind Workflow → GeometryKernelAPI → adapter → OpenCascade and is never invoked by session lifecycle, snapshot, recovery or replay.
