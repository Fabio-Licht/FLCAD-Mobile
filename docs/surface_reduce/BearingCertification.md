# G-011C Bearing Certification

Run `tool/surface_reduce_certification.dart` with the OpenCascade bridge, `bearing.stl`, and a project output directory. It verifies real native selection, non-mutating preview, constraints, validation, commit and rollback.

While native Reduce is unavailable, the required result is `UnsupportedOperation: reduceSurface`; the original persistent surface ID remains unchanged and fallbacks/approximations remain zero.
