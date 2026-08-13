# Technical Debt

## High

| Debt | Evidence | Required action |
|---|---|---|
| Circular module composition | Engineering Core imports strategic domains; FEL imports domains that import FEL | move registrations and command aggregation to app composition root |
| Serialization migration gap | mixed schema conventions, no migration registry | define schema catalog, typed version errors and golden migrations |
| Duplicate project stacks | `features/projects`, `features/home/projects`, `features/jobs` | designate canonical repository and migrate/remove legacy after compatibility window |
| Unmeasured production performance | no profile startup/heap/large-mesh suite | create device benchmark matrix and CI regression gates |

## Medium

| Debt | Evidence | Required action |
|---|---|---|
| Runtime duplication | 12+ isolate wrappers and multiple tokens | adapter-backed shared scheduler |
| Cache fragmentation | 13 caches, mostly unbounded and uninstrumented | shared capability contract, limits and metrics |
| Shared legacy geometry | many domains use Smart Regions `Vec3`/`MeshTopology` | migrate behind Geometric Kernel-compatible mesh contract |
| Plugin inconsistency | six registries, many domains without lifecycle | platform plugin descriptor and adapters |
| Large classes | 407-line solver, 316-line capture view, 305-line surface engine | split orchestration, algorithms and presentation |
| In-memory replay/history | buses and timelines have no retention policy | configurable bounds and persistent audit sink |

## Low

- String-based taxonomies and command names should become shared stable identifiers.
- Error types are often `StateError`/`UnsupportedError`; public APIs need domain error codes.
- Several serializers are encode-only foundations.
- Documentation is distributed by sprint and needs one generated index.

No debt was silently refactored during this review because the highest-value fixes cross public composition boundaries.
