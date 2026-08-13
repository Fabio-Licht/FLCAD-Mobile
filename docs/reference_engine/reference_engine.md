# Reference Engine 2.0

O Reference Engine é o núcleo geométrico compartilhado do FLCAD. Operações consumidoras recebem `ReferenceEntity`; não dependem diretamente de malhas. Cada entidade possui geometria, receita reproduzível, DNA, analytics, modo Static/Live, versão e dependências.

O fluxo é Project First: os arquivos ficam em `Project/References`. O `ReferenceEngine` coordena builders, cache, grafo, histórico e eventos; `ReferenceApi` é a única fachada pública. A geometria de entrada é injetada no contexto, permitindo uso igual em Mobile, Desktop e Cloud.

Implementado no Alpha: planos, eixos, pontos, curvas discretas e sistemas de coordenadas. Reconhecimento de planos e centroides por Smart Region também está disponível. Cilindros, cones, esferas, GPU, IA e sincronização possuem contratos, mas não algoritmos produtivos nesta fase. Superfícies, Sketch, sólidos e CAM estão fora do escopo.

O Adaptive Reference System compara DNA, confiança e erro de referências candidatas para decidir entre preservar, reconstruir ou sugerir substituição. Uma referência Live é reconstruída quando sua origem muda; uma Static permanece imutável.
