# ADR-082 — Suggest, Never Impose

Status: Accepted — permanent FLCAD rule

Whenever FLCAD can predict the operator's intention with useful confidence,
it should suggest that intention without taking control away from the operator.

An inference is transient presentation state. It may adjust the live preview
and the point confirmed by the operator, but it must not create a Constraint,
rewrite unrelated geometry, or persist as project truth.

Only one inference may be presented at a time. The highest-confidence candidate
wins and is represented by a small contextual glyph near the cursor. Dialogs,
status messages and modal confirmation are prohibited for inferencing.

The contract applies to all present and future drawing tools, including lines,
circles, arcs, rectangles, splines, ellipses, slots and projected curves.
