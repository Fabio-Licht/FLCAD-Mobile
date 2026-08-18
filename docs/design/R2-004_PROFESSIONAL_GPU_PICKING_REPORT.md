# R2-004 — Professional GPU Picking Engine

## Resultado

O Render Lab passou a possuir picking GPU independente da aparência visual.
O teste foi executado com `CALOTA_INOXX.stl`, contendo 502.728 triângulos.

Resultados observados no mesmo ponto de tela:

| Filtro | Resultado GPU |
|---|---|
| Face | Face 65156 |
| Edge | Edge 134191 |
| Vertex | Vertex 10209 |

O viewport permaneceu entre aproximadamente 445 e 455 FPS na Intel UHD
Graphics durante a validação. A captura de seleção está em
`smoke/r2-004-face-highlight.png`.

## Pipeline

```text
Display Mesh
   ├─ Visual pass -> RGBA swap-chain target
   └─ Picking pass -> R32G32_UINT ID target
                         │
                         ├─ R = PickKind
                         └─ G = stable subentity ID

Visual pass ─────┐
                 ├─ same D32 depth texture
Picking pass ────┘

Cursor -> tolerance neighborhood -> active type filter -> hover
Click without drag -> persistent selection -> visual confirmation
```

O pixel shader visual não participa da decisão. Cor, luz, material e shading
podem ser alterados sem modificar os IDs retornados. O depth test do passe de
picking usa a mesma textura D32 e as mesmas matrizes do desenho visível.

## Contrato de identidade

`PickResult` contém apenas `PickKind` e `id`. O protocolo reserva os tipos:

- Face;
- Edge;
- Vertex;
- Curve;
- Section;
- Sketch;
- Preview.

STL fornece apenas faces triangulares, arestas e vértices. Por isso esses três
tipos são reais e foram validados nesta etapa. Curve, Section, Sketch e Preview
estão reservados no protocolo, mas não foram falsamente criados no laboratório;
receberão buffers e IDs do adaptador do `CadSceneGraph` na fase de integração.

## Interação

- movimento do cursor: pré-seleção por GPU;
- clique curto esquerdo: seleção;
- arraste esquerdo: Orbit, sem selecionar acidentalmente;
- `1`, `2`, `3`: filtros Face, Edge e Vertex;
- seleção ativa: laranja;
- pré-seleção de face: ciano;
- título: mostra filtro, tipo e ID de hover/seleção.

O filtro explícito é necessário em malhas digitalizadas densas: sem ele,
vértices e arestas próximos ao cursor poderiam impedir a escolha previsível de
uma face.

## Compatibilidade futura

O Render Lab continua sem referências a `CadDocument`, `CadRuntime`, Geometry
Kernel ou Recognition. Na integração, um adaptador unidirecional produzirá
buffers de exibição e uma tabela `GPU ID -> SceneGraph handle`. A resposta do
picking será traduzida de volta pelo adaptador, sem alterar os contratos dos
motores existentes.

## Limites desta entrega

- highlight preenchido está validado para faces;
- edge e vertex possuem hover, ID e seleção real, atualmente confirmados pelo
  estado textual; sua apresentação visual ampliada será o primeiro refinamento
  antes da incorporação no viewport do Programa 1;
- curvas, seções, sketches e previews dependem dos respectivos buffers do
  SceneGraph, inexistentes no carregador STL isolado.

## Gate

O novo pipeline elimina a dependência de cor e triangulação projetada usada
pelo picking do Canvas e distingue explicitamente tipo e subentidade. O gate
técnico do protótipo é positivo para Face/Edge/Vertex. A superioridade
operacional completa ainda requer validar o highlight ampliado de Edge/Vertex e
as entidades provenientes do SceneGraph durante a integração gradual.
