# G-009E Platform Certification Report

## Result

**BLOCKED — certification not issued.**

## Verified

- Static analysis: clean.
- Complete Flutter regression and coverage: 385 tests passed.
- Windows Release build: successful.
- Native backend loaded explicitly from the Release bundle.
- OpenCascade version: 8.0.1.
- Native health: healthy, zero live shapes before the demonstration.
- Capabilities: BREP, Boolean, Healing, IGES, Meshing, NURBS, STEP, Solid and Surface.
- Bootstrap remains passive; native loading occurred only through the explicit certification tool.

## Build corrections

1. Replaced an invalid cross-directory `POST_BUILD` command with a dedicated copy target.
2. Removed a redundant native install rule that used the runner's generator-expression install prefix literally.
3. Copied OCCT runtime DLLs based on the cache-visible runtime list.
4. Excluded Debug third-party binaries from Release bundles.
5. Added the seven transitively required runtime libraries identified from PE dependency tables.

## Blocking finding

The real candidate part is OpenCascade's `bearing.stl` (6,544,455 bytes). The repository has no official STL import API. `KernelExchangeFormat` exposes only STEP, IGES and BREP, and `flcad_occ_import_shape` implements those same paths. Therefore the mandatory first step, `Open STL`, cannot be completed through the official architecture.

Using file presence, a no-op callback, a fixture or BREP fallback as proof of STL import would be simulated evidence and is explicitly rejected by the certification engine.

## Required action before certification

Connect a real Project First STL mesh importer to the workflow, then execute all sixteen demonstration stages through their official APIs. Until that is done, G-010 readiness remains blocked despite the healthy OpenCascade backend.
