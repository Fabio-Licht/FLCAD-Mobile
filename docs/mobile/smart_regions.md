# Smart Regions Engine 2.0

Smart Regions são objetos imutáveis e versionados que referenciam índices de triângulos de uma `MeshTopology`. Vértices e triângulos nunca são copiados, alterados ou destruídos. A API pública é `SmartRegionsApi`; consumidores Mobile, Desktop, Cloud, IA e CAD não devem manipular a malha diretamente.

Seleções são serializadas como intervalos compactos. Soft Regions armazenam somente pesos esparsos. Live Regions preservam uma expressão de filtro e são reavaliadas quando a malha muda. Layers e grupos são metadados independentes, com hierarquia ilimitada por `parentId`.

O workspace Project First fica em `SmartRegions/`, com JSON versionado, snapshots e histórico. Operações pesadas podem usar `BackgroundRegionExecutor`; integrações GPU implementam contratos próprios e devem manter fallback CPU.

A meta de 100 milhões de triângulos orienta adapters nativos, streaming e representações compactas. A implementação Dart Alpha não declara esse volume como validado.
