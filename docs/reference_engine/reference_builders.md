# Reference Builders

Um `ReferenceBuilder` transforma `ReferenceBuildContext + ReferenceRecipe` em `ReferenceBuildResult`. O contexto fornece mapas de malhas, regiões e referências; a receita contém `builderId`, parâmetros serializáveis e IDs de origem.

Builders disponíveis:

- `PlaneBuilder`: região/best fit, três pontos, offset, paralelo, perpendicular e plano médio; tangent/section reutilizam a infraestrutura geométrica Alpha.
- `AxisBuilder`: dois pontos, normal de plano e interseção de planos.
- `PointBuilder`: explícito, centroide e ponto sobre eixo.
- `CurveBuilder`: pontos explícitos e contorno discreto de região.
- `CoordinateSystemBuilder`: origem e eixos XYZ ortonormais.

Novos builders são registrados no engine, não na UI. Ajustes de cilindro/cone/esfera e curvas CAD devem entrar como plugins que cumpram o mesmo contrato.
