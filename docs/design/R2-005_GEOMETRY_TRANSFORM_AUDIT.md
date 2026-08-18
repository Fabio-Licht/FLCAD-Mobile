# R2-005 — Geometry Transform Audit

## Escopo

Auditoria limitada ao caminho de geometria e transformação. DXGI, Flutter
External Texture, compositor, picking e shaders visuais não foram alterados.

## Conclusão executiva

A STL não é perdida nem escalada no caminho de geometria. A falha ocorre no
contrato da matriz enviado para o constant buffer do Native Viewport.

O Render Lab usa o contrato Direct3D abaixo:

```text
vetor-linha × World × View(LH) × Projection(LH, depth 0..1)
```

O FLCAD envia ao Native Viewport uma matriz produzida para o Canvas:

```text
Projection(RH, depth -1..1) × View(RH) × vetor-coluna
```

Os 16 valores são copiados sem conversão para um shader que executa
`mul(position, mvp)`. Portanto, ordem, convenção vetorial, handedness e faixa de
profundidade não coincidem.

## Respostas objetivas

### Bounding Box

**Corresponde geometricamente, mas não é bit a bit idêntica.** Canvas e Native
percorrem a mesma lista `nodes`. O Canvas calcula em `double`; o host converte
os vértices para `float` e recalcula min/max. A única diferença esperada é o
arredondamento float, não uma transformação ou troca de unidade.

### Escala da STL

**Permanece inalterada.** O Display Adapter encaminha `nodes` e `triangles`
diretamente. O Native converte posição de `double` para `float`, sem fator de
escala, normalização de unidade ou matriz de modelo.

### World

**Correta.** É identidade no Render Lab e é implicitamente identidade no
Native Viewport.

### View

**A View interna do Native é correta e equivalente à do Render Lab, mas deixa
de ser usada.** Após `setCamera`, `has_camera_matrix_` fica verdadeiro e o host
passa a usar permanentemente os 16 valores recebidos do Dart. A View recebida é
right-handed e foi construída para vetor-coluna; não é a View LH do Render Lab.

### Projection

**Não utiliza os mesmos parâmetros no caminho ativo.** O fallback Native é
igual ao Render Lab: FOV vertical 42 graus, aspecto `width/height`, near
`max(radius*0.001, 0.001)` e far `max(radius*100, 1000)`. O caminho ativo recebe
do Dart FOV 45 graus, near `distance/10000`, far `distance*1000` e projeção com
profundidade OpenGL `[-1,+1]`.

### Fit View

**Usa a mesma geometria de Bounding Box, mas não o mesmo enquadramento.** Render
Lab e fallback Native usam `distance = radius * 2.7`. O Canvas usa
`distance = radius * 3.5`. Além disso, o `Fit()` executado pelo Native após o
snapshot é imediatamente sobreposto por `setCamera(widget.camera)`.

### Viewport Transform

**Preserva a proporção.** Render Lab e Native configuram o viewport com a
largura e altura atuais e aspecto `width/height`. Não foi localizado stretch ou
troca de eixos no viewport transform.

### Depth Range

**O estado Direct3D está correto; a matriz ativa é incompatível.** O viewport
usa depth `[0,1]`, o depth buffer é limpo com `1` e o teste é `LESS`. Entretanto,
a projeção enviada pelo Dart produz NDC `[-1,+1]`. Isso pode recortar ou
reposicionar profundidade de forma incorreta.

### Near e Far

**Coerentes no fallback Native; divergentes no caminho ativo.** Os valores do
Canvas não são os valores do Render Lab e acompanham uma projeção com outra
convenção de profundidade.

### Localização da falha

**A falha entra antes do Vertex Shader, no conteúdo do constant buffer, e se
manifesta na multiplicação World → View → Projection.** Vértices, índices,
escala e Bounding Box ainda estão corretos antes dessa multiplicação. O shader
executa corretamente, mas recebe uma matriz com contrato incompatível; o
resultado de clip-space já sai incorreto.

## Teste mínimo comparativo

O Render Lab já fornece o lado independente do teste para cubo/torus/STL. O
NativeViewportHost, porém, só possui ciclo de vida através do runner Flutter;
portanto não existe hoje um executável independente capaz de executar o lado
“FLCAD Native GPU sem Flutter”. Criar esse host seria uma implementação nova,
fora desta auditoria.

Mesmo sem esse novo host, a comparação determinística do pipeline mostra:

| Entrada | Antes de WVP | WVP interno Native/Render Lab | WVP ativo recebido do Dart |
|---|---:|---:|---:|
| Cubo | equivalente | equivalente | incompatível |
| Torus | equivalente | equivalente | incompatível |
| STL | equivalente | equivalente | incompatível |

A forma da entrada não muda o diagnóstico: o erro é global e afeta todo ponto
transformado pelo mesmo constant buffer.

## Correção indicada para uma etapa autorizada

Definir um único contrato de câmera para o Native GPU. A alternativa de menor
risco é enviar parâmetros de câmera (Eye, Target, Up, FOV, near, far e modo de
projeção) e montar `World * View * Projection` no C++ com a mesma convenção do
Render Lab. Não copiar diretamente a matriz destinada ao Canvas.

