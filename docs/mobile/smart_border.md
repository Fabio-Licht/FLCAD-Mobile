# Smart Border Engine

O engine implementa Expand, Shrink, Smooth, Relax e Preserve sobre adjacência de triângulos. As operações retornam uma nova `TriangleSelection`; a entrada e a malha permanecem intactas. Regras e comandos podem aplicar operações manualmente, automaticamente ou por recomendação de IA.

Valores em milímetros exigem escala de malha e adapter métrico futuro. O Alpha opera por anéis topológicos, sem fingir equivalência física.
