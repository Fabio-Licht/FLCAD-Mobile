# R2-001 — Rendering Engine Architecture

Status: proposta arquitetural, sem autorização de implementação.

Escopo: arquitetura, contratos, diagramas e plano de migração. Este documento
não contém shaders, código de renderização nem alterações ao produto.

## 1. Decisão executiva

O viewport principal do FLCAD Windows utilizará **Direct3D 11**, encapsulado
por um backend nativo e apresentado ao Flutter por uma **external texture**.
Flutter continuará responsável pelo shell, comandos, Explorer, Inspector,
diálogos e overlays 2D. O Render Engine será responsável somente pela imagem
3D, recursos gráficos, picking visível e métricas do viewport.

A decisão por D3D11 não será exposta ao domínio. O restante da plataforma
conhecerá apenas o contrato `CadRenderBackend`. Isso permite acrescentar no
futuro backends Metal, Vulkan ou outro backend Windows sem alterar
`CadDocument`, Geometry Kernel, comandos ou formatos de projeto.

Princípios invariáveis:

1. `CadDocument` continua sendo a fonte persistente da verdade.
2. O Geometry Kernel continua sendo o proprietário da geometria exata.
3. `CadSceneGraph` continua sendo a projeção operacional da cena.
4. O Render Engine nunca cria, cura ou modifica geometria CAD.
5. IDs exibidos e selecionados permanecem IDs estáveis do FLCAD.
6. Canvas e GPU recebem o mesmo snapshot lógico durante a transição.
7. A adoção do backend GPU depende de equivalência funcional e aprovação do
   operador, não apenas de desempenho ou qualidade de imagem.

## 2. API gráfica

### 2.1 Escolha: Direct3D 11

D3D11 é a escolha para o primeiro backend porque:

- Windows Release é a plataforma oficial de validação atual;
- o Flutter Windows Embedder possui caminho de external texture baseado em
  textura D3D11 ou handle DXGI compartilhado;
- oferece depth/stencil, MSAA, buffers persistentes, queries e render targets
  necessários ao CAD sem a complexidade operacional inicial do D3D12/Vulkan;
- possui suporte maduro em GPUs integradas, profissionais e máquinas Windows
  mais antigas;
- a recuperação de device loss e a inspeção por ferramentas do Windows são
  conhecidas e previsíveis;
- integra-se naturalmente a uma render thread nativa sem transformar o shell
  Flutter em uma janela nativa separada.

Baseline proposto: D3D11 Feature Level 11_0. Uma capacidade inferior poderá
acionar o Canvas de recuperação; não deverá reduzir silenciosamente a
correção geométrica do viewport GPU.

### 2.2 Alternativas descartadas para o primeiro backend

| Alternativa | Motivo para não ser a primeira |
|---|---|
| D3D12 | Mais controle, porém maior custo de sincronização, memória e recuperação sem benefício proporcional na primeira versão |
| Vulkan | Portável, mas integração e manutenção mais caras no Windows atual |
| OpenGL | Portável, porém com caminho de composição e drivers menos previsível no Windows |
| OCCT V3d/AIS como viewport inteiro | Acelera recursos CAD, mas reduz o controle da identidade visual e complica composição, eventos e overlays Flutter |
| Janela nativa filha | Problemas de clipping, DPI, foco, z-order e overlays; external texture preserva uma única composição Flutter |

## 3. Incorporação ao Flutter

```text
Flutter desktop window
┌──────────────────────────────────────────────────────────┐
│ Toolbar / Explorer / Inspector / dialogs                 │
│  ┌────────────────────────────────────────────────────┐  │
│  │ Stack                                               │  │
│  │  ├─ Texture: imagem produzida pelo Render Engine   │  │
│  │  ├─ Flutter overlay: labels, HUD e ferramentas 2D  │  │
│  │  └─ Flutter input surface: pointer/keyboard         │  │
│  └────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘
                    ↕ contrato de viewport
┌──────────────────────────────────────────────────────────┐
│ Plugin Windows                                           │
│ texture registry ↔ shared D3D11 texture ↔ render thread │
└──────────────────────────────────────────────────────────┘
```

O widget de viewport será um host, não um renderizador. Ele terá quatro
responsabilidades:

- controlar criação, resize, DPI, suspensão e descarte da textura;
- encaminhar eventos normalizados de entrada ao controlador operacional;
- compor overlays Flutter que não dependam de profundidade;
- exibir estado de inicialização, falha ou fallback.

O Render Engine produzirá em textura off-screen. Ao concluir um frame, o
plugin notificará o Flutter de que há uma nova imagem disponível. O Flutter
não copiará pixels pela CPU.

Regras de threading:

- UI thread: widgets, comandos e eventos do operador;
- render thread: recursos D3D11, atualização de buffers e submissão de frames;
- worker threads: preparação de malha, normais, LOD e estruturas espaciais;
- Geometry Kernel: mantém seu modelo atual de execução e nunca será chamado
  dentro de um frame.

## 4. Responsabilidades e comunicação

### 4.1 Fluxo autoritativo

```text
Comando do operador
        ↓
CadRuntime / transação
        ↓
CadDocument (estado persistente e IDs)
        ↓
CadDocumentSceneProjection
        ↓
CadSceneGraph (estado apresentável)
        ↓
Render Scene Adapter
        ↓
RenderSnapshot inicial + RenderDelta incremental
        ↓
CadRenderBackend
        ↓
D3D11 Render Engine ou Canvas fallback
```

O fluxo inverso nunca transporta geometria modificada:

```text
Pointer → PickRequest → PickResult com IDs estáveis
                         ↓
             Selection/command coordinator
                         ↓
              CadRuntime / CadDocument
                         ↓
                 SceneGraph selecionado
```

### 4.2 CadDocument

Não será alterado para armazenar dados de GPU. Ele continuará persistindo:

- ID e tipo da entidade;
- `ShapeHandle` ou `KernelMeshHandle`;
- estado operacional e dados serializáveis;
- revisões do documento.

Handles D3D, buffers, materiais compilados, IDs de textura e caches de picking
nunca entram em `cad-document.json`.

### 4.3 Geometry Kernel

O kernel fornece geometria exata e tesselações por contratos existentes ou
por um adaptador de apresentação. `ShapeHandle` é identidade/referência, não
payload gráfico. O Render Engine recebe somente dados imutáveis de exibição:

- posições e índices;
- normais de origem quando válidas;
- topologia necessária à preservação de arestas;
- limites espaciais;
- IDs de entidade e, quando disponíveis, IDs de face/edge/subshape;
- fingerprint e revisão da geometria.

Uma alteração geométrica gera nova revisão/fingerprint. Mudanças de câmera,
seleção, visibilidade ou material não solicitam nova tesselação ao kernel.

### 4.4 SceneGraph

`CadSceneGraph` continua definindo quais entidades aparecem e seus estados.
O `Render Scene Adapter` transforma o modelo atual, inclusive seu mapa de
geometria, em contratos tipados e versionados. O backend não interpreta mapas
dinâmicos nem conhece classes do kernel.

O SceneGraph permanece renderer-independent. Nenhum campo `D3D*` será
adicionado às entidades.

## 5. Contratos arquiteturais

Os nomes abaixo definem fronteiras, não código autorizado.

### 5.1 `CadRenderBackend`

| Operação | Responsabilidade |
|---|---|
| initialize | Negociar capacidades e criar a superfície |
| resize | Aplicar dimensões físicas, DPI e render scale |
| applySnapshot | Substituir a cena lógica completa em um ponto consistente |
| applyDelta | Aplicar alterações ordenadas por número de revisão |
| updateCamera | Atualizar somente estado de câmera |
| requestFrame | Marcar a cena para renderização |
| pick | Executar picking síncrono visual ou assíncrono tolerante |
| capture | Produzir captura determinística para Benchmark |
| suspend/resume | Tratar minimização e ciclo de vida da janela |
| dispose | Liberar recursos e cancelar trabalho pendente |

### 5.2 `RenderSnapshot`

Snapshot imutável contendo:

- versão do protocolo, project ID e scene revision;
- lista de entidades com `entityId`, kind e geometry revision;
- transform, bounds, visibilidade e render layer;
- referência a um recurso geométrico imutável;
- material semanticamente definido, não parâmetros específicos de D3D;
- estado de seleção, hover e preview;
- câmera e configurações de qualidade.

### 5.3 `RenderDelta`

Cada delta possui `baseRevision` e `targetRevision`. Operações permitidas:

- adicionar/remover entidade;
- substituir recurso geométrico;
- alterar transform, visibilidade, layer ou material;
- alterar selection/hover/preview;
- atualizar câmera e viewport.

Delta fora de ordem é rejeitado e provoca ressincronização por snapshot. Isso
impede que Canvas e GPU mostrem estados diferentes após undo/redo ou operações
assíncronas.

### 5.4 `RenderGeometryResource`

Contrato imutável identificado por `geometryId + revision + fingerprint`:

- vertex/index streams;
- normal/feature streams opcionais;
- intervalos de primitives por subentidade;
- bounding box e bounding sphere;
- política de continuidade e arestas duras;
- LODs opcionais;
- metadados de diagnóstico, nunca dados de domínio mutáveis.

Uploads são cacheados por fingerprint. Uma entidade pode trocar transform ou
material sem duplicar sua geometria na memória.

### 5.5 `PickRequest` e `PickResult`

Request:

- coordenada física do pixel e tamanho do viewport;
- scene revision e camera revision;
- filtro de tipos selecionáveis;
- modo hover, click, janela ou profundidade múltipla;
- tolerância para edge/curve/point em pixels.

Result:

- status e revisões usadas;
- entity ID, primitive/subshape ID e kind;
- profundidade, ponto world-space e normal;
- posição de tela e distância ao cursor;
- lista ordenada de candidatos quando houver ambiguidade.

Resultados com revisão obsoleta são descartados, nunca aplicados à seleção.

### 5.6 `RenderCapabilities`

Contrato consultável contendo adapter, feature level, memória estimada, MSAA,
limites de textura/buffer, picking suportado e motivo de fallback. Isso permite
diagnóstico reproduzível sem acoplar a UI à API gráfica.

## 6. Picking

O picking utilizará o mesmo depth-tested scene usado para desenhar a imagem.
Isso garante que a entidade destacada seja aquela efetivamente visível.

### 6.1 Pipeline de picking

1. Cada primitive recebe IDs compactos de entidade e subentidade.
2. Um passe de ID usa a mesma câmera, clipping, transform e depth buffer do
   frame visual.
3. Para hover, lê-se uma pequena região ao redor do cursor; os candidatos são
   ordenados por prioridade operacional, distância em pixels e profundidade.
4. Para clique, o resultado inclui world position reconstruída pela
   profundidade e matriz inversa da câmera.
5. Edge, curve e point recebem tolerância em pixels, independente do zoom.
6. O ID compacto é resolvido para o ID estável do SceneGraph.
7. O controlador de seleção atual decide a seleção; o renderer não altera o
   CadDocument.

### 6.2 Latência e confirmação

- hover poderá usar readback assíncrono de um frame, com cancelamento por
  revisão do cursor;
- clique terá prioridade e poderá aguardar a resposta do frame correspondente;
- pré-seleção, seleção ativa e preview são estados distintos no SceneGraph;
- uma verificação CPU/BVH opcional poderá fornecer candidatos de curvas finas
  ou diagnóstico, mas não substituirá a visibilidade definida pelo depth
  buffer;
- seleção retangular usará buffer de IDs em região ou estrutura espacial,
  conforme volume, preservando o mesmo contrato de resultado.

## 7. Pipeline completo de renderização

Arquitetura inicial recomendada: **forward rendering técnico**, com depth
pre-pass seletivo. Deferred rendering não é requisito da fundação.

```text
Geometry extraction / tessellation
        ↓
Validation + normal/crease reconstruction + subshape mapping
        ↓
Immutable CPU render resources
        ↓
Incremental upload to persistent GPU buffers
        ↓
Frustum culling + LOD + draw classification
        ↓
Depth pre-pass / opaque depth
        ↓
Opaque engineering-material pass (MSAA)
        ↓
Technical edges and section boundaries
        ↓
Transparent / preview pass, depth-aware and ordered
        ↓
Selection + hover overlays, depth-aware
        ↓
Optional geometry-legibility effects approved by Benchmark
        ↓
Output transform and anti-alias resolve
        ↓
Shared D3D11 texture → Flutter Texture
        ↓
Flutter 2D overlays
```

### 7.1 Preparação geométrica

- validar índices, degenerados, winding e bounds;
- consumir normais confiáveis ou reconstruí-las por topologia/posição;
- ponderar normais por ângulo/área e preservar creases definidos;
- separar textura real de scan de ruído de triangulação;
- manter mapeamento triangle → entity/subshape;
- gerar LOD sem alterar a identidade da geometria selecionável;
- nunca bloquear a render thread com tesselação.

### 7.2 Classificação de passes

Ordem lógica:

1. background;
2. depth/opaque mesh and BRep display meshes;
3. sections e feature edges;
4. surfaces transparentes;
5. preview;
6. selection e hover;
7. sketch, curves e points depth-aware;
8. WCS/triad e overlays de tela.

Categorias visuais serão semânticas (`mesh`, `surface`, `section`, `sketch`,
`curve`, `preview`, `selection`), permitindo identidade consistente entre
backends sem compartilhar implementação.

### 7.3 Qualidade e estabilidade

- depth/stencil obrigatório;
- MSAA para silhuetas e linhas geométricas;
- iluminação em espaço linear;
- material técnico fosco com faixa especular controlada;
- câmera e luzes estáveis durante navegação;
- transparência nunca poderá selecionar ou ocultar incorretamente uma entidade;
- efeitos adicionais serão gates independentes e somente entram se melhorarem
  a leitura geométrica;
- resolução dinâmica é permitida durante interação, mas não pode alterar
  picking, câmera ou captura de Benchmark.

### 7.4 Frames e sincronização

O renderer é event-driven: desenha quando câmera, cena, viewport, animação ou
captura exigirem. Não manterá loop permanente sem necessidade.

Cada frame registra `sceneRevision`, `cameraRevision` e `frameId`. Capturas e
pick results carregam essas revisões para impedir comparação ou seleção de um
estado intermediário.

## 8. Compatibilidade total com a Plataforma FLCAD

Compatibilidade significa preservar:

- schema e arquivos de projeto;
- IDs de `CadDocumentEntity`;
- `ShapeHandle`, `KernelMeshHandle` e APIs do kernel;
- undo/redo e transações;
- semântica de seleção e comandos;
- câmera operacional, Fit View, Sketch e WCS;
- exportação e persistência;
- instalação e Release Windows.

Medidas arquiteturais:

1. Camada anticorrupção `Render Scene Adapter`: nenhum tipo D3D atravessa para
   Dart de domínio.
2. Protocolo versionado: plugin e Dart negociam versão e capacidades.
3. IDs estáveis: tabelas compactas de GPU são descartáveis e reconstruíveis.
4. Recurso gráfico derivado: todo buffer pode ser recriado a partir do kernel
   e SceneGraph.
5. Falha isolada: device loss não corrompe documento nem encerra transação.
6. Fallback explícito: Canvas permanece disponível durante migração e recovery.
7. Diagnóstico: adapter, driver, recursos, tempos e motivo do fallback entram
   em log técnico, não no documento.
8. Testes de contrato: o mesmo fixture de cena deve produzir as mesmas
   entidades visíveis, selecionáveis e bounds em ambos os backends.

## 9. Coexistência Canvas + GPU

```text
CadSceneGraph
      ↓
Render Scene Adapter (único)
      ↓ RenderSnapshot / RenderDelta
      ├───────────────┐
      ↓               ↓
CanvasBackend     D3D11Backend
      ↓               ↓
CustomPainter     Flutter Texture
      └──── seleção por feature flag / capability / recovery ────┘
```

Regras da coexistência:

- ambos implementam `CadRenderBackend` e consomem os mesmos contratos;
- backend é escolhido ao criar o viewport, nunca no meio de uma transação;
- troca em runtime exige snapshot completo e preserva câmera/seleção;
- modo espelho de desenvolvimento pode alimentar ambos, exibindo apenas um;
- Canvas permanece baseline de recuperação, testes e hardware incompatível;
- funcionalidades de domínio não podem depender de capacidade exclusiva do
  backend GPU;
- uma função visual exclusiva pode degradar explicitamente no Canvas, sem
  alterar o resultado geométrico ou o comando CAD;
- o Canvas só será removido após decisão futura específica, nunca como efeito
  colateral da adoção do GPU viewport.

## 10. Gestão de memória e grandes malhas

- geometria é imutável e compartilhada por fingerprint;
- uploads são segmentados e canceláveis;
- recursos têm orçamento de CPU/GPU e política LRU;
- câmera, seleção e materiais são deltas pequenos;
- malhas grandes utilizam chunks espaciais e LOD;
- a qualidade parada é restaurada após qualquer redução interativa;
- descarregar GPU não descarrega automaticamente o ShapeHandle do kernel;
- nenhuma cópia integral da malha ocorre por frame;
- métricas mínimas: triângulos visíveis, draw calls, memória, tempo CPU/GPU,
  upload pendente, latência de pick e frames descartados.

## 11. Falhas e recuperação

Estados do backend:

```text
uninitialized → initializing → ready → suspended
                         ↘ degraded → recovering → ready
                                      ↘ failed → Canvas fallback
```

Device loss invalida apenas recursos derivados. O backend recria device,
textura e caches e solicita snapshot atual. Se falhar, o host troca para Canvas
e informa claramente o operador; o documento permanece aberto.

## 12. Plano de migração

Cada fase exige Release Windows, testes e gate próprio. Nenhuma fase autoriza a
seguinte automaticamente.

### Fase 0 — Contratos e Benchmark

- aprovar este documento;
- congelar uma malha oficial disponível ao FLCAD, poses e resolução;
- definir critérios de legibilidade, picking e desempenho;
- registrar hardware mínimo e recomendado.

Gate: arquitetura e fixture aprovados, sem código de renderer.

### Fase 1 — Abstração sem mudança visual

- formalizar contratos renderer-independent;
- colocar Canvas atrás de `CadRenderBackend`;
- introduzir snapshot/delta e testes de revisão;
- manter pixels e operação atuais.

Gate: Release equivalente ao anterior e todos os fluxos preservados.

### Fase 2 — Spike de integração isolado

- provar external texture, resize, DPI, lifecycle e device loss;
- mostrar geometria sintética interna, sem integrar comandos CAD;
- medir cópia, sincronização e compatibilidade de adapters.

Gate: nenhum readback de frame pela CPU e estabilidade no hardware-alvo.

### Fase 3 — Cena real básica

- consumir snapshot de uma malha real;
- buffers persistentes, depth, câmera, Fit View e MSAA;
- manter Canvas selecionável.

Gate: geometria completa, oclusão correta e navegação sem regressão.

### Fase 4 — Sincronização incremental

- deltas, transforms, visibilidade, undo/redo, preview e descarte;
- cache por fingerprint e recuperação por snapshot;
- testes de cenas grandes.

Gate: Canvas e GPU apresentam a mesma cena lógica após sequências operacionais.

### Fase 5 — Picking profissional

- ID/subshape pass, hover, click, tolerância de edge/curve e seleção múltipla;
- integrar resultados ao selection coordinator existente;
- validar revisão e latência.

Gate: nenhum destaque de entidade oculta ou divergente da imagem.

### Fase 6 — Rendering Benchmark

- normais e creases;
- material técnico, iluminação, edges, transparência e seleção;
- efeitos de legibilidade entram isoladamente e com comparação visual.

Gate: aprovação do operador nas mesmas poses e no uso contínuo.

### Fase 7 — Hardening

- grandes malhas, memória, device loss, múltiplos DPI e adapters;
- telemetria local, captura determinística, packaging e testes prolongados;
- qualificar fallback.

Gate: matriz de hardware e jornada de trabalho aprovadas.

### Fase 8 — Rollout

- GPU opt-in em Release controlado;
- GPU default após estabilidade medida;
- Canvas permanece recovery durante período definido;
- remoção futura exige ADR independente.

## 13. Critérios de aceite arquitetural

A arquitetura estará pronta para implementação somente quando houver acordo
sobre:

- D3D11 como primeiro backend e external texture como composição;
- propriedade dos dados e fluxo unidirecional;
- contratos snapshot/delta, picking e capabilities;
- IDs e revisões estáveis;
- pipeline forward técnico e passes;
- fallback e coexistência Canvas/GPU;
- fixture oficial, hardware-alvo e gates de migração;
- orçamento e responsáveis por plugin, renderer, integração e QA visual.

## 14. Fora de escopo de R2-001

- criação de plugin nativo;
- registro de external texture;
- shaders;
- buffers ou passes reais;
- alteração de `CadDocument`, Runtime, ShapeHandle ou GeometryKernelAPI;
- substituição do viewport Canvas;
- alteração visual do Release atual.

R2-001 registra somente o desenho do sistema. Qualquer implementação exige
autorização explícita da fase correspondente.
