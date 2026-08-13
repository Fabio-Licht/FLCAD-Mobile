# Intelligent Sketch Domain

O FC-005 transforma Sketch em uma entidade de engenharia contextual. Um `IntelligentSketch` reúne contextos geométricos, entidades, constraints, DNA, analytics, intenção, versão e histórico. Ele não importa Flutter e compartilha o mesmo JSON entre Mobile, Desktop e Cloud.

O Hybrid Sketch Engine representa cada ponto como `SketchAnchor`: posição 3D, contexto, coordenadas paramétricas opcionais e índice de primitiva. Assim, uma curva pode atravessar malha, região, plano e futuras superfícies sem projeção posterior obrigatória.

Sketches e entidades podem ser Static ou Live. O engine reconstrói somente Sketches Live quando fingerprints contextuais mudam. Surface/NURBS/Torus, sólidos, CAM e modelagem paramétrica completa são contratos nesta versão, não implementações simuladas.
