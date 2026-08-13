# Sketch Graph

`SketchGraph` armazena relações causais entre regiões, referências, superfícies, Sketches e futuros features. Na criação, cada contexto origina uma aresta `context`. O grafo oferece dependentes transitivos e remoção segura, sendo reidratado de `sketch_graph.json` após reinicialização.

IDs e relações são independentes da UI. Extensões CAD e Surface devem adicionar arestas dirigidas sem inserir seus objetos no domínio de Sketch.
