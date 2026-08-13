# Application Bootstrap

`app/bootstrap` is the composition root. `AppBootstrap` coordinates application startup and `EngineeringBootstrap` wires engines, runtime, cache, schemas and plugins. Engineering Core owns contracts and orchestration primitives; concrete cross-domain construction belongs here. `EngineeringContext.standard` remains a compatibility facade.
