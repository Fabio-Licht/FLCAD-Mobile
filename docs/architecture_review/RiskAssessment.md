# Risk Assessment

| Risk | Likelihood | Impact | Evidence | Mitigation |
|---|---|---|---|---|
| Persisted project becomes unreadable after schema change | medium | critical | no migration registry/compatibility fixtures | schema catalog, migrations, backups and corruption tests |
| Memory growth in long sessions | medium | high | unbounded caches, replay lists, histories | retention limits, heap benchmarks, eviction policies |
| Package extraction blocked | high | medium | module import cycles | external composition root and command contributors |
| Isolate storm under concurrent analysis | medium | high | independent `Isolate.run`, no admission control | shared bounded scheduler |
| Incorrect engineering confidence interpreted as authority | medium | high | heuristic Alpha formulas | calibration datasets, UI uncertainty, provenance and human approval |
| Project deletion/data loss defect | low | critical | recursive deletion exists but path boundary is checked | backup/trash option, integration tests, audit log |
| Plugin compromises project/data | medium future | critical | no permissions/trust policy | signed manifests, sandboxing, capability permissions |
| Cloud conflicts corrupt Project First state | high if Cloud added now | critical | no sync/conflict model | versioned transactions and conflict protocol before Cloud |
| Mobile UI cannot expose strategic architecture | high | medium | only capture/Alpha reconstruction screens | Project Workspace product integration |
| Security/compliance gap | high for Enterprise | critical | no auth/RBAC/encryption/security review | dedicated security program before Enterprise claims |

## Residual risk

Functional correctness is well tested for current fixtures, but production geometry scale, corrupted data, device resource pressure and hostile inputs remain insufficiently evidenced.
