# Hybrid Surface Engine

`core/hybrid_surface_engine` combines analytical, transition and freeform surface plans into one explainable reconstruction network. It consumes `SurfacePlan` data and produces no geometry, kernel request or B-Rep entity.

The engine coordinates network construction, compatible region grouping, continuity optimization, complete strategy comparison, patch planning, quality prediction and the deferred reconstruction DAG.

