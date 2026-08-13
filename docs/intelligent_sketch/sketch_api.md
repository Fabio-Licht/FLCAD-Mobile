# Sketch API

`SketchApi` é o único acesso para criar, listar, editar, resolver, reconstruir, excluir, restaurar, versionar e obter sugestões. UI e módulos externos não acessam arquivos diretamente.

Persistência Project First:

- `Sketch/sketches.json`
- `Sketch/sketch_graph.json`
- `Sketch/sketch_history.json`
- `Sketch/constraints.json`
- `Sketch/Snapshots/*.json`

FEL oferece `CREATE SKETCH`, `CREATE CENTER`, `CREATE CIRCLE`, `APPLY CONSTRAINTS`, `CREATE PROFILE`, `PROJECT SURFACE` e `DELETE SKETCH`. Projeção em superfície exige plugin compatível.
