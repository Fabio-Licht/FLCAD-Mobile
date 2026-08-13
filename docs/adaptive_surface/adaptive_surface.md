# Adaptive Surface Domain

O ASD é um domínio Project First, independente de Flutter, para reconhecer, construir, refinar e validar superfícies. `AdaptiveSurface` reúne geometria, origem, vizinhança, DNA, intenção, manufatura, métricas, score, estágio progressivo e versão.

Todos os tipos FC-006 compartilham `SurfaceGeometry` e o registro de `SurfaceBuilder`. O Alpha implementa ajuste de plano, esfera e patch por pontos. Tipos procedurais possuem receitas/control points portáveis e sinalizam dependência de kernel posterior. Não há sólidos, booleanos, CAM ou CNC.

Superfícies Live são reconstruídas somente quando o fingerprint de origem muda. Estágios evoluem Alpha → Beta → Optimized → Production sem regressão implícita.
