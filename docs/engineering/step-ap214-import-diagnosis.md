# STEP AP214: diagnóstico e compatibilidade nativa v1

## Evidência e nova decisão de produto

A origem real tem 12.353.968 bytes e uma linha física de 938.585 bytes. Contém
um PRODUCT, um PRODUCT_DEFINITION, um MANIFOLD_SOLID_BREP e nenhuma relação de
assembly. O arquivo privado e seu locator não fazem parte do repositório.

ISO 10303-21 §12.2.5.3 exige ordem crescente pelos nomes dos componentes no
external mapping. A unidade observada tem NAMED_UNIT, SOLID_ANGLE_UNIT, SI_UNIT;
também usa referência em dimensions, redefinido como derivado por si_unit
(§12.2.6 exige `*`). A origem é não conforme. A hipótese anterior de bug do SDK
foi retificada; a nova decisão de produto é recuperar esta assinatura conhecida.

Fontes primárias:

- [ISO 10303-21 publicado pelo editor STEP Tools](https://www.steptools.com/stds/step/IS_final_p21e3.html)
- [Schema si_unit](https://www.steptools.com/stds/stp_aim/html/t_si_unit.html)
- [OCCT 8.0.1 RWSiUnitAndSolidAngleUnit::ReadStep](https://github.com/Open-Cascade-SAS/OCCT/blob/V8_0_1/src/DataExchange/TKDESTEP/RWStepBasic/RWStepBasic_RWSiUnitAndSolidAngleUnit.cxx)
- [OCCT NamedForComplex e CheckDerived](https://github.com/Open-Cascade-SAS/OCCT/blob/V8_0_1/src/DataExchange/TKDESTEP/StepData/StepData_StepReaderData.cxx)

NextForComplex encontra SOLID_ANGLE_UNIT(), mas CheckNbParams espera os dois
parâmetros de SI_UNIT. A falha precisa é `Count of Parameters is not 2 for si_unit`.
O atributo derivado incompatível gera warning. O reader é idêntico no tag V8_0_1
e no master consultado 3d097a0328e71b826377d4814ab05ec3c3d23871, blob
28d91585e1c22a36b0ea20714ba2b567df4515c3. O SDK OCCT 8.0.1 permanece intacto.

## Alteração independente: limite físico de linha

O perfil C→C STEP passou de 16 KiB para 1 MiB por linha. O lexer percorre a
linha sem acumulá-la. Os limites de input, transporte, token, nesting e
topologia continuam ativos; o perfil STL não mudou. Essa alteração não é uma
normalização e não aparece na lista de compatibilidade.

## Regra nativa fechada

1. Enquadrar e tentar ReadStream estrito na origem admitida pelo CAF primeiro.
2. Só considerar retry quando ModelCheckList contém exatamente uma entidade
   com falha, do tipo exato StepBasic_SiUnitAndSolidAngleUnit, com uma única
   falha e a mensagem fixa de contagem acima. ReadStream malsucedido, falhas
   adicionais e outros tipos não recebem recuperação.
3. Ler o mesmo source capability para memória C++ (máximo 64 MiB nesta regra).
   O CAF confere novamente o SHA-256 original contra a identidade selada.
4. Usar StepLex e parser de registros/componentes com offsets de tokens.
   Strings com aspas duplicadas, comentários e listas aninhadas não são
   interpretados por busca/replace textual. Limites e polls continuam ativos.
5. Localizar pelo label reportado pelo OCCT. Exigir exatamente NAMED_UNIT(reference),
   SOLID_ANGLE_UNIT(), SI_UNIT($,.STERADIAN.), nessa ordem. A referência deve
   resolver para DIMENSIONAL_EXPONENTS com sete números iguais a zero. Ausência,
   componentes extras/duplicados, outros prefixos/enums ou dimensões não zero
   não são recuperáveis.
6. Fazer splice somente do span analisado para
   `(NAMED_UNIT(*) SI_UNIT($,.STERADIAN.) SOLID_ANGLE_UNIT())`. Preservar todos os
   demais bytes. Não escrever a origem.
7. Repetir enquadramento e ReadStream com reader/work session novos, revalidar
   CAF e exigir os gates existentes de modelo, transfer, BREP, unidade, produto
   único, solid único, aparência e referências externas. Não há terceiro retry
   nem descarte de erros residuais.
8. Conferir a origem pelo CAF também no gate final anterior à publicação nativa.

Não há transporte da origem pelo Dart, pathname temporário, ReadFile(path),
alteração do SDK ou pipeline legado. Assemblies, múltiplos produtos, referências
externas, cores por corpo/face e transparência permanecem fora do escopo.

## Persistência, UI e lifecycle

Manifestos estritos continuam com schema flcad.step-appearance/version 1.
Aplicação da regra gera version 2, acrescentando apenas compatibility:

```json
{
  "compatibility": {
    "version": 1,
    "sourceSha256": "<SHA-256 hexadecimal da origem admitida e verificada>",
    "normalizations": [
      {"rule": "si-unit-solid-angle-order", "version": 1},
      {"rule": "si-unit-solid-angle-derived", "version": 1}
    ]
  }
}
```

O payload real exige 64 dígitos hexadecimais, não o placeholder ilustrativo.
Schema, versões, campos, hash e lista ordenada são validados; regras desconhecidas
ou repetidas são rejeitadas. Nome, escala e cor linear mantêm o contrato anterior.
Nenhum locator, token, capability ou identidade de residência é acrescentado.

O layout C é preservado: metadata.version 1/reserved 0 identifica leitura estrita;
metadata.version 2/reserved 3 comunica o conjunto fechado de regras v1. Combinações
desconhecidas são rejeitadas. Não há novo pointer ou buffer de origem na ABI.
O Dart constrói o manifesto apenas dos metadados e do hash CAF admitido.

A cena expõe stepCompatibility=true a partir do manifesto validado. Import,
open, Redo e entidade retida preservam o estado. O controlador mostra aviso
explícito de compatibilidade, das duas normalizações e de preservação da origem.
A mensagem pública de falha continua genérica; diagnósticos Debug usam categorias
fechadas e status, nunca mensagens arbitrárias, paths ou identidades privadas.

## Alteração independente: admissão Windows da raiz do projeto

O armazenamento combina separadores `/` e `\`. Após superar a falha STEP, o
projeto real de teste encontrou CAF_ARGUMENT ao admitir sua raiz. O gateway
converte somente separadores antes do CAF; não resolve `..`, não relaxa política
e não utiliza pathname para readquirir autoridade. A correção tem testes próprios.

## Matriz de testes e smoke

| Garantia | Prova |
|---|---|
| Estrito primeiro, retry único | step_source_test: duas ReadStream na fixture recuperável |
| Linha próxima/acima de 1 MiB | runtime modes 7/8: sucesso/rejeição específica |
| Ordem inválida sem assinatura derivada | mode 9: rejeição específica |
| Assinatura recuperável fiel | mode 10: unidade/cor, três assets, hash e manifesto v2 |
| Dimensões não zero/ausentes, componente extra, enum inválido, erro adicional | modes 11–15 e step_source_test: sem publicação/owners |
| Revogação antes do retry | step_source_test: check(1) cancelado, apenas uma ReadStream |
| Save/open/Undo/Redo e entidade retida | mode 10 e retained compatible STEP: aviso, cor, hashes e owners |
| Diagnósticos e manifesto seguros | cad_step_diagnostics_test e managed_step_contract_test |
| Admissão Windows | cad_asset_fs_gateway_test: raiz equivalente e staging com separadores mistos |
| Arquivo real | cad_runtime_real_step_test: controlador, runtime produtivo, aviso, manifesto e owners |

O teste real é opt-in via FLCAD_REAL_STEP_SOURCE e FLCAD_REAL_STEP_SHA256
(baseline calculado externamente, por Get-FileHash), com timeout computacional de
10 minutos, sem delays como prova. Só picker e configuração das DLLs de teste
são injetados. O projeto descartável não é uma cópia temporária da origem.
Suítes instrumentadas usam DLLs Debug com símbolos de contagem. O bundle Release
é verificado por testes que não exigem esses símbolos.

Smoke visual manual no aplicativo normal Windows Release: criar/abrir projeto,
selecionar a matriz privada pela UI, conferir peça e aviso, salvar/fechar/abrir,
Undo/Redo e fechar. Conferir externamente tamanho e SHA-256 antes e depois.
O controlador automatizado não substitui inspeção visual manual do viewport.

## Validação executada nesta alteração

- Lote Dart STEP/BREP/STL/source bridge, contrato, comando, CAF/staging/custody,
  runtime/transações/escritores/integridade referencial: 381 testes passaram.
- Após o ajuste final da entidade retida: 4 testes direcionados passaram.
- Matriz real pelo controlador: passou com DLLs Debug e DLLs empacotadas Release,
  comparando o hash do manifesto com baseline externo. SHA-256 da origem
  permaneceu igual ao baseline anterior à tarefa.
- CTest Debug source/STEP/ABI/C→C: 4 testes; bridge/falhas: 2 testes, passaram.
- CTest Windows Release OpenCascade: 12 testes passaram, incluindo compatibilidade
  e rejeições nativas. Build Windows Release e smoke CAF do aplicativo passaram.
- Analyze, formatação e diff-check passaram. TKDESTEP.dll do bundle é idêntica
  à DLL do SDK configurado. Nenhum patch do SDK foi aplicado.
- Inspeção visual manual do viewport com a matriz: **não aprovada**. Foram
  confirmadas facetas radiais visíveis, overlay de arestas confuso/espesso,
  pan que gira a peça, orbit impreciso e saltos excessivos no zoom por roda.
  Esses achados exigem uma tarefa isolada de viewport; não constituem aprovação
  visual deste commit de compatibilidade e não são corrigidos nesta alteração.

As tentativas intermediárias de smoke real identificaram a admissão Windows
com separadores mistos e a configuração incompleta das DLLs no harness; foram
corrigidas e repetidas. Não são relatadas como importações bem-sucedidas.
O primeiro lote amplo tinha erro de compilação no teste novo de Undo/Redo;
o lote final e os testes afetados acima passaram após a correção do teste.
