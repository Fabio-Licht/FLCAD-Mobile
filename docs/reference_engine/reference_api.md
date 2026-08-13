# Reference API

`ReferenceApi` é a fachada pública para criar, listar, reconstruir, excluir, restaurar e validar referências. Nenhuma tela ou módulo consumidor deve acessar `ReferenceRepository` diretamente.

Exemplo conceitual:

```dart
final plane = await api.create(
  projectId: projectId,
  name: 'Base',
  mode: ReferenceMode.live,
  recipe: ReferenceRecipe('plane', {'method': 'bestFit'}, [region.id]),
  meshes: {mesh.id: mesh},
  regions: {region.id: region},
);
```

Persistência no projeto:

- `References/references.json`
- `References/reference_graph.json`
- `References/reference_history.json`
- `References/Snapshots/*.json`

FEL registra `FIT/CREATE PLANE`, `CREATE AXIS`, `CREATE POINT`, `CREATE CURVE`, `CREATE UCS` e `DELETE REFERENCE`. Comandos de ajuste de cilindro, cone e esfera permanecem tipados como extensões não instaladas até seus reconhecedores existirem.
