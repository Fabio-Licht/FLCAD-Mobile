# R2-003 — Professional CAD Rendering Pipeline

Status: implementação técnica concluída; gate visual final permanece sob
aprovação do operador.

Escopo: somente `native/render_lab`. Programa 1, Flutter, CadDocument, Runtime,
Geometry Kernel e SceneGraph não foram alterados.

## Resultado implementado

### RENDER-002 — Professional Normal Pipeline

O pipeline anterior soldava posições e atribuía uma média global a cada
vértice. Isso suavizava regiões contínuas, mas também atravessava mudanças
reais de forma.

O pipeline atual produz uma normal independente por canto de triângulo:

- soldagem espacial adaptada à diagonal da malha;
- reconstrução da vizinhança por posição geométrica;
- orientação do winding auxiliada pela normal original do STL;
- peso pelo ângulo interno do canto;
- peso pela raiz da área do triângulo;
- limiar de crease de aproximadamente 52 graus;
- separação de normais através de descontinuidades;
- ponderação robusta pela concordância entre normais vizinhas;
- redução da influência de triângulos pequenos/isolados do scan;
- vertex stream expandido por canto para permitir continuidade e hard edge na
  mesma posição geométrica.

Consequência visual: superfícies contínuas deixam de revelar a tesselação,
enquanto furos, degraus, nervuras, filetes e limites abruptos permanecem
legíveis.

### RENDER-003 — Technical Material

Material único de apresentação técnica:

- azul neutro de baixa saturação;
- resposta predominantemente difusa;
- ausência de metalness e reflexo ambiental;
- sem textura artística ou aparência plástica;
- conversão explícita linear → sRGB;
- contraste concentrado na orientação da superfície.

### RENDER-004 — Professional Lighting

Foi adotado um conjunto técnico key/fill/top em espaço de câmera:

- key light descreve inclinação principal;
- fill evita perda completa das formas secundárias;
- top separa planos e transições superiores;
- piso ambiente reduzido para manter cavidades legíveis;
- iluminação é independente da posição world-space da peça.

As luzes são camera-relative. Orbit, Pan e Zoom compartilham a mesma base de
iluminação e não recalculam direções a partir da malha.

### RENDER-005 — Specular Control

- lóbulo largo e de baixa energia;
- expoente fixo e controlado;
- intensidade e valor máximo limitados;
- resposta acompanha cilindros/filetes;
- não existe highlight HDR nem ambiente refletido.

### RENDER-006 — Curvature Reading

A leitura de curvatura decorre da variação contínua das normais reconstruídas,
do diffuse técnico e da faixa especular. Nenhum edge artificial, derivada de
tela ou realce de triangulação foi introduzido.

## Itens explicitamente não implementados

- AO ou SSAO;
- HDR;
- tone mapping HDR;
- deferred rendering;
- G-buffer;
- GPU picking;
- selection/highlight;
- PBR ou iluminação cinematográfica.

## Validação funcional

### Fixture controlada

`smoke/g104b_primitives/torus.stl`:

- 1.920 triângulos;
- superfície contínua sem facetas visíveis;
- faixa tonal acompanha a curvatura;
- captura: `smoke/r2-003-torus.png`.

### STL real

`C:\TRABALHO\MAHA 3D\CALOTA_INOXX\CALOTA_INOXX.stl`:

- 502.728 triângulos originais;
- detalhes circulares, texto, furos, nervuras e filetes preservados;
- cavidades permanecem separadas sem AO;
- triangulação não domina a imagem;
- captura: `smoke/r2-003-final-1m.png`.

### Estabilidade

Foi executada sequência automatizada de Orbit e Zoom sobre a carga de 1 milhão
de triângulos. O processo permaneceu responsivo e a iluminação manteve a mesma
referência de câmera, sem alteração de parâmetros entre frames.

## RENDER-008 — Performance

Ambiente:

- Intel UHD Graphics;
- Intel Core i5-12450H;
- janela 1280 × 820;
- 1.000.000 de triângulos submetidos;
- draw loop sem VSync.

Resultados observados:

- aproximadamente 253–271 FPS;
- startup/preparação: aproximadamente 2,1 segundos;
- working set: aproximadamente 100–112 MB;
- meta mínima de 60 FPS: atendida com margem superior a 4×.

A queda em relação ao R2-002 é esperada: o vertex stream agora mantém normais
por canto para preservar creases. Não houve otimização prematura.

## RENDER-007 — Material Benchmark

Comparação direta R2-002 → R2-003 usando a mesma STL, câmera e janela:

`smoke/r2-003-r2-002-vs-r2-003.png`.

Comparação qualitativa com a imagem oficial Geomagic, usando modelos distintos:

`smoke/r2-003-qualitative-reference.png`.

Esta segunda imagem serve apenas para avaliar capacidade de leitura. Ela não é
apresentada como cumprimento do RENDER-010.

## RENDER-010 — Situação do Benchmark final

O Geomagic Design X está instalado e foram encontradas as sessões que originam
as referências visuais. Entretanto, o STL original exibido nessas sessões não
está disponível junto às imagens oficiais, e importar a STL atual dentro de uma
sessão de trabalho já aberta modificaria o estado operacional do usuário.

Por isso, não foi fabricada uma comparação falsa. Para concluir literalmente o
RENDER-010 ainda é necessário um destes pares:

1. STL do benchmark oficial disponibilizado ao Render Lab; ou
2. captura do Geomagic renderizando `CALOTA_INOXX.stl` na pose padrão; ou
3. autorização explícita para criar uma nova sessão Geomagic e importar essa
   STL, sem reutilizar/modificar as sessões existentes.

O executável e a implementação estão prontos para essa captura. A R2-003 não é
declarada visualmente aprovada antes desse comparativo e da avaliação do
operador.

## Resposta técnica provisória

Pergunta: “A leitura geométrica do Render Lab já está próxima do Geomagic?”

Resposta da implementação: **a direção e os fundamentos estão próximos, mas o
gate final ainda depende da comparação do mesmo modelo e da aprovação visual
do operador**.

