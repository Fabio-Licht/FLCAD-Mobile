# Region Graph

`RegionGraph` representa regiões e derivados de engenharia: planos, eixos, curvas, sketches, superfícies e fillets. Arestas registram dependência, vizinhança e fronteira compartilhada. `dependentsOf` permite invalidar a árvore quando uma região muda, sem modificar a malha.

O grafo é persistido em `region_graph.json` e pode ser sincronizado por providers de Cloud/Desktop.
