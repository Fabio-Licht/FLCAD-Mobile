# Sketch Engine

`SketchEngine` is the transactional aggregate for sketches and parametric entities. It coordinates history, five isolated graph views, selection, analytics, persistence, undo, redo, and rollback. It never initializes or calls a CAD kernel.
