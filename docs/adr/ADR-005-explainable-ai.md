# ADR-005 — Explainable Engineering AI

- Status: Accepted
- Context: Engineering decisions affect manufacturability, inspection and reconstruction quality.
- Problem: Opaque labels cannot be audited or safely corrected.
- Alternatives: black-box scores; deterministic rules only; evidence-based hybrid reasoning.
- Decision: Every probabilistic conclusion carries confidence, evidence, provenance, alternatives and explanation.
- Consequences: larger models and conversion layers; user corrections can be recorded meaningfully.
- Future impact: ML providers must supply calibrated evidence metadata and cannot bypass validation.
