# Professional Reverse Engineering Workflow

Ω-001 turns the existing Project First engines into one guided experience. The canonical sequence is Project → STL → mesh analysis → quality → regions → references → sketches → surface plans → feature plans → CAD plan → export. CAD stages remain plans until a real kernel exists.

Business state lives in `core/professional_workflow`; Flutter observes immutable snapshots and invokes controller commands. Every artifact carries `projectId`.
