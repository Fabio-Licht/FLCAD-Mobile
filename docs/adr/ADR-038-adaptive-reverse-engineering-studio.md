# ADR-038 — Adaptive Reverse Engineering Studio

## Decision

The `adaptive_studio` domain composes existing modules into contextual layouts. Adaptation is reactive to an explicitly supplied workflow state; no polling, timer, worker, kernel call or domain execution occurs. Context layouts are temporary while user docking and saved memories remain explicit project preferences.

Quick Actions reference Engineering Intelligence recommendations and FEL commands but never execute them. Notifications are non-modal. Project First persists workspace, layout, dashboard, docking, navigation, analytics and memory independently.

## Consequences

The Studio can reduce cognitive load through progressive disclosure while preserving a Show All mode, six focus modes and restorable multi-monitor-ready layouts without coupling UI composition to engineering side effects.
