# Architecture

`RevolveApi` delegates authoring to `RevolveEngine`. The engine coordinates profile recognition and the feature platform. Only `RevolveFeatureKernelAdapter` may request geometry from `GeometryKernelAPI`.
