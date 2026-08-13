# ADR-016: Build Engineering Studio as a state-driven Desktop shell

Status: Accepted

## Decision

Place reusable Studio state/managers in `core/engineering_studio` and keep Flutter as an observer. Persist layouts inside each Project. GPU rendering, lasso and native windows are injected capabilities, never assumed platform behavior.

## Consequences

Desktop gains a professional multi-panel shell without coupling engineering engines to widgets. Mobile behavior remains unchanged. Future GPU and CAD kernels can attach through explicit contracts without replacing layout, tree, selection, commands or persistence.
