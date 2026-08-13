# Surface Runtime

Persistência Project First:

- `Surfaces/surfaces.json`
- `Surfaces/surface_graph.json`
- `Surfaces/surface_history.json`
- `Surfaces/surface_network.json`
- `Surfaces/Snapshots/*.json`

`SurfaceApi` é a fachada única. Cache usa fingerprint das fontes. Eventos cobrem criação, atualização, remoção, rebuild, refine, validation, repair, optimization e recognition. Decisões seguem para um learning sink injetável; o padrão é no-op.
