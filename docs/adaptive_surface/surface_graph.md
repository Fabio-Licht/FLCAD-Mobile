# Surface Graph e REKG

`ReverseEngineeringKnowledgeGraph` é o grafo transversal tipado da plataforma. Nós representam Mesh, Region, Reference, Sketch, Surface, Solid, FEL e AI; relações dirigidas registram origem e impacto.

O Surface Engine cria Mesh/Region/Reference/Sketch → Surface. O tipo Solid existe apenas como destino futuro. O grafo é persistido em `surface_graph.json`, reidratado após reinicialização e permite análise transitiva de impacto.
