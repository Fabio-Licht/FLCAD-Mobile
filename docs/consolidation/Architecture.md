# Consolidated Architecture

```text
Flutter UI
   |
AppBootstrap (composition root)
   |
EngineeringContext / service contracts
   +-- Runtime 2.0 ---- domain compatibility runtimes
   +-- Cache ---------- namespaced domain data
   +-- CQRS/Event Bus - commands, queries, audit
   +-- Schema Registry / Migration Engine
   +-- Repository / Plugin / Service contracts
   |
Project Manifest -> all project-owned artifacts
```

Dependency direction is UI → bootstrap → core contracts. Domain engines do not
own application startup. Compatibility factories that still compose concrete
services are deprecated migration surfaces and not the target dependency model.
