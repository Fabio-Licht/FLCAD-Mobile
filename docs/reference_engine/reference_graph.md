# Reference Graph

`ReferenceGraph` é um grafo dirigido versionável. Uma aresta `source -> reference` significa que a referência deriva da origem. A origem pode ser Smart Region, outra referência ou, futuramente, Sketch/Surface.

O grafo oferece dependências, objetos derivados, ordenação topológica e detecção de ciclos. Toda criação registra as origens da `ReferenceRecipe`; consumidores devem consultar o grafo para invalidar ou reconstruir descendentes. O formato persistido é `reference_graph.json` e não contém objetos de UI.

Dependências entre referências devem ser acíclicas. Adaptadores futuros podem acrescentar tipos de aresta, preservando IDs universais e a direção causal.
