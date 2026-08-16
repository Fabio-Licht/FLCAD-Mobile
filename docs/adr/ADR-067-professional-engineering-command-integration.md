# ADR-067 — Professional Engineering Command Integration

## Status

Accepted with explicit B-001E capability boundaries.

## Decision

Desktop actions are routed through `CommandDispatcher`, validated against an immutable `CommandContext`, resolved by `CommandRegistry`, and executed by `CommandManager`. Every successful execution enters the undo stack, clears redo, updates observable state, and records an audit entry under the active project's `CAD` directory.

The runtime is passive. It contains no timers, polling, isolates, workers, or parallel command execution. Timestamp and duration are injected values; the default duration is zero because internal timing is prohibited.

## Flow

UI event → validation → dispatcher → manager → registered adapter → certified module/kernel → observable workspace state → Explorer/Viewport/Inspector/Assistant rebuild.

The same dispatcher is used by the file menu, dashboard import actions, workspace module navigation, selection, and undo/redo controls. Import/export delegates exclusively to B-001C.

## History and reversal

Successful operations append JSON Lines records to:

- `CAD/CommandHistory/history.jsonl`
- `CAD/UndoHistory/history.jsonl`
- `CAD/RedoHistory/history.jsonl`

Records contain timestamp, module, parameters, result, duration and operation. Undo/redo invoke explicit command adapters; they never mutate widgets directly. Export cannot reliably delete a user-controlled external file, so its undo is an auditable logical reversal only.

## Integration boundaries

Opening the certified AI workspaces is functional and consultative. Import/export supported by B-001C is functional. Modeling commands requiring geometric selection, parameter editors, previews or approval dialogs—reference creation, recognition fitting and Surface Operations—are not activated by this ADR because their complete interaction contract belongs to B-001E Professional Modeling UI. No temporary geometry command or alternate algorithm is introduced.

OBJ/PLY and mesh-to-BRep limits remain those documented in ADR-066.
