# Surface Recognition

`SurfaceRecognitionApi.run(mesh)` is the sole entry point. It lazily inspects the native mesh, segments connected triangles, classifies every region, evaluates confidence, updates official projections and persists no CAD geometry. The `bearing.stl` certification is reproduced with `tool/surface_recognition_certification.dart`.
