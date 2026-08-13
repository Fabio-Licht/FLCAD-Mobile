# Mesh Sketch

`MeshSketchAdapter` implementa o contrato neutro de geometria para malhas. O Alpha fornece fingerprint e projeção determinística no vértice mais próximo. Entidades continuam armazenadas em coordenadas 3D e ligadas ao contexto Mesh.

Smart Regions entram pelo `SketchContextFactory`, preservando o DNA da região. Pincel, trim, extend, mirror e offsets avançados devem ser ferramentas consumidoras de entidades e constraints; não pertencem à camada de persistência.
