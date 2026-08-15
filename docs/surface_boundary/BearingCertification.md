# G-011E Bearing Certification

Run `tool/surface_boundary_certification.dart` with the OpenCascade bridge, `bearing.stl`, and a project directory. It validates native boundary selection, non-mutating preview, Boundary Analyzer, validation, commit and rollback.

While native boundary editing is unavailable, the required result is `UnsupportedOperation: editBoundary`; the original persistent handle remains unchanged and fallbacks/approximations remain zero.
