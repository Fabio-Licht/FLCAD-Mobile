# ShapeHandle

`ShapeHandle` is an immutable, serializable reference to a future CAD entity. It contains a persistent ID, kernel ID, entity type and optional metadata. Its constructor is private; handles are created through the validated reference factory or deserialization.

The handle deliberately contains no `TopoDS`, Parasolid pointer or memory-derived identity. A plugin resolves its own native object internally. Equality follows persistent identity plus kernel ownership, enabling storage, replay and cross-runtime transport without exposing vendor types.

