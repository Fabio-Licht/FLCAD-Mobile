# ADR-004 — Decoupled CAD Kernel

- Status: Accepted
- Context: Mobile, Desktop and Cloud may require different geometric/CAD backends.
- Problem: Binding domain intent directly to OpenCascade, Parasolid or another kernel would constrain portability and licensing.
- Alternatives: vendor kernel throughout; proprietary B-Rep now; mathematical foundation plus adapters.
- Decision: Keep Geometric Kernel mathematical and define future CAD adapter contracts separately.
- Consequences: no real B-Rep/booleans today; algorithms and intent remain portable.
- Future impact: a production adapter must map topology, tolerances, errors and ownership without leaking vendor types.
