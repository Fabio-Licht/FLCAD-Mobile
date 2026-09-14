# Qualidade do viewport CAD — tarefa isolada

Base: `7a422f7`, compatibilidade STEP revisada e commitada na branch
`fix/cad-runtime-transaction-coordinator`. Esta tarefa está na branch
`fix/cad-viewport-quality`; seu diff não integra o commit de compatibilidade.
Reprodução: a matriz STEP privada indicada pelo usuário, sem copiar ou alterar
a origem. **Baseline visual aprovado manualmente pelo usuário** após as
correções registradas abaixo. Esta rodada apenas revisa, valida e consolida
o baseline; não introduz novos ajustes visuais.

## Diagnóstico separado

| Fronteira | Evidência | Correção delimitada |
|---|---|---|
| BREP | O importador exige um sólido e `BRepCheck_Analyzer::IsValid`; a matriz real passou. Bounds transitórios finitos, aproximadamente 157 × 171 × 32 mm. | Não modificar geometria, tolerâncias ou unidades do BREP. |
| Tesselação | `cob_shape_write_v1`, kind 2, gera o display STL com deflexão absoluta 0,1 e ângulo 0,35 rad, independentemente da diagonal. | Manter o STL durável; tesselação **transitória** sobre cópia do BREP com deflexão diagonal × 10⁻⁴, limitada a [10⁻⁵, 10], e ângulo inicial 0,08 rad. |
| Normais nativas | `NativeViewportHost::ApplySnapshot` somava normais por índice. Vértices separados do STL não compartilhavam a suavização. O shader também invertia normais pelo sinal de Z mundial. | Normais analíticas por face BREP e nó UV, transformadas pela localização e orientação da face. Não misturar faces distintas. Remover a inversão arbitrária por Z. |
| Canvas | A reconstrução por ângulo/área soldava STL, mas podia suavizar transições entre faces CAD. | Preservar as normais analíticas da apresentação BREP em ambos os renderers; manter reconstrução por creases para meshes sem BREP. |
| Arestas | `_paintMeshFeatureEdges` inferia bordas e creases dos triângulos, com stroke 1,15/1,7. Não era um inventário de arestas BREP. | Amostrar arestas únicas da topologia, excluir degeneradas e seams, sem diagonais de triangulação. Passagem GPU de linhas com teste de profundidade para Arestas; Wireframe mostra todas as arestas CAD. |
| Mouse | A UI não encaminhava modificadores; Ctrl+Shift+MMB tinha precedência de orbit. Soltar o auxiliar após orbit ativava zoom. A primeira movimentação de orbit iniciado no down era descartada; movimentos menores que 0,1 px também eram descartados sem acumulação. | Encaminhar teclado, separar zoom explícito e retornar ao pan. Iniciar orbit no down, mantendo priming na transição durante um gesto. Preservar deslocamentos subpixel não nulos. |
| Pose nativa | Toda atualização de cena executava `Fit()`, inclusive deltas de seleção. | A pose canônica Dart não pode ser modificada por upload de cena. |
| Fit/zoom | Fit usava raio × 2,7 e não considerava aspecto/FOV. Zoom por roda aplicava exp(delta × 0,001), cerca de 13% por 120 unidades. | Fit por esfera, menor FOV horizontal/vertical e margem 8%; roda exp(delta × 0,0004), cerca de 4,7%, com limites relativos ao modelo e clipping. Vistas padrão reutilizam Fit. |

A matriz real gerou 122.158 triângulos e 169 arestas topológicas com deflexão
0,0234054 e ângulo 0,08 rad na descoberta Debug. Esses números comprovam dados
preparados; a aprovação visual foi fornecida separadamente pelo usuário.

## Contrato de apresentação transitória

`flcad_occ_display_geometry` é uma consulta nativa somente leitura. Recebe a
residência protegida pelo lease de shape já existente e retorna coordenadas,
índices, normais e polylines de arestas; não retorna identidade nativa. Não
admite/reabre source nem recebe pathname. Não publica owners ou meshes no
registry, não modifica o SDK e não escreve assets.

A cena mantém `nodes`, `triangles`, bounds e descritor do display STL durável
inalterados, inclusive a checagem de correspondência exata antes do commit.
Os renderers consultam `brepPresentation` para apresentação transitória. Cor
geral continua vindo do manifesto validado, pela conversão linear → sRGB
existente. Documento, journal, três assets e transferências de ownership não
recebem novo contrato. Open/Redo reconstruem a apresentação sob leases e antes
da publicação, junto da preparação já existente; Undo/close descartam os dados
visuais com a cena.

O trabalho nativo roda em worker enquanto o lease permanece vivo; seu resultado
não concede autoridade. Revogação continua sendo conferida pelo coordenador
antes de promover/publicar. Não há nova aquisição da fila.

Limites: 250 mil triângulos, 200 mil pontos de aresta e saída JSON de 64 MiB.
Até seis tentativas de tesselação, coarsening ×2 na deflexão e ×√2 no ângulo,
limitado a 0,5 rad. Falhas/budgets são rejeitados; não há retry por pathname.
Esses limites controlam saída e publicação; não representam um limite rígido
de tempo ou de memória interna dos algoritmos OCCT. Em singularidades onde a
normal analítica não é definida, usa-se a normal geométrica orientada do
triângulo. Não prometer normais analíticas em todos os vértices singulares.

## Testes e revisão

- `cad_viewport_quality_math_test`: enquadramento em portrait/landscape e ambos
  os lenses; Fit repetido; pan sem orientação alterada; pivot de orbit e
  acumulação subpixel independente da frequência; zoom
  recíproco, subdividido, finito e saturado; vistas padrão sem salto inicial;
  normais por face preservadas entre chunks.
- `navigation_engine_test` e `professional_cad_viewport_test`: retorno orbit →
  pan sem zoom, início de orbit no down, regressões de seleção/Sketch/roda.
- `native_viewport_display_adapter_test`: snapshot com normais e delta de
  seleção sem reenviar geometria.
- `mesh_stream_test`: política por escala e rejeição não finita; esfera,
  localização e orientação invertida; normais unitárias; 12 arestas do box;
  BREP serializado idêntico antes/depois; registry/owners intactos; buffer
  insuficiente sem publicação parcial.
- `cad_runtime_managed_step_test`: cor/manifesto originais, apresentação BREP e
  topologia, save/open/Undo/Redo e assets intactos. Regressões BREP/STL,
  runtime/transações, staging/custody/CAF/source bridge preservadas.
- Matriz real opt-in pelo controlador produtivo: origem CAF, três assets,
  compatibilidade e apresentação transitória, sem nova chamada ao pipeline
  legado. HLSL VSMain/PSMain/PSLine compilados com D3DCompiler 47.

As tentativas intermediárias não são aprovação: substituir inicialmente a
geometria durável pela apresentação violou a checagem de descritor e foi
corrigido com `brepPresentation`. O primeiro lote concorrente também atingiu
timeouts de 30 s durante compilação/descoberta pesada. A repetição usa timeout
computacional de 2 min e concorrência 2; não usa delays como prova. O cálculo
analítico foi reduzido a uma vez por nó/face, sem avaliá-lo na passagem que
apenas escreve posições. O smoke BREP com duas importações passou em 13 s.

Revisão: o contrato de compatibilidade e manifesto não tem diff nesta branch;
BREP original é copiado sem triangulação compartilhada; dados visuais não são
identidades persistidas. A preparação mantém leases e as checagens documentais
existentes. Não adicionar pathname, coleta de assets, edição STEP, assemblies,
cores por corpo/face ou material/transparência.

Em documentos mistos ou meshes sem topologia BREP, os modos globais não opacos
continuam no Canvas e suas feature edges são aproximações de mesh. O Canvas não
fornece oclusão GPU de arestas; não declarar hidden-line exato nessa variante.
Na matriz STEP, Arestas usa a passagem GPU com profundidade. Seleção de
triângulos na apresentação continua sendo seleção de mesh, não identidade
durável de face CAD ou autorização para edição STEP.

## Roteiro visual obrigatório — matriz real

Usar `build/windows/x64/runner/Release/flcad_mobile.exe`, junto de DLLs e data
do mesmo bundle. Abrir/criar projeto de teste e importar a matriz indicada pelo
usuário; conferir o aviso de compatibilidade. Registrar tamanho/SHA-256 da
origem externamente antes/depois, sem gravar locator no documento.

| Passo | Critério manual |
|---|---|
| Shaded, ISO e superior | Superfícies planas com iluminação uniforme, superfícies curvas suaves, sem pinwheel radial; silhouette sem perda visível de detalhe. |
| Arestas, superior e ISO | Arestas CAD finas; nenhuma diagonal radial de tesselação; arestas ocultas não atravessam o sólido na passagem GPU. |
| Wireframe | Topologia CAD reconhecível, sem rede de todos os triângulos; curvas contínuas. |
| MMB arrastado | Apenas translação; repetir horizontal/vertical/diagonal, sem mudança de orientação. |
| Shift+MMB ou MMB+primário | Orbit em torno do pivot; movimento pequeno previsível; soltar auxiliar retorna ao pan sem zoom. |
| Ctrl+Shift+MMB | Zoom explícito; não orbit. |
| Roda lenta e rápida, nos dois sentidos | Incrementos proporcionais e pequenos; não cruzar pivot/near; saturação recuperável. |
| Fit e vistas padrão | Modelo inteiro visível em janela larga e estreita; Fit repetido não muda pose; primeira roda após vista padrão sem salto. |
| Selecionar/desselecionar e mudar modo | Nenhum refit/rotação involuntária ou perda da cor geral. |
| Save/close/open/Undo/Redo/close | Mesma geometria, nome, unidade e cor; nenhum asset alterado e nenhuma cena órfã. |

Só aprovar visualmente após registrar resultados deste roteiro. Testes
automatizados, hashes e build Release não substituem essa aprovação.

## Resultado automatizado

- 382 testes STEP/BREP/STL/runtime/transações, CAF/staging/custody/source bridge
  passaram com concorrência 2 e timeout computacional de 2 min.
- 71 testes viewport, câmera, navegação e seleção integrada passaram.
- 12 CTests Debug e 12 Release passaram; regressão de apresentação nativa
  repetida nas duas configurações após a assertion final de dados não vazios.
- Matriz real pelo controlador: Debug e DLLs do bundle Release passaram.
  Release repetiu 122.158 triângulos/169 arestas em 21 s; não é smoke visual GPU.
- Build normal Windows Release passou; três shaders compilaram; analyze,
  formatação Dart e diff-check passaram. SHA-256 da origem e TKDESTEP.dll do SDK
  permaneceram idênticos aos baselines.
- Worktree do viewport fica sem commit para inspeção manual. Nenhum push.

## Correção visual após aprovação da navegação

A aprovação manual de pan, zoom e orbit foi recebida nesta etapa. Seus arquivos
permanecem idênticos ao início desta tarefa, assim como runtime/transações,
contrato STEP, leitor de compatibilidade e gerador da apresentação BREP. O HEAD
continua em `7a422f7`; nenhum commit adicional foi feito.

| Evidência | Causa confirmada | Correção limitada ao renderer |
|---|---|---|
| Face oposta às luzes fica quase preta | HLSL recebia normais em mundo e usava duas luzes fixas nesse espaço, com piso ambiente de 0,18. A matriz world atual é identidade; não havia transformação incorreta de geometria. | Rotação rígida world→view das normais, sem translação, reflexão ou inversão por câmera; luz principal/fill em espaço de câmera. Resposta limitada a 0,42–1,00. |
| Arestas pouco visíveis sobre sólido escuro | Mesmo pass shaded escuro, linhas escuras e bias de rasterizador sem efeito sobre LINELIST. | Mesmo pass shaded, seguido exclusivamente pelas polilinhas topológicas existentes, contraste claro, LEQUAL, escrita de depth desativada e bias de apenas dois passos representáveis D32 no shader de linha. |
| Wireframe funciona | Pass de linhas com cor direta, sem normais ou iluminação e sem superfície preenchida. | Preservado: cor, polilinhas e profundidade; bias de shader zero nesse modo. Capturas antes/depois idênticas pixel a pixel nas três vistas. |
| Transparência/seleção dominantes | Canvas invertia cada normal em direção ao observador e substituía todo o material por laranja na seleção. Overlay topológico tinha alpha 0,72. | Normais orientadas preservadas; resposta de iluminação limitada; seleção mistura somente 18% de laranja, hover 12%, sem alterar alpha da superfície. Overlay transparente com alpha 0,38. |

O [contrato Direct3D de depth bias](https://learn.microsoft.com/en-us/windows/win32/direct3d11/d3d10-graphics-programming-guide-output-merger-stage-depth-bias)
confirma que o bias de rasterizador não se aplica a primitivas de linha normais.
O deslocamento novo é independente do near/far em quantidade de passos do
formato D32; não desloca geometria, não desliga o teste de profundidade e não
escreve no depth buffer. Não promete hidden-line exato em meshes sem topologia.

Na matriz real, 366.474 cantos têm normais finitas e unitárias. Três cantos de
um único triângulo quase collinear divergem do winding (área aproximada de
0,000424 mm²; fração da área total inferior a 1e-7). Esse desvio localizado é
observável no teste opt-in e não explica a falha global de iluminação. Nenhuma
normal ou triangulação da origem foi forçada ou alterada para ocultá-lo.

### Testes desta correção

- `cad_material_lighting_test`: invariância por rotação rígida comum de normal
  e câmera/luzes; normais orientadas em toda a esfera com iluminação limitada;
  alpha, material e composição de seleção/hover transparente preservados.
- `native_viewport_render_smoke.cpp`: renderer D3D11 produtivo, shaders reais e
  readback de framebuffer em 12 rotações. Arestas mantém o pixel interno igual
  ao Shaded e acrescenta somente contraste limitado às linhas. Wireframe não
  preenche faces. Orientação invertida junto do winding retém somente ambiente,
  sem inversão silenciosa de normais. Executar, após build Windows:
  `powershell -NoProfile -ExecutionPolicy Bypass -File tool/run_native_viewport_render_smoke.ps1 -Configuration Release`.
- `cad_viewport_real_visual_test`: captura opt-in do widget Canvas completo,
  transparência sem/com seleção em superior, inferior e isométrica. Recebe
  somente apresentação geométrica exportada pelo teste do import managed real;
  não é transporte produtivo de STEP pelo Dart e não inclui identidade da
  origem, residência, tokens ou capabilities.
- 74 testes direcionados de material/viewport/navegação/seleção passaram;
  captura Canvas passou antes/depois; teste do controlador com matriz real e
  DLLs Release repetido passou em 21 s. Build Windows Release passou (98 s),
  analyze sem problemas. Formatação e `git diff --check` passaram.

Capturas D3D11 antes/depois usam o host nativo real em framebuffer offscreen,
mesma apresentação importada, câmera e material azul padrão. Capturas Canvas
usam o widget Flutter real. São 15 pares: três modos D3D11 e transparência
sem/com seleção nas três vistas. Nenhuma imagem foi sintetizada. Os renders
foram inspecionados visualmente; não equivalem à aprovação interativa da UI.
Essa conferência final ficou pendente porque o desktop compartilhado tinha
outra aplicação em uso; a instância Release de teste foi encerrada.

### Roteiro manual focado, sem repetir a navegação aprovada

1. Usar `build/windows/x64/runner/Release/flcad_mobile.exe` com DLLs/data do
   bundle; abrir a matriz em projeto de teste, sem editar ou substituir assets.
2. Em Native GPU, escolher Shaded e alternar Top, Bottom e Isometric em Views.
   Conferir azul legível, relevo de furos/curvas e ausência de superfícies pretas
   por orientação. Comparar com os pares correspondentes.
3. Em cada vista, alternar Shaded→Arestas: a superfície deve conservar a mesma
   iluminação; somente arestas CAD finas são adicionadas. Nenhuma diagonal de
   triangulação, preenchimento escuro ou linha oculta atravessando a superfície.
4. Conferir Wireframe nas três vistas: mesma leitura/topologia já aprovada.
5. Em Transparência, selecionar/desselecionar a peça e passar o mouse: interior
   deve continuar visível; seleção é discreta, sem massa opaca ou escura.
6. Registrar aprovação/reprovação de cada vista/modo. Não modificar os controles
   aprovados nem salvar mudanças geométricas para essa conferência.

## Rodada reprovada: Fit, espessura e Mesh Region

Esta rodada substitui a aprovação visual presumida das alterações anteriores.
O Fit era agendado antes de `restoreWorkspace`: a restauração inicial mudava a
pose e invalidava o próprio gate. Um callback único também perdia o pedido se
o viewport ainda não tivesse dimensões válidas.
Mesmo antes disso, o guard de `cad.document` (somente import legado) impedia
todo o caminho em documentos exclusivamente managed. Esse guard foi removido:
o documento publicado do runtime é a autoridade para a prontidão da cena.
O pedido agora permanece pendente após a restauração do controller. A notificação do runtime provoca
rebuild; `ProfessionalCadViewportWidget` confirma layout válido e resize;
`IntegratedCadViewportWidget` aguarda inicialização e publicação da cena no
host antes de entregar o Fit. Sessão, revisão, ticket e pose continuam
revogando operações antigas ou interação posterior. O pedido é consumido uma
única vez e não é emitido por open/Undo/Redo.

Logs de desenvolvimento seguros `[viewport-import-fit]` distinguem publicação
enfileirada e comando entregue; não incluem origem ou identidade nativa.
`cad_viewport_import_delivery_test` suspende inicialização por um Completer,
reconstrói o widget real, confirma snapshot antes de `setCamera` com a câmera
enquadrada, consumo único e preservação da interação posterior. O teste do
controlador STEP real confirma também o evento de publicação pós-importação.
`cad_viewport_real_import_fit_test` importa a matriz pelo controlador dentro
do workspace oficial; confirma `cad.document == null`, o evento managed,
o comando de câmera enviado ao host e um único Fit mesmo após rebuild.
O armazenamento de plugin e de projeto fica isolado em diretório temporário.
Ao capturar o workspace, foi confirmado também que `shouldRepaint` ignorava
`renderMeshes` e `paintBackground`: trocar o backend não pintava o sólido até
outra invalidação. Essas duas comparações foram adicionadas; a captura de
integração exige pixels do material, além do comando de câmera entregue.

Arestas repetia a linha em cinco deslocamentos de tela e o Canvas adicionava
um halo de 2 px. Agora há uma única passagem de linha CAD, com blend alpha
para a cobertura antialiased, bias de dois passos D32 e sem dilatação.
Canvas usa 1 px lógico, sem halo. Quando há seleção, os contornos são
compostos uma única vez após o preenchimento dourado. O smoke D3D11 mede a
largura efetiva incluindo alpha e exige no máximo 1,25 px por contorno.
Wireframe conserva a passagem e os estados anteriores.

O turquesa vinha de `_updateNativeHover` → resolver operacional →
`setOperationalHover`, que preenchia os triângulos de Mesh Region e mostrava
seu tooltip. Esse hover de inspeção agora requer opt-in explícito;
seleção por clique e seleção operacional continuam habilitadas. O teste do
widget real confirma ausência de `setOperationalHover` e de Mesh Region no
modo normal.

As novas capturas offscreen usam a apresentação recém-importada da matriz:
host D3D11 produtivo em Shaded/Arestas/Wireframe e viewport Flutter real após
layout e Fit. A captura Flutter usa a fonte de testes (Ahem); não é captura
da janela desktop nem aprovação manual da UI. A aprovação manual posterior
está registrada no fechamento abaixo.

## Fechamento do baseline aprovado

A validação manual posterior foi aprovada pelo usuário como baseline. Não
foram feitos novos ajustes visuais nesta rodada de fechamento. As capturas
offscreen continuam sendo evidência técnica complementar à aprovação manual.
Os arquivos de captura e de compilação temporária ficam fora do repositório;
somente código, testes reproduzíveis e documentação fazem parte do diff.

### Checks finais do fechamento

- 62 testes Dart de viewport, navegação, Fit, material, adapter e integração
  passaram; os dois testes adicionais do controlador/workspace com a matriz
  real e DLLs Release passaram (64 testes no fechamento).
- 12 CTests Debug e 12 Release passaram em `build/occ_mesh_stream`.
- Smoke do renderer D3D11 produtivo passou em Debug e Release, com 12
  orientações, composição de seleção e largura efetiva limitada a 1,25 px.
- `flutter analyze --no-pub`, verificação de formatação dos 27 arquivos Dart
  e `git diff --check` passaram.
- Builds Windows Debug/Release já passaram na rodada do baseline aprovado;
  nenhum código visual foi alterado no fechamento.
- Leitor de compatibilidade STEP, bridge CAF e contrato documental STEP
  permanecem idênticos a `7a422f7`. Nenhum artefato temporário integra o commit.

### Arquivos do baseline (37)

- `docs/engineering/cad-viewport-quality-diagnosis.md`
- `lib/app/cad_viewport/camera/cad_camera_controller.dart`
- `lib/app/cad_viewport/camera/cad_managed_import_fit.dart`
- `lib/app/cad_viewport/native/integrated_native_viewport_widget.dart`
- `lib/app/cad_viewport/native/native_viewport_bridge.dart`
- `lib/app/cad_viewport/professional_cad_viewport_widget.dart`
- `lib/app/cad_viewport/rendering/cad_canvas_normal_pipeline.dart`
- `lib/app/cad_viewport/rendering/cad_material_lighting.dart`
- `lib/app/desktop/desktop_application.dart`
- `lib/app/navigation/navigation_contracts.dart`
- `lib/app/navigation/navigation_engine.dart`
- `lib/app/navigation/navigation_style.dart`
- `lib/app/runtime/cad_runtime.dart`
- `lib/app/runtime/cad_runtime_transactions.dart`
- `lib/core/cad_kernel/opencascade/native_source_bridge.dart`
- `lib/core/cad_kernel/opencascade/open_cascade_ffi.dart`
- `native/opencascade/include/flcad_occ_api.h`
- `native/opencascade/include/flcad_occ_display_policy.h`
- `native/opencascade/src/flcad_occ_api.cpp`
- `native/opencascade/src/flcad_occ_display_geometry.inc`
- `native/opencascade/tests/mesh_stream_test.cpp`
- `test/cad_managed_import_fit_test.dart`
- `test/cad_material_lighting_test.dart`
- `test/cad_runtime_managed_step_test.dart`
- `test/cad_runtime_managed_stl_test.dart`
- `test/cad_runtime_real_step_test.dart`
- `test/cad_viewport_import_delivery_test.dart`
- `test/cad_viewport_quality_math_test.dart`
- `test/cad_viewport_real_import_fit_test.dart`
- `test/cad_viewport_real_visual_test.dart`
- `test/native_viewport_display_adapter_test.dart`
- `test/native_viewport_render_smoke.cpp`
- `test/navigation_engine_test.dart`
- `test/professional_cad_viewport_test.dart`
- `tool/run_native_viewport_render_smoke.ps1`
- `windows/runner/native_viewport_host.cpp`
- `windows/runner/native_viewport_host.h`
