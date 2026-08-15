# G-011F Bearing Certification

Run `tool/surface_manufacturing_certification.dart` with the OpenCascade bridge, `bearing.stl`, and a project directory. It validates real selection, preview, Draft Analysis, Manufacturing Analyzer, validation, commit and rollback.

Without native manufacturing operations, the required result is `UnsupportedOperation: manufacturingSurface`; the original handle remains unchanged and fallbacks/approximations remain zero.
