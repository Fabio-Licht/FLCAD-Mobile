# ADR-064 — AI Engineering Platform Certification

## Status

Accepted.

## Context

Sprints G-012A through G-012G form an integrated explainable engineering platform. A platform-level gate is required without introducing engineering behavior or automatic CAD actions.

## Decision

`AIPlatformCertificationEngine` audits a static, versioned manifest for the seven layers. Each module certificate must expose capabilities, evidence, justification, origin, score, discarded hypotheses and sprint traceability. The global dependency graph must be acyclic, contain no orphan or invalid node, and provide workspace, Property Inspector, persistence, analytics and ADR coverage for every module.

The engine executes 2,500 identical canonical projections and requires byte-identical JSON. Certification dates and coverage descriptions are caller inputs; no internal clock is permitted. Performance approval is based on deterministic capacity and serialized-size limits, never elapsed-time sampling. Approved results are emitted as `AIEngineeringPlatformCertificate.json`, with a separate Project First architecture audit.

## Approval criteria

Approval requires seven passing module certificates, 2,500 deterministic pipelines, complete and acyclic integration, explainability evidence, generated coverage, clean static analysis and test suite, `git diff --check`, a release APK, no external context, no automatic decision or command, and no geometry mutation.

## Mandatory exclusions

The certification layer contains no engineering solver, CAD operation, ML, LLM, generative AI, fallback, STL parser, timer, isolate or automatic worker.

## Consequences

Certification is reproducible and auditable. A rejected result cannot be emitted as an official certificate. Platform evolution requires updating both the architecture manifest and its evidence.
