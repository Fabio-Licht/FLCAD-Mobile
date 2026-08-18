# G-109 — Auditoria técnica da Categoria B (OCCT 8.0.1)

Status: **AUDITORIA — SEM IMPLEMENTAÇÃO**  
Data: 2026-08-17  
SDK auditado: `opencascade-8.0.1-vc14-64`  

## Limites desta auditoria

- A Categoria A permanece congelada e na fila de QA.
- Nenhum contrato, bridge, operador, controller ou componente de interface foi alterado.
- A Categoria C (`Fair Surface` e `Morph Surface`) não foi auditada.
- “Operador oficial” significa uma API pública do OCCT que entrega a semântica completa do comando. Classes de apoio não são tratadas como um comando pronto.
- Toda futura operação deverá manter `Preview`, `Apply` e `Cancel`; somente o resultado aceito poderá ser materializado no `CadDocument` como `ShapeHandle` oficial.

## Evidência de versão

O SDK local usado pelo projeto contém, em seus headers 8.0.1, as classes e métodos citados neste documento: `GeomPlate_CurveConstraint`, `GeomPlate_BuildPlateSurface`, `GeomPlate_MakeApprox`, `BRepFilletAPI_MakeFillet`, `BRepOffsetAPI_MakeOffsetShape::PerformByJoin`, `BRepOffsetAPI_MakeThickSolid::MakeThickSolidByJoin`, `GeomLib::ExtendCurveToPoint`, `GeomLib::ExtendSurfByLength`, `BRepAlgoAPI_Splitter` e `BRepBuilderAPI_Sewing`.

## Resumo executivo

| Ferramenta | Operador completo no OCCT 8.0.1? | Composição oficial? | Algoritmo proprietário necessário? | Estratégia aprovada para implementação futura |
|---|---|---|---|---|
| Match Surface | Não | Sim | Não | `GeomPlate` + aproximação BSpline + reconstrução topológica |
| Blend Surface | Sim, apenas para arestas de topologia compartilhada | Sim, para faces desconectadas | Não no escopo comprovado | `BRepFilletAPI_MakeFillet` no caso compartilhado; composição `ChFi3d`/`BRepBlend` somente para o caso geral |
| Offset + Walls | Sim para thick solid compatível | Sim para Face/Shell aberto | Não | `MakeThickSolidByJoin`; caso aberto: offset + paredes oficiais + sewing |
| Boundary Extend | Não | Sim | Não | extensão geométrica oficial + interseção/alvo + reconstrução da Face |
| Boundary Trim | Sim para o corte topológico; não como comando UX completo | Sim | Não | `BRepAlgoAPI_Splitter` ou trim paramétrico + seleção do domínio + validação |

Conclusão: **nenhum algoritmo geométrico proprietário do FLCAD é autorizado ou necessário nesta etapa**. Os cinco comandos podem ser implementados por operadores oficiais ou por composição explícita de operadores oficiais. O Blend geral entre superfícies desconectadas é o único caso de maior risco; uma eventual lacuna somente poderá ser declarada depois de implementar e medir a composição oficial, nunca antecipadamente.

## 1. Match Surface

### Respostas obrigatórias

- **Existe operador oficial?** Não existe um comando público único “Match Surface”.
- **Exige composição?** Sim.
- **Exige algoritmo proprietário?** Não.
- **Classes oficiais:** `GeomPlate_CurveConstraint`, `GeomPlate_BuildPlateSurface`, `GeomPlate_MakeApprox`, adaptadores de curva sobre superfície e builders BRep de Edge/Wire/Face.
- **Limitações conhecidas:** G1 e G2 exigem uma curva associada à superfície de suporte; G0 usa tolerância de distância, G1 tolerância angular e G2 tolerância de curvatura. A quantidade de pontos de restrição afeta fortemente o custo. O resultado de `GeomPlate` é uma superfície de plate, não a Face final persistível.
- **Alternativa oficial:** para reconstrução de uma face delimitada sem a semântica de “mover uma superfície para casar com outra”, `BRepOffsetAPI_MakeFilling` pode impor restrições de contorno; não é substituto genérico de Match.

### Estratégia futura

1. Resolver Face/Surface móvel, Boundary alvo e superfícies de suporte.
2. Construir `GeomPlate_CurveConstraint` com ordem 0, 1 ou 2.
3. Resolver com `GeomPlate_BuildPlateSurface`.
4. Verificar `G0Error`, `G1Error` e `G2Error` contra as tolerâncias solicitadas.
5. Aproximar com `GeomPlate_MakeApprox` para `Geom_BSplineSurface`.
6. Reaplicar o Wire oficial, construir a Face, validar e apenas então produzir o `ShapeHandle` de preview.

O OCCT documenta explicitamente as ordens G0/G1/G2 e seus critérios de distância, ângulo e curvatura em `GeomPlate_CurveConstraint`.

## 2. Blend Surface

### Respostas obrigatórias

- **Existe operador oficial?** Sim para fillet/blend sobre arestas quebradas pertencentes a um Shell ou Solid: `BRepFilletAPI_MakeFillet`.
- **Exige composição?** Não no caso de duas faces adjacentes que compartilham a Edge selecionada. Sim no caso geral de Faces/Surfaces/Boundaries desconectadas.
- **Exige algoritmo proprietário?** Não para o escopo suportado. Não fica autorizado um fallback proprietário para o caso geral.
- **Classes oficiais:** `BRepFilletAPI_MakeFillet`; em nível inferior, pacotes `ChFi3d`, `BRepBlend` e `BRepBlend_AppSurface`; leis de raio por `Law_Function` quando aplicável.
- **Limitações conhecidas:** o operador de alto nível requer topologia compartilhada válida; raio excessivo, arestas curtas, singularidades, auto-interseções e cadeias tangenciais ambíguas podem impedir a construção. `SetContinuity` controla a continuidade interna C0/C1/C2 da superfície de fillet e a tolerância G1 com as faces de suporte; isso não equivale a prometer G2 externo em qualquer entrada.
- **Alternativa oficial:** para uma transição por contornos entre faces desconectadas, usar a família `GeomPlate`/filling como construção restrita, mas apresentá-la como Blend somente se os critérios geométricos e topológicos do comando forem satisfeitos e medidos.

### Estratégia futura

- **Rota primária:** detectar Edge compartilhada em Shell/Solid, configurar raio constante ou lei, executar `BRepFilletAPI_MakeFillet`, validar resultado e histórico de faces geradas/modificadas.
- **Rota geral:** somente depois da rota primária certificada, montar a solução com algoritmos públicos `ChFi3d`/`BRepBlend`, incluindo spine/guide, walking, aproximação, trims e reconstrução topológica. Falha dessa composição deve gerar diagnóstico técnico; não deve cair silenciosamente em Filling.

## 3. Offset + Walls

### Respostas obrigatórias

- **Existe operador oficial?** Sim para shapes adequados ao thick-solid: `BRepOffsetAPI_MakeThickSolid::MakeThickSolidByJoin`.
- **Exige composição?** Para Face isolada ou Shell aberto, sim.
- **Exige algoritmo proprietário?** Não.
- **Classes oficiais:** `BRepOffsetAPI_MakeThickSolid`, `BRepOffsetAPI_MakeOffsetShape::PerformByJoin`, `BRepBuilderAPI_MakeEdge`, `BRepBuilderAPI_MakeWire`, `BRepBuilderAPI_MakeFace`, `BRepBuilderAPI_Sewing`; validadores BRep.
- **Limitações conhecidas:** offsets podem falhar em regiões cujo raio local é menor que a espessura, em singularidades, auto-interseções, cantos problemáticos e topologia inválida. A correspondência entre bordas de origem e offset deve usar o histórico oficial do operador; pareamento apenas por posição é proibido.
- **Alternativa oficial:** `MakeOffsetShape::PerformByJoin` para produzir apenas o Shell paralelo; as paredes e tampas são então construídas e costuradas com builders oficiais.

### Estratégia futura

1. Preferir `MakeThickSolidByJoin` quando a entrada e as faces de abertura forem compatíveis.
2. Para Face/Shell aberto, executar `PerformByJoin`.
3. Obter correspondência topológica pelo histórico `Generated`/`Modified` do algoritmo.
4. Construir cada parede lateral por Edge/Wire/Face oficiais.
5. Costurar com `BRepBuilderAPI_Sewing` e validar fechamento, orientação e tolerâncias.
6. Se o resultado não fechar, retornar Shell válido com diagnóstico explícito; nunca declarar Solid artificialmente.

No OCCT 8, `PerformByJoin` e `MakeThickSolidByJoin` são as entradas públicas oficiais para os comportamentos históricos de offset e thick solid.

## 4. Boundary Extend

### Respostas obrigatórias

- **Existe operador oficial?** Não existe um comando topológico único “Boundary Extend”.
- **Exige composição?** Sim.
- **Exige algoritmo proprietário?** Não.
- **Classes oficiais:** `GeomLib::ExtendCurveToPoint`, `GeomLib::ExtendSurfByLength`, ferramentas oficiais de interseção/projeção, `BRepAlgoAPI_Section`/`BRepAlgoAPI_Splitter` quando houver alvo topológico, e builders de Edge/Wire/Face.
- **Limitações conhecidas:** `ExtendCurveToPoint` e `ExtendSurfByLength` aceitam continuidade 1, 2 ou 3, convertem a geometria limitada para BSpline e recomendam extensões pequenas em relação à geometria original. A extensão de superfície não aceita uma BSpline periódica na direção estendida. Esses níveis C1/C2/C3 não devem ser rotulados automaticamente como Match G1/G2 com outra superfície.
- **Alternativa oficial:** estender a curva de boundary até um ponto obtido por projeção/interseção e reconstruir apenas a região afetada; para extensão puramente paramétrica da superfície, usar `ExtendSurfByLength`.

### Estratégia futura

1. Identificar Boundary, lado U/V e direção before/after sem heurística espacial ambígua.
2. Se for extensão por comprimento, usar `ExtendSurfByLength`.
3. Se for “até geometria”, calcular o alvo com interseção/projeção oficial e usar `ExtendCurveToPoint` ou estender a superfície e recortá-la no alvo.
4. Reconstruir Edge/Wire/Face, preservar demais boundaries e validar gaps, orientação e auto-interseção.
5. Expor comprimento real, continuidade solicitada/obtida e tolerância no relatório do preview.

## 5. Boundary Trim

### Respostas obrigatórias

- **Existe operador oficial?** `BRepAlgoAPI_Splitter` é o operador oficial para dividir shapes por outros shapes. O comando de produto “Boundary Trim” ainda exige selecionar qual parte conservar e reconstruir a Face.
- **Exige composição?** Sim.
- **Exige algoritmo proprietário?** Não.
- **Classes oficiais:** `BRepAlgoAPI_Splitter`, `Geom_TrimmedCurve`, `BRepBuilderAPI_MakeEdge`, builders de Wire/Face e ferramentas oficiais de classificação/validação.
- **Limitações conhecidas:** o splitter pode produzir múltiplos fragmentos; interseções tangenciais, coincidentes ou próximas da tolerância exigem diagnóstico. A escolha do fragmento retido deve derivar da seleção/ponto de retenção do operador e não de ordem incidental de retorno.
- **Alternativa oficial:** quando o corte corresponde a parâmetros conhecidos sobre uma curva, criar `Geom_TrimmedCurve` ou uma Edge com limites paramétricos e reconstruir o Wire/Face; para corte geométrico geral, permanecer em `BRepAlgoAPI_Splitter`.

### Estratégia futura

1. Resolver a Face/Boundary objeto e Curve/Surface/Plane ferramenta.
2. Usar trim paramétrico somente quando os parâmetros forem inequívocos; nos demais casos usar `BRepAlgoAPI_Splitter`.
3. Classificar os fragmentos e reter o domínio indicado pelo usuário.
4. Reordenar/reconstruir o Wire, preservar inner wires quando válidos e construir a Face.
5. Validar fechamento, orientação, gaps, tolerâncias e quantidade de fragmentos antes de habilitar Apply.

## Matriz de risco e decisão

| Ferramenta | Risco principal | Condição de recusa técnica | Saída futura esperada |
|---|---|---|---|
| Match Surface | restrições G1/G2 incompatíveis ou aproximação fora da tolerância | erro medido excede tolerância | Face/Surface matched em `ShapeHandle` |
| Blend Surface | ausência de Edge compartilhada ou raio inviável | construção não concluída/shape inválido | Shell/Solid modificado ou Face de blend válida |
| Offset + Walls | auto-interseção ou paredes sem correspondência | shell não costurável/solid não fechável | Shell ou Solid, declarado corretamente |
| Boundary Extend | extensão excessiva, periódica ou alvo ambíguo | boundary/face inválida após rebuild | Face reconstruída |
| Boundary Trim | múltiplos domínios sem escolha inequívoca | parte retida indeterminada | Face recortada |

## Gate para implementação

A futura implementação da Categoria B deverá respeitar esta ordem interna:

1. contratos de entrada já aprovados e Geometry Input Resolver existente;
2. preview transitório de kernel;
3. relatório de tolerância, entidades afetadas e validade;
4. Apply atômico no documento; Cancel sem mutação;
5. persistência/restauração e Undo/Redo;
6. Feature Freeze;
7. smoke test no Release Windows e QA.

Nenhum passo desta auditoria autoriza implementação, alteração da Categoria A ou início da Categoria C.
