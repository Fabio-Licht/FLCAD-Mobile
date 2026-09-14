# STL denso: orçamento de apresentação transitória

## Fronteira e contrato

O STL binário de reprodução tem 97.847.984 bytes, 1.956.958 triângulos e
980.120 vértices únicos. A admissão CAF e a publicação managed funcionavam;
a apresentação expandia cada face em três vértices antes do MethodChannel,
atingindo aproximadamente 1,71 GiB de RSS. O evento Windows era um fast-fail;
não há dump que identifique a instrução exata de alocação.

Somente STL managed mesh-only excedendo 125.000 vértices ou 250.000 triângulos
usa a rota nova. STEP/BREP, normais, tesselação e controles existentes permanecem
na rota anterior. A chamada de display já exportada recebe o token de mesh sob
o mesmo lease de custody; símbolos e assinaturas C não mudam. Nenhum token faz
parte do resultado de apresentação ou da identidade documental.

Antes de copiar os arrays originais por FFI, C++ prepara uma representação
indexada limitada. O asset CAF completo permanece a autoridade para open/Redo.
O LOD nunca é promovido, salvo no documento/journal ou usado como substituto
do asset. Cada restauração o recalcula determinísticamente. Placement transforma
a cena preparada pelo mecanismo existente, sem modificar a origem.

## Política explícita

| Recurso | Limite |
| --- | ---: |
| Fonte admitida pelo parser existente | 1.000.000 vértices / 2.000.000 triângulos |
| LOD indexado | 125.000 vértices / 250.000 triângulos |
| JSON nativo e buffer FFI da rota LOD | 24 MiB |
| Envelope conservador adicional de preparação C++ | 128 MiB |
| Alocador dos containers de clustering | 32 MiB, verificado antes de alocar |
| Canvas fallback | até 750.000 corners, chunks de 20.000 triângulos |
| Buffers D3D de geometria | até 2,87 MiB de vértices + 2,87 MiB de índices |

O envelope C++ descreve remap, containers limitados, normais e serialização;
não é uma quota de RSS do processo nem inclui o mesh original, engine Flutter,
driver ou cena com múltiplas entidades. Os limites de containers são verificados
durante construção; o tamanho serializado é verificado antes da cópia FFI.
Não há reconstrução proporcional aos milhões de corners originais.
Um memory_resource limita efetivamente as alocações das árvores, sem reservar
32 MiB antecipadamente. Static assertions conferem os envelopes separados de
clustering e serialização; os containers são liberados antes da serialização.

## Redução

`spatial-clustering-v1` agrupa vértices em células de tamanho inicial
diagonal/512, usando o primeiro ponto original de cada célula. Os seis extremos
reais são preservados; bounds locais e enquadramento não diminuem.
Percorre todos os triângulos, remapeia seus índices, descarta degenerados e
deduplica ciclos orientados. Se qualquer orçamento é excedido, descarta a
tentativa inteira e repete com células maiores, até doze tentativas.
Falha explícita se não houver representação completa não vazia no orçamento.
Não publica um prefixo truncado de triângulos.

As normais de apresentação derivam do winding dos triângulos reduzidos, com
média ponderada por área. O renderer GPU recebe vértices indexados sem passar
pela expansão do CadCanvasNormalPipeline. O Canvas usa a representação limitada
e suas normais, mantendo os chunks Uint16 existentes.

Clustering é aproximação visual: não garante erro Hausdorff, topologia original,
pequenos furos ou detalhe abaixo da célula. Extremos preservados podem ficar sem
faces incidentes. Essas limitações exigem inspeção visual do caso real e impedem
alegação de precisão geométrica sobre o LOD.

## UI e ferramentas

A cena carrega metadata transitória versionada `presentationLod`, com contagens
originais/de exibição, método e `measurementSafe: false`. O viewport mostra
“Visualização simplificada” e as contagens, sem pathname ou autoridade nativa.
A seleção continua no ID documental da entidade. Resolução operacional oferece
somente seleção; não segmenta/registra regiões do LOD. Picking Canvas não devolve
índice de triângulo como identidade original. Reconhecimento/medição de região
rejeita explicitamente esta representação. Não existe ferramenta de medição
precisa nova ou cópia integral por Dart para contornar essa restrição.

Preflight Dart verifica comprimentos e protocolo antes de normais/codec;
o host repete limites/índices antes de reservar posições e fazer upload D3D.

## Matriz de evidências

| Garantia | Prova |
| --- | --- |
| Preflight não lê arrays integrais | `stl_display_lod_test.dart`: ListBase que falha em qualquer acesso |
| Determinismo, bounds, winding, containers limitados | `mesh_stream_test.cpp`: grid acima da quota, duas serializações iguais, extremos e normais |
| Sem expansão antes do GPU codec | `stl_display_lod_test.dart`: listas indexadas compartilhadas no snapshot |
| Fonte/asset completos e sem metadata transitória persistida | `cad_runtime_dense_stl_test.dart`: SHA-256/tamanho antes/depois e documento |
| Undo/Redo, save/open, placement e custody | mesmo teste integrado, duas restaurações e owners/leases zero no encerramento |
| D3D11 Debug/Release e fixture real | `native_viewport_render_smoke.cpp`: snapshot StandardMessageCodec, upload e pixels visíveis |
| Sem regressão nas rotas anteriores | testes managed STL/BREP/STEP/placement, runtime, custody, source bridge e viewport |

O teste integrado aceita `FLCAD_DENSE_STL_SOURCE` para o caso real e
`FLCAD_DENSE_STL_SNAPSHOT` para gerar somente dados de apresentação limitados
fora do repositório. O hash de teste lê o arquivo para conferência; não transporta
bytes de importação ao runtime. Capturas offscreen não substituem aprovação da
UI Windows Release.

## Roteiro manual Release

1. Abrir projeto vazio e importar o STL real pela UI managed. Conferir ausência
   de queda e Fit, contagem original 1.956.958 e aviso de simplificação.
2. Inspecionar forma/bounds em Shaded, Wireframe, Arestas e transparência;
   navegar sem mudanças de controles. Selecionar a entidade e editar placement.
3. Confirmar que região/medição não oferece precisão do asset completo.
4. Undo/Redo duas vezes; salvar, fechar e reabrir. Conferir forma, placement,
   contagens e ausência de duplicação.
5. Conferir hashes/tamanhos da origem e asset antes/depois. Registrar somente
   fase, contagens e memória aproximada, sem paths ou identificadores nativos.

Commit condicionado à conclusão dos checks e da validação manual Release.

## Resultados automatizados e revisão

No arquivo real, o LOD final tem 118.281 vértices e 239.878 triângulos.
O teste integrado percorreu import → dois Undo/Redo → placement → save/close/open,
validou o cabeçalho e tamanho do asset binário completo, hashes da origem/asset,
IDs/documento e owners/leases drenados no shutdown. RSS na preparação foi
aproximadamente 275 MiB; pico de aproximadamente 428 MiB no lifecycle completo.
Esses valores pertencem ao processo Flutter de teste, não são uma medição da
UI Release nem uma garantia global de memória.

Builds Windows Debug e Release, CTest OCCT 12/12 em ambas as configurações,
smoke offscreen D3D11 com o snapshot real em ambas as configurações,
analyze e formatação/diff-check passaram. O smoke executa codec, host,
upload de buffers e renderização com pixels visíveis; a captura tem somente
geometria de apresentação, sem identidade da fonte.

Regressões STEP passaram (62 testes). A primeira execução de descoberta usou
uma DLL de bridge de teste anterior ao limite STEP commitado; reconstruí-la
resolveu a falha sem alterar STEP. Sob concorrência, uma regressão BREP de
placement excedeu o timeout padrão de 30 segundos; repetida isoladamente com
timeout CLI de dois minutos, passou em 31 segundos. Nenhuma assertion foi
ignorada e nenhum teste existente foi modificado para ocultar a falha.

Revisão somente leitura de lifecycle/ownership: o LOD não cria owner, não move
custody e mantém o lease até o retorno da preparação. As transações verificam
os counts originais do descritor e os counts limitados da apresentação,
mantendo a verificação exata antiga para BREP/STEP/STL pequeno. As mesmas
fronteiras de revogação e publicação permanecem ativas.

Revisão somente leitura de escopo/precisão: a rota não usa filesystem/source
pathname, não persiste metadata transitória e não modifica a ABI. Containers,
serialização e host têm guardas antes das alocações relevantes. Seleção e
placement usam a entidade original; regiões do LOD não são identidades CAD
precisas. Não foram alterados controles, compatibilidade STEP, esquema de
placement ou assets duráveis.

## Correção da ligação do comando STL

O diagnóstico posterior de crash comprovou que `import.stl` ainda chamava
`pickAndImport`/`registerImport`: o preflight managed não participava dessa
rota. O dump mostrou `std::bad_alloc` não tratada na cópia de uma lista de
17.612.622 `EncodableValue` (72 bytes cada), durante o decode do MethodChannel,
antes de `ApplySnapshot`/upload D3D. Guardas do host não protegem o decoder.
O fast-fail 7 não comprovou corrupção de memória ou watchdog como causa.

O comando agora chama `pickAndImportManagedStl`, que admite a fonte somente
por `runtime.importManagedStl`. A entrada genérica também delega STL à mesma
rota. CAF, bridge C→C, staging, custody, seleção e publicação de Fit são
reutilizados. Cancelamento explícito revoga a transação antes do commit;
close/dispose também cancelam a operação UI suspensa. Não há fallback legado.

O teste `cad_runtime_dense_stl_test.dart` executa o comando público real com
picker controlado e bridge de integração explicitamente localizada (o teste
Flutter não executa junto das DLLs da aplicação). A entrada genérica lança
erro se invocada; a entidade precisa ter `managedStlAssets`, sem `activeImport`
ou registro legado. O teste verifica seleção/evento de Fit, cancelamento,
falha de admissão, entrega pelo MethodChannel, Undo/Redo, save/open, hashes e
owners. No arquivo real: 239.878 triângulos, 118.281 vértices e MethodCall de
14.915.265 bytes. O host do teste Dart é simulado; os testes D3D separados
exercitam codec/upload/render. Isso não substitui a validação manual da UI.

As 28 regressões managed STL passaram, incluindo cancelamento determinístico
antes da promoção com owners/leases drenados. A validação manual do STL real
de 93 MB foi aprovada: importação, apresentação e navegação concluíram sem
queda.

Em uma reprodução anterior, a coexistência Canvas/Native GPU apresentou um
intervalo de “não respondendo” e working set observado de 6.154.981.376 bytes.
O diagnóstico externo confirmou coexistência de caches e recursos, mas não
atribuiu nem reproduziu esse pico histórico. Isso permanece uma melhoria
futura de perfil de memória; nenhuma correção D3D/driver foi incluída neste
trabalho.
