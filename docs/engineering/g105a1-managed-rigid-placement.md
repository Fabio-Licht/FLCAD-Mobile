# G-105A1 — Placement rígido managed

Implementação sobre `4ed5ed9`, na branch `feat/g105a-transform-alignment`.
STEP, BREP e STL recebem placement não destrutivo. Não há escala, gizmo,
alinhamento por referências, transformação de BREP pelo kernel ou exportação
transformada. ABI, CAF, compatibilidade STEP e controles do viewport não mudam.

## Contrato

`CadDocument` grava versão 2 e lê versões inteiras 1/2; versão 1 representa
placement ausente/identidade e não aceita placement embutido. Versões
desconhecidas são rejeitadas. Nenhuma migração transforma coordenadas legadas
ou converte `transformMatrix` já aplicado.

Entidade import managed tem campo top-level opcional `placement`, independente
dos dois assets BREP, único asset STL ou três assets STEP. Não pode coexistir
com handles documentais ou `transformMatrix`/`alignmentMatrix` legados.
O objeto tem exatamente estes campos:

```json
{
  "schema": "flcad.entity-placement",
  "version": 1,
  "frameUnit": "mm",
  "space": "world",
  "pivotLocal": [0, 0, 0],
  "operations": [{"kind": "translate", "values": [10, 0, 0]}]
}
```

Operações aceitas: `translate` com três valores em mm; `rotate` com quaternion
normalizado `[x,y,z,w]`. UI/API recebe graus e converte uma vez ao quaternion
durável. Não há matriz redundante persistida, token, pointer, capability,
pathname ou fingerprint de residência nesse contrato. Stack máxima: 256
operações. Componentes de translação/pivot e matriz composta limitados a 1e9;
entrada angular da API limitada a ±360000 graus. Não finitos, quaternion
nulo/não normalizado, schema/campos desconhecidos e operações não rígidas
são erros específicos de formato. Matriz derivada deve ser afim, ortonormal,
destro, determinante +1; singularidade, escala e reflexão são rejeitadas.

## Composição e pivot

Row-major, ponto coluna: `pWorld = M × pLocal`. Delta de mundo pré-multiplica
`Mnext = Dworld × M`. Um comando aplica translação, depois rotações sobre X,
Y e Z de mundo, nessa ordem. Rotação usa `T(pWorld) × R × T(-pWorld)`.
Pivot é o centro do AABB **original da mesh managed** em coordenadas locais,
capturado no primeiro comando e persistido. É convertido pela matriz vigente
antes de cada rotação; acompanha a peça depois da translação. Assim mover a
peça e rotacioná-la não orbita acidentalmente em torno da origem global.
O exemplo do inventário sobre rotação em torno da origem de mundo exige pivot
fixo de mundo; não descreve esse default local. Edição de pivot/local-space
fica para fase posterior.

STEP já tem geometria canônica mm; nome/unidade declarada/cor do manifest não
mudam. STL/BREP direto mantém a interpretação atual das coordenadas de cena;
transladar em mm não inventa unidade de origem nem redimensiona assets.

## Runtime, apresentação e lifecycle

`CadRuntime.transformManagedEntity(id, translateX/Y/Z, rotateX/Y/Z)` e
`resetManagedPlacement(id)` são comandos públicos enfileirados uma única vez.
Alvo deve estar ativo e retido como managed, em coleção desbloqueada. Comando
sem incrementos não cria revisão nem limpa Redo. Uma confirmação numérica é
um item de histórico. O fluxo antigo `applyEntityTransform` rejeita alvos
managed, evitando transformação destrutiva/legada implícita.

Preparação managed gera coordenadas locais pelos recursos existentes, projeta
cópias de nodes, bounds (oito cantos), normais e arestas topológicas, inclusive
`brepPresentation`. Para matriz rígida a inversa transposta das normais é a
própria rotação; translação não participa. Não muda winding ou intensidade de
cor. Canvas e host native recebem essa mesma apresentação preparada.

STEP retido mantém `rootLinearRgb` e compatibilidade; open restaura manifest
validado. Conversão de cor para sRGB continua no adaptador existente, uma vez.
Cena/seleção/retenção/histórico seguem publicação transacional já existente.
Assets iguais reutilizam os owners; não há novo recurso nativo de placement.
Undo/Redo restaura stack sem reimportar origem ou aplicar o delta duas vezes.
Save/open valida documento e histórico, prepara todos os assets antes de
publicar. Falha pré-commit mantém estado anterior; recovery pós-commit segue
o contrato atual, sem ampliar crash-atomicidade dos dois JSONs.

Close/open substituto/shutdown revogam preparação suspensa. Close mantém
visual → retenção → dispose; leases e quarentena continuam na custody atual.
Shutdown pode manter o documento confirmado para leitura, sem publicar o
placement revogado. Clones documentais de snapshots, lifecycle e operações
de coleção preservam placement.

## UI e roteiro manual

No painel Transform, uma única entidade managed selecionada apresenta seis
incrementos: ΔX/ΔY/ΔZ em mm e RX/RY/RZ em graus. Confirmar grava placement;
Restaurar posição original grava reset reversível. Campos zeram após sucesso,
ficam bloqueados durante confirmação e exibem erro público seguro. Seleção
mista exige escolher uma entidade; não há oferta de escala ou kernel apply.

1. Importar STEP colorido, BREP e STL; selecionar um de cada vez no Explorer.
2. Abrir Transform; aplicar ΔX=10 e RZ=90; conferir movimento e rotação sobre
   centro original, cor, Shaded/Arestas/Wireframe e seleção.
3. Undo/Redo repetidos; conferir que só a entidade correta muda.
4. Salvar, fechar e abrir; conferir pose/cor; Undo/Redo e reset novamente.
5. Testar NaN/texto inválido e coleção bloqueada: nenhuma mudança publicada.

Não foi realizada aprovação visual manual nova nesta tarefa; o roteiro é
para validação do comportamento novo, sem declarar revisão do baseline.
Exportação managed transformada e medição topológica na pose world permanecem
fora do escopo: este placement não concede acesso de kernel nem promete essas
operações. Ferramentas antigas de inspeção podem operar em coordenadas locais;
não usá-las como prova metrológica de placement.

## Provas automatizadas e revisão

`entity_placement_test.dart`: composição/pivot, ordem não comutativa, roundtrip,
imutabilidade, limites, schema, não finitos, matriz singular e projeção de
normais/arestas/bounds sem alteração da origem.

`cad_runtime_managed_placement_test.dart`: fixtures nativas reais STEP/BREP/STL,
owners/leases, cor, apresentação para host, Undo/Redo repetidos, save/close/open,
histórico misto com legado, hashes/tamanhos íntegros, falha de persistência,
revogação determinística por close/open/shutdown, schema inválido em documento
e histórico. Testes de integração usam as DLLs
instrumentadas existentes recompiladas, não fallback por pathname.

`managed_placement_editor_test.dart`: contrato da UI com runtime instrumentado,
despacho de mm/graus para o alvo correto, bloqueio de NaN, confirmação única,
campos bloqueados durante comando suspenso e reset. Usa Completer, sem delay
como prova. O runtime real é exercitado separadamente pela suíte integrada.

Ambiente integrado: OCC instrumentado em `build/occ_mesh_stream/Release`, CAF
em `build/cad_asset_fs/Release`, bridge em `build/windows/x64/runner/Release`.
Fixtures: `cad_occ_bridge_smoke.exe` e `flcad_occ_step_bridge_smoke.exe`.
Uma primeira execução identificou DLLs de testes locais desatualizadas;
recompilar OCC e apontar a bridge para a Release compatível restabeleceu os
símbolos de apresentação, contadores e o limite de linha STEP existente.
Nenhum código de compatibilidade ou SDK foi alterado para isso.

Revisão de ownership/lifecycle: placement não adquire autoridade de origem,
não promove assets, não cria shape/mesh, não chama kernel transform, não
readquire a fila e não altera retenção de assets idênticos. Preparação precede
persistência; revogação é validada antes de publicação. Preservação explícita
de placement nas normalizações e clones evita perda silenciosa em histórico.

## Checks finais

- 188 testes Dart: placement/matemática, editor numérico, transações,
  integridade referencial, writers, viewport, adaptador, iluminação e navegação.
- 150 regressões Dart managed STEP/BREP/STL e custody.
- 10 testes novos de integração managed placement, incluindo reset e
  descritores de residência estáveis durante Undo/Redo (348 casos únicos).
- `cmake --build build/occ_mesh_stream --config Release`: alvo de testes
  recompilado com sucesso; nenhum arquivo nativo/SDK alterado.
- `ctest --test-dir build/occ_mesh_stream -C Release --output-on-failure`:
  12/12 passaram, incluindo source, STEP, BREP, mesh e C ABI.
- `flutter analyze --no-pub`: nenhuma issue.
- `dart format --output=none --set-exit-if-changed`: 13 arquivos Dart,
  zero mudanças pendentes.
- `git diff --check`: passou; diff nativo/CAF/compatibilidade STEP vazio;
  apenas os arquivos desta implementação/documentação/testes no worktree.

Não houve build novo do executável UI Windows nem smoke visual manual nesta
entrega. A compilação/análise Dart e as integrações com DLLs validam os
contratos automatizados; o roteiro acima não foi declarado aprovado.
