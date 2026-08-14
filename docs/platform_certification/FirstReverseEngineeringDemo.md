# First Reverse Engineering Demo

Candidate part: OpenCascade 8.0.1 `data/stl/bearing.stl` (6,544,455 bytes).

Result: **BLOCKED** before `Open STL`. The repository contains no official STL importer; `GeometryKernelAPI` interchange supports STEP, IGES and BREP only. Treating file presence or a test fixture as an import would violate the no-simulation requirement. No certification was issued.

Required resolution: implement or connect an official Project First STL mesh importer, then execute every stage through the existing domain APIs and persist the resulting session and report.
