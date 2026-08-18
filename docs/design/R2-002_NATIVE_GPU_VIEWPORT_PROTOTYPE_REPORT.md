# R2-002 — Native GPU Viewport Prototype Report

Status: candidato funcional construído; aguarda avaliação visual do operador.

## Resultado

Foi produzido um executável Windows independente que abre STL binária ou
ASCII e a renderiza diretamente em Direct3D 11. Ele não depende de Flutter,
CadDocument, CadRuntime, Geometry Kernel ou SceneGraph.

Componentes validados:

- janela Win32 independente;
- device e immediate context D3D11;
- swap chain e render target;
- depth buffer D32 real;
- vertex e index buffers imutáveis;
- vertex shader e pixel shader simples;
- material técnico fosco neutro;
- Orbit, Pan, Zoom e Fit;
- resize e destruição normal da janela;
- carregamento de STL ASCII e binária;
- métrica de FPS e adapter no título.

Não foram implementados picking, selection, highlight, AO, SSAO, HDR, tone
mapping, PBR, deferred rendering ou G-buffer.

## Testes executados

### Smoke controlado

Fixture: `smoke/g104b_primitives/torus.stl`.

- 1.920 triângulos;
- geometria completa e corretamente enquadrada;
- oclusão e superfície contínua visualmente corretas;
- inicialização, renderização e encerramento aprovados;
- captura: `smoke/r2-002-render-lab-torus-fixed.png`.

### STL real

Fixture: `C:\TRABALHO\MAHA 3D\CALOTA_INOXX\CALOTA_INOXX.stl`.

- arquivo com aproximadamente 25 MB;
- cavidades, faces dianteiras e traseiras resolvidas pelo depth buffer;
- ausência das sobreposições estruturais observadas no Canvas;
- Orbit, Pan, Zoom e Fit despachados em smoke operacional;
- processo permaneceu responsivo após a sequência.

### Carga inicial de 1 milhão de triângulos

O modo `--benchmark-1m` repete o index stream da STL até exatamente 1.000.000
de triângulos. Isso mede submissão e rasterização iniciais sem pretender ser um
benchmark científico nem uma otimização de cena.

Ambiente observado:

- GPU usada pelo D3D11: Intel(R) UHD Graphics;
- CPU: Intel Core i5-12450H;
- resolução da janela: 1280 × 820;
- draw loop sem VSync (`Present(0, 0)`);
- resultado observado: aproximadamente 493–522 FPS;
- working set observado: aproximadamente 72–80 MB;
- meta inicial de 60 FPS: superada neste cenário.

O número não representa FPS garantido de produto. O protótipo ainda não possui
sincronização de frame, múltiplos passes, picking ou grandes conjuntos de
entidades.

## Comparação visual objetiva

Flutter Canvas, na captura anterior da mesma fonte de trabalho:

- não resolveu corretamente profundidade e sobreposição;
- apresentou faixas e composição incorreta de faces;
- não comunicou de forma confiável a forma global da peça.

Direct3D 11 no protótipo:

- apresenta silhueta coerente;
- cavidades e faces ocultas respeitam profundidade;
- volumes permanecem estáveis independentemente da ordem dos triângulos;
- o material simples já permite reconhecer a peça;
- não depende de ordenação manual de faces.

Evidência lado a lado: `smoke/r2-002-gpu-vs-canvas.png`.

## Resposta ao gate R2-002

Pergunta: “O novo pipeline GPU já produz uma imagem visualmente superior ao
Flutter Canvas?”

Resposta técnica do protótipo: **SIM**.

O ganho decisivo não vem de efeitos avançados. Ele já aparece com um shader
simples porque a geometria possui rasterização 3D e depth buffer reais.

A aprovação final continua pertencendo ao operador. Este resultado não
autoriza integração Flutter nem a implementação das fases posteriores.

## Validação visual em vídeo

Foi registrada uma sessão contínua contendo:

- abertura do executável independente;
- diálogo real de importação da STL;
- carregamento de 502.728 triângulos;
- Orbit;
- Pan;
- Zoom in/out;
- Fit View;
- redimensionamento progressivo da janela;
- encerramento do Render Lab.

Artefato oficial:
`smoke/r2-002-video/FLCAD-R2-002-VALIDACAO-VISUAL.mp4`.

Especificações do arquivo entregue:

- H.264;
- 1920 × 1080;
- 28 segundos;
- 30 FPS no arquivo final;
- 840 frames;
- rótulos temporais identificando cada gesto;
- sem aceleração do movimento do viewport.

O contador do Render Lab permaneceu visível durante a sessão. A última leitura
registrada na tomada foi aproximadamente 642 FPS na Intel UHD Graphics. O
screen recorder possui custo e cadência próprios; o valor do título pertence
ao loop do Render Lab, não ao encoder de vídeo.

## Preparação para Picking

Picking não foi implementado. A fronteira prevista permanece:

```text
Display Mesh
  ├─ vertex/index streams
  ├─ entity ID
  └─ primitive/subshape mapping (futuro)
          ↓
ID/depth pass futuro
          ↓
PickResult renderer-independent
```

Nenhum contrato de domínio ou comportamento de seleção foi introduzido no
laboratório.
