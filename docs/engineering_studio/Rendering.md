# Render Pipeline

Layers cover mesh, references, sketches, regions, planned surfaces/features, decision and workflow overlays. `StudioRenderBackend` is the GPU boundary. No renderer is simulated: without a backend, render requests throw `UnsupportedError`. Frame metrics include draw calls, triangles and elapsed time.
