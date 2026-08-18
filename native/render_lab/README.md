# FLCAD Render Lab - R2-004

Protótipo independente Win32/Direct3D 11. Não depende do Flutter, do Runtime,
do CadDocument, do SceneGraph ou do Geometry Kernel do FLCAD.

## Escopo

- STL binária e ASCII;
- vertex/index buffers imutáveis;
- vertex shader e pixel shader simples;
- material técnico fosco;
- depth buffer D32 real;
- Orbit, Pan, Zoom e Fit;
- FPS e número de triângulos no título da janela;
- modo de carga de 1 milhão de triângulos para medição inicial.

R2-003 acrescenta normais por canto ponderadas por área e ângulo, preservação
de creases, filtro robusto de continuidade, material técnico fosco e
iluminação CAD estável em espaço de câmera. Nenhum efeito multipass foi
introduzido.

R2-004 acrescenta um passe GPU independente em `R32G32_UINT`. Cada pixel guarda
o tipo da subentidade e seu ID; o passe reutiliza o mesmo depth buffer do
viewport visual. Face, aresta e vértice da STL possuem picking real, hover e
seleção persistente. O contrato reserva ainda Curve, Section, Sketch e Preview,
que serão alimentados quando o SceneGraph for integrado ao Render Engine.

## Build

```powershell
cmake -S native/render_lab -B build/render_lab -A x64
cmake --build build/render_lab --config Release
```

## Execução

Abrir o seletor de STL:

```powershell
& "build/render_lab/Release/FLCAD Render Lab.exe"
```

Abrir diretamente uma STL:

```powershell
& "build/render_lab/Release/FLCAD Render Lab.exe" "C:\modelo.stl"
```

Métrica sintética de draw com exatamente 1 milhão de triângulos (repete os
índices da STL carregada sem alterar a geometria exibida):

```powershell
& "build/render_lab/Release/FLCAD Render Lab.exe" --benchmark-1m "C:\modelo.stl"
```

Controles:

- clique curto com o botão esquerdo: selecionar;
- arraste com o botão esquerdo: Orbit;
- botão do meio: Pan;
- roda: Zoom;
- `F` ou `Home`: Fit.
- `1`: filtro de faces;
- `2`: filtro de arestas;
- `3`: filtro de vértices.

## Limites intencionais do protótipo

Sem AO, HDR, tone mapping, PBR, deferred rendering, integração Flutter ou
comandos CAD. Curvas, seções, sketches e previews não existem em uma STL; o
protocolo aceita esses tipos, mas eles não são artificialmente simulados no Lab.
