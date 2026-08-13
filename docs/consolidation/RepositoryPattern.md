# Repository Pattern

`Repository<T, Id>` standardizes `findById`, `findAll`, `save` and `delete`; `VersionedRepository` adds history. `ProjectRepository` is the first migrated implementation. UI access remains mediated by managers/repositories. Every stored artifact must carry project ownership.
