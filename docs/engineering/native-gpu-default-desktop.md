# Backend CAD padrão no Windows

Base: `5b294aef77bbfd135b90da0e55ef48a30a7ed8b8`. Branch local:
`feat/native-gpu-default-desktop`. Implementação pendente de aprovação visual;
nenhum commit ou push nesta rodada.

## Revisão após reprovação manual

A rodada anterior foi reprovada. Suas capturas e observações abaixo são históricas
e não aprovam a revisão atual. O backend pertence ao viewport inteiro; nunca existe
um backend por entidade. Durante handoff, os dois passes geométricos ficam suspensos;
quando estável, exatamente um prepara/renderiza a cena completa.

| Todas as entidades visíveis | Shaded / Transparência | Arestas / Wireframe |
|---|---|---|
| STEP ou BREP, display válido e arestas CAD | Native GPU | Native GPU |
| STL LOD | Native GPU | Canvas global |
| STEP/BREP + STL LOD | Native GPU para todos | Canvas para todos |
| Referências padrão, WCS, gizmo, ViewCube e demais overlays | Overlay Flutter + Native GPU para CAD | Overlay Flutter + backend elegível do CAD |
| Qualquer geometria visível fora do contrato Native | Canvas para todos, com aviso | Canvas para todos, com aviso |
| Geometria não suportada oculta | Elegibilidade das demais visíveis | Elegibilidade das demais visíveis |
| Falha D3D, ou Canvas explicitamente escolhido | Canvas global | Canvas global |

Elegibilidade é verificada antes da codificação/publicação, inclusive no nível
`brepPresentation`, somente para geometria CAD real. Uma entidade CAD não suportada
impede a carga Native inteira e o aviso identifica sua categoria técnica. Se for
ocultada, a preferência Native pode ser retomada globalmente; uma recuperação por
falha mantém Canvas até escolha explícita. WCS, referências de apresentação, gizmos,
ViewCube, seleção, HUD, avisos e controles são chrome/overlay do viewport: permanecem
visíveis e interativos, mas não entram na elegibilidade nem no payload geométrico.

Defeitos concretos corrigidos nesta revisão:

- O teste de elegibilidade anterior filtrava entidades com `nodes` no nível externo,
  e o adapter também podia omitir entidades/arestas contidas em `brepPresentation`.
- A preparação de histórico managed reinspecionava/reprojetava owners retidos em
  alterações somente de visibilidade. Agora, depois da validação de assets/owners
  existente, reutiliza a cena confirmada quando definição e placement são iguais.
  Só visibilidade/transparência mudam; transformações, restore/open e assets continuam
  pelo fluxo existente. Não há mudança em identidade, importação ou ownership.
- Maps e listas RGB recriados eram tratados como geometria nova. O adapter compara
  identidade dos arrays de apresentação e valores RGB, evitando novo normal pipeline
  e snapshot em Hide/Show. Entidades ocultas ainda não residentes não são carregadas.
- O preflight do payload Native agora valida coordenadas finitas, índices triangulares
  inteiros/dentro de `nodes` e `normals` finitas/alinhadas antes do MethodChannel. O
  campo `triangles` é o index buffer do protocolo. STL managed/LOD válido permanece
  elegível em Shaded; payload inválido cai em Canvas com categoria `malha CAD`, sem
  alcançar o parser/upload D3D11.
- A bridge agora mantém uma publicação e uma entrega de câmera em voo, coalescendo
  estados seguintes antes de codificar. Revision no canal privado recebe ack do host;
  revisions antigas são descartadas sem aplicar nem renderizar. Gerações revogam
  respostas durante troca/shutdown. Não há mudança da ABI FFI.
- O hover Canvas fazia picking/BVH no overlay Native normal; foi desativado nesse
  modo. BVHs de pivot são preservados em Hide/Show/seleção, invalidados quando os
  arrays mudam ou a entidade sai. O callback de navegação agora acompanha o widget
  atual, em vez de capturar o estado inicial sem Native. Seleção Native normal não
  segmenta malhas STEP em regiões; atualiza o mesmo focusPoint que o picking Canvas.

A câmera e o engine/profile de navegação aprovado no baseline `9d246f9c` não foram
alterados. O Professional widget atua como único frontend de input do backend ativo;
com Native, não é um renderer Canvas de modelos. Input fica suspenso durante handoff.

Provas novas: `native_viewport_global_scene_test.dart` cobre STEP, STL LOD e misto,
IDs de toda a cena no host, um Texture/pass ativo, caches Canvas vazios, Hide/Show sem
arrays, seleção, pan sem rotação, orbit, zoom, câmera final entregue, fallback global
antes de qualquer snapshot e gate de visibilidade com ack/coalescência. Regressões
runtime STEP/STL verificam reutilização dos arrays e conservação dos assets/owners.
O smoke D3D Debug/Release verifica dois residentes de cena, Hide/Show mantendo os
mesmos buffers e descarte de revision atrasada sem Render.

Nova validação visual manual ainda não executada/aprovada. Não commitar.

Validação automatizada desta revisão: 380 testes Dart aprovados com as fixtures
nativas e as duas fontes reais habilitadas. O teste STL real confirmou 1.956.958
triângulos originais, 239.878 de display, payload MethodChannel de 14.915.265 bytes,
save/open/Undo/Redo, Hide/Show sem troca dos arrays e pico observado de RSS de
aproximadamente 523 MB. A matriz STEP real confirmou import/Fit por uma cena
managed-only elegível. O smoke D3D11 passou em Debug e Release com o snapshot LOD
real, dois residentes, revisions/Hide/Show, modos, seleção e shutdown. Esses
resultados são gates técnicos; não substituem a nova validação visual solicitada.

## Política e representação

No Windows, a primeira apresentação tenta D3D11 com dimensões finitas e válidas.
Canvas permanece disponível para diagnóstico e recuperação. A escolha explícita
de Canvas persiste durante mudanças de modo no mesmo viewport. Trocar de backend
não reseta o modo, câmera, seleção ou placement.

O host atual desenha arestas topológicas de BREP/STEP. STL sem esse contrato usa
Canvas em Arestas/Wireframe, preservando a apresentação de arestas de malha já
existente, com aviso explícito. Uma mudança explícita para Shaded permite voltar
à preferência Native GPU. Não são inventadas arestas CAD a partir de triângulos.
Transparência nativa usa o protocolo existente `renderStyle=3`, alpha moderado,
blend e profundidade sem escrita. Seleção conserva transparência; Wireframe
destaca contornos selecionados sem preencher superfícies.

Há uma cena canônica de display do runtime, incluindo o LOD transitório já aprovado
para STL denso. Ela não é um segundo backend: seus assets/owners originais seguem
sob o runtime. Somente o backend ativo prepara sua apresentação:

- Native ativo: `renderMeshes=false`; caches de renderização Canvas são drenados.
  O overlay Flutter conserva navegação, Sketch e referências. Picking/pivot usam
  views somente leitura dos arrays canônicos, sem copiar posições/índices; o BVH
  de interação pode ser reutilizado e é invalidado na alteração/remoção da cena.
- Canvas ativo: host desligado, sem buffers de cena, shaders, targets ou polling;
  adapter nativo vazio. Não há snapshot/delta, inclusive em repaint, seleção,
  câmera ou callback antigo. Operações de diagnóstico não reimportam assets.

## Troca, revogação e recuperação

1. Revogar taps/hover e callbacks antigos; suspender preparação de renderização.
2. Drenar inicialização pendente e limpar a apresentação anterior.
3. No host, desassociar contexto e liberar entidades, buffers, targets, picking,
   shaders, estados D3D e device/context.
4. Aguardar o callback assíncrono de unregister Flutter. A variante de textura
   permanece viva até esse callback; seu estado de superfície é independente do
   host e fica inerte antes de sua destruição. Nenhum callback tardio acessa o host.
5. Depois do frame que descarta caches Canvas, inicializar o destino e enviar uma
   carga inicial da representação necessária. Deltas sem mudança são omitidos.
6. Reconciliar cena/câmera alteradas durante a espera antes de liberar apresentação
   e Fit. Geração e identidade da cena impedem entrega tardia de readiness.

O canal pertence à janela. Ownership e drain entre instâncias da bridge impedem
que dispose de um viewport antigo desligue seu sucessor ou que uma nova bridge
inicialize enquanto o unregister anterior ainda estiver pendente.

`GetDeviceRemovedReason` é verificado em renderização e no health check periódico,
também em Release. Erros do host/canal revogam disponibilidade e iniciam cleanup
antes de preparar Canvas. O usuário recebe estado genérico de recuperação/Canvas
ativo, sem pathname, token ou capability. Isso não desfaz nem modifica documento,
histórico, seleção documental, placement, assets ou ownership managed.

## Garantias e provas

| Fronteira | Prova |
|---|---|
| Inicialização/padrão, carga única, backend inativo | `native_viewport_backend_policy_test.dart`: default Windows, round trip, contagem de chamadas, adapter vazio e cache Canvas vazio |
| Dispose antigo versus sucessor | Mesmo teste: gate de unregister entre duas bridges e dispose inativo sem shutdown do sucessor |
| Cancelamento/substituição/shutdown de backend | Mesmo teste: inicialização suspensa, troca para Canvas, shutdown, ausência de snapshot tardio |
| Interação durante inicialização | Mesmo teste: gate de setCamera e atualização de orientação sem sobrescrita tardia |
| Falha D3D/canal | Mesmo teste: erro específico injetado, shutdown antes de Canvas, cena/modo preservados |
| Picking/pivot sem segunda cópia geométrica | Mesmo teste: arrays emprestados, mesmos resultados de hit e zero buffers geométricos copiados |
| Textura assíncrona e recursos D3D | `native_viewport_render_smoke.cpp`: registrar com gate, callback após destruição do host, variantes vivas até unregister, três ciclos completos de liberação/reinicialização |
| Shaded/Arestas/Wireframe/seleção/transparência | Smoke D3D real Debug/Release e regressões `professional_cad_viewport_test.dart`, `integrated_native_viewport_selection_test.dart`, `cad_viewport_quality_math_test.dart` |
| LOD real e assets/lifecycle | `cad_runtime_dense_stl_test.dart`: comando managed, 1.956.958 → 239.878 triângulos, hashes, placement, save/open e Undo/Redo; snapshot real no smoke D3D |
| Fit e STEP real | `cad_viewport_real_import_fit_test.dart`: publicação managed pela workspace real, Professional viewport e comando de câmera entregue ao host |
| Fundação managed | Regressões STEP/BREP/STL, placement, transações, staging, custody, CAF e source bridge; CTest OCCT/bridge |

Os testes Dart simulam o canal; o smoke separado usa codec/upload/D3D real. Nenhum
desses testes isoladamente constitui aprovação visual manual da UI.

## Evidências e limites da rodada

Validação automatizada da rodada anterior: 374 testes Dart aprovados, com fixtures nativas
Release e fontes reais habilitadas (`--timeout=2m --concurrency=2`). A política
inclui nove testes novos. CTest: 12 testes OCCT e 2 da bridge C→C aprovados em
cada configuração Debug e Release. Smoke D3D11 Debug/Release aprovado com o
snapshot LOD real, seleção Wireframe sem preenchimento, transparência, registrar
assíncrono com gate e três ciclos de shutdown/reinicialização. O teste de
lifecycle do STL real registrou pico de RSS de aproximadamente 551 MB; isso é
uma amostra do processo de teste, não um limite de memória da aplicação.

Foi observado um encerramento inicial Release ao entrar por Novo Projeto, antes
de importar: working set aproximadamente 3,5 GB, `c0000409`, fast-fail 7. O dump
externo mostra terminate durante decoding de MethodChannel no wrapper C++, não
evidência de falha D3D atribuível ao driver. A causa desse episódio não foi
determinada; não é atribuída ao problema de unregister, nem declarada corrigida.

Em execuções posteriores recompiladas, a UI Debug apresentou o STL real e fez
Canvas → Native; working set observado aproximadamente 620 MB. Release apresentou
o STL real já enquadrado e fez Native → Canvas, preservando câmera, em torno de
410–500 MB nessa sequência. A matriz STEP real também foi carregada na UI.
Essas amostras não são medição de VRAM nem limite garantido de memória.

Na sequência final Release, Novo Projeto abriu com Native ativo; a matriz STEP
foi importada com Fit e apresentada em Shaded, Arestas, Wireframe e Transparência.
STEP e depois STL real foram apresentados em um projeto de teste, com round trip
Native → Canvas → Native mantendo enquadramento/seleção. O LOD exibiu as contagens
1.956.958 → 239.878; Arestas acionou Canvas com aviso e Shaded retomou Native.
Uma segunda importação STL foi cancelada pela UI sem remover a cena anterior.
Working set observado nessa sequência mista: aproximadamente 521–649 MB; memória
privada aproximadamente 547–708 MB em amostras distintas. Não há medição separada
de VRAM nessa sequência, nem alegação de equivalência visual perfeita entre os
renderers. Capturas ficaram fora do repositório. Aprovação visual do usuário
continua pendente, incluindo placement e navegação de forma abrangente.

Builds Windows Debug/Release aprovados, `flutter analyze --no-pub` limpo,
formatação Dart e `git diff --check` sem erros. A revisão de escopo/lifecycle
mantém as mudanças nas quatro classes do viewport, host privado runner, testes e
este documento; nenhum artefato temporário novo está no diff versionável.

O pico histórico de aproximadamente 5,7 GiB documentado no trabalho de LOD continua
sem explicação atribuída. A política remove coexistência de caches próprios dos
backends; não afirma explicar esse pico. Recursos de frame em trânsito no engine
Flutter/driver podem sobreviver à liberação das referências da aplicação; não são
uma segunda cena persistente preparada pelo backend inativo.

Remoção física de dispositivo/TDR não é provocada deliberadamente. O caminho de
recuperação é validado por erro específico e gates; falha fatal do engine/processo
fora do retorno de erro do host não pode ser recuperada por uma bridge Dart.
O episódio inicial permanece um item de investigação antes de aprovação final.

## Roteiro visual final

1. Abrir um projeto de teste vazio no Release novo: Native GPU ativo quando D3D
   inicializar. Importar a matriz STEP real; conferir Fit e as quatro apresentações,
   seleção, pan/orbit/zoom e placement numérico sem mudança de geometria original.
2. Em outro projeto de teste, importar o STL real: aviso com contagens original/LOD,
   apresentação e navegação sem queda; medição/região continuam indisponíveis no LOD.
3. Fazer Native → Canvas → Native em Shaded e Transparência; conferir câmera,
   seleção e placement. Para Arestas/Wireframe STL ou misto sem topologia CAD,
   conferir fallback de modo explícito e retorno a Native ao escolher Shaded.
4. Repetir Undo/Redo e save/close/open. Cancelar uma importação e fechar durante
   carregamento. Documento e assets devem permanecer íntegros.
5. Repetir entrada por Novo Projeto, investigando o episódio inicial caso reapareça.
   Não aprovar nem commitar enquanto houver queda ou regressão visual.

Não há mudanças em CAF, assets, bridges source/C→C, custody managed, importadores,
compatibilidade STEP, schema/persistência G-105A1, ABI FFI ou pipeline legado.
