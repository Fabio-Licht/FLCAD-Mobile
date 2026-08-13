# ADR-008 — Engineering Cognition

- Status: Accepted
- Context: AREI observes and DNA knows, but product workflows need practical feature and intent perception.
- Problem: Users otherwise manually translate probabilities into modeling decisions.
- Alternatives: place recognition in AREI; place rules in UI; compose a cognition layer.
- Decision: Engineering Cognition combines AREI evidence and DNA rules into features, functions and recommendations.
- Consequences: clear separation from execution; some taxonomy mapping remains string-based.
- Future impact: UI and external models should consume the stable cognition snapshot and graph.
