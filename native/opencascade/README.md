# FLCAD OpenCascade native host

Configure with `OpenCASCADE_DIR` pointing to an OCCT CMake package, then build and install `flcad_opencascade`. The library exposes only the stable C ABI in `include/flcad_occ_api.h`; no OCCT type crosses into Dart.

This workspace intentionally does not vendor OCCT. Configuration fails explicitly when the SDK is absent.
