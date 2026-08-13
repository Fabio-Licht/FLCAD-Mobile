# Import and Export

The interchange API supports STEP (`.step`, `.stp`), IGES (`.iges`, `.igs`) and BREP (`.brep`). Import returns an opaque handle. Export resolves that handle internally to the native OCCT token.

Operations accept cancellation and progress contracts, run through Kernel Runtime and record analytics. A missing native host, unknown handle or unsupported format is an explicit failure.

