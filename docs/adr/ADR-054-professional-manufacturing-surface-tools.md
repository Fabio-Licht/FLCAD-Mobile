# ADR-054 — Professional Manufacturing Surface Tools

## Status

Accepted.

## Decision

Professional Manufacturing is a Project First transactional orchestration layer over Surface Operations → GeometryKernelAPI → OpenCascade 8.0.1 → Live Reconstruction. It introduces persisted `ManufacturingIntent` for later CAM and G-012 consumers.

Draft and quality reuse Surface Continuity analysis; protected regions reuse Boundary contracts; Punch/Die Extension, Offset, Blend and Transition record their certified suite dependencies. All commits still use the single official operation `manufacturingSurface`, preventing parallel geometry logic.

Draft Analysis, Manufacturing Analyzer, Preview and Advisor are non-mutating. Springback Compensation is infrastructure-only. Without native support, commit returns exactly `UnsupportedOperation: manufacturingSurface`, preserving geometry, handles, preview, validation, advisor, history and workflow. Simulated geometry, approximations, fallbacks and parallel processing are forbidden. Runtime bootstrap is passive and lazy.
