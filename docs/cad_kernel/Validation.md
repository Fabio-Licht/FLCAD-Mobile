# OpenCascade Validation

Validation returns structured `GeometryDiagnostic` objects for invalid geometry, open shells, incorrect orientation, degenerate faces and invalid wires. Severity, code, message, shape identity and metadata are portable and contain no OCCT types.

The legacy validation contract is retained by formatting these diagnostics, preserving public compatibility.

The native runtime uses `BRepCheck_Analyzer` and never mutates the inspected shape.
