# G-011D Bearing Certification

Run `tool/surface_fair_certification.dart` with the OpenCascade bridge, `bearing.stl`, and a project directory. It validates native selection, non-mutating preview, Reflection, Zebra, Validation, commit and rollback.

While native Fair is unavailable, the required commit result is `UnsupportedOperation: fairSurface`; the original persistent handle remains unchanged and fallbacks/approximations remain zero.
