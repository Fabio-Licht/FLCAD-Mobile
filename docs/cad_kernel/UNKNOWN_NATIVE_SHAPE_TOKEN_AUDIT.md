# Auditoria — `Unknown native shape token`

Status: **DIAGNÓSTICO CONCLUÍDO — SEM CORREÇÃO**  
Data: 2026-08-17  
Escopo observado: `flcad_occ_native_smoke`, configuração Release

## Conclusão

O erro observado não é perda de um token previamente registrado. Na execução
Release do smoke nativo, o token `roundtrip` **nunca é criado**.

O teste chama criação, exportação e importação STEP dentro de `assert(...)`.
Com `NDEBUG`, o compilador remove integralmente essas expressões. Em seguida, a
chamada de `flcad_occ_transform_shape()` — adicionada fora de `assert` — é
executada com o buffer `roundtrip` ainda vazio. O registry procura a chave `""`
e retorna corretamente `Unknown native shape token`.

O mesmo executável de teste, compilado em Debug, executa as expressões de
`assert`, cria o token e conclui integralmente com sucesso.

## Rastreamento do token esperado

### Onde deveria ser criado

O token deveria nascer em:

1. `flcad_occ_import_shape()` lê o STEP e obtém `STEPControl_Reader::OneShape()`;
2. `flcad_occ_import_shape()` chama `output()`;
3. `output()` chama `store(shape)`;
4. `store()` gera `occ-shape-N` e insere `shapes[id] = shape`;
5. `output()` copia o ID para o buffer C `roundtrip`.

### Onde deveria ser registrado

No registry nativo em memória:

`std::unordered_map<std::string, TopoDS_Shape> shapes`.

### Onde deixou de existir

Em nenhum lugar: não houve criação nem remoção. Na configuração Release, a
expressão abaixo é eliminada antes da execução:

`assert(flcad_occ_import_shape(...) == 1);`

Assim, `roundtrip` permanece `""`. A falha é levantada por `get("")` dentro de
`flcad_occ_transform_shape()`.

## Propriedade do token

| Camada | Papel no caso auditado |
|---|---|
| ShapeHandle | Não participa do smoke C++ direto |
| Registry nativo | Proprietário do vínculo token → `TopoDS_Shape`; comportou-se corretamente |
| CadDocument | Não participa |
| Persistência | Não participa |
| Bridge C/FFI | Define as chamadas, mas o smoke invoca diretamente a ABI C |
| Test harness | Origem do defeito: produtor envolvido em `assert`, consumidor fora dele |

## Origem histórica

O comportamento foi introduzido pelo commit:

`34e803f835492e61ace9e0e55e844ce53d9e0a50`  
`feat(reverse): Professional Sketch Workbench completed`  
Data: 2026-08-17 15:22:41 -0300

Esse commit adicionou `flcad_occ_transform_shape()` e seu teste. A importação
STEP preexistente continuou dentro de `assert`, enquanto a nova chamada de
transformação foi implementada com `if (...)`, portanto permaneceu ativa em
Release. O commit não introduziu remoção indevida no registry.

## Regressão

- **Produto/runtime:** não há evidência de regressão de token.
- **Teste Release:** sim. O smoke passou a falhar quando ganhou o primeiro
  consumidor executável fora de `assert` após produtores eliminados por
  `NDEBUG`.
- **Cobertura Release:** já era ineficaz para todas as chamadas envolvidas em
  `assert`; o novo trecho apenas tornou essa deficiência visível.

## Alcance

### STEP

O erro aparece no round-trip STEP porque `roundtrip` é o primeiro token vazio
consumido por uma chamada fora de `assert`. Não demonstra falha de
`STEPControl_Reader`, `output()` ou `store()`.

### Surface

As operações NURBS, Trim, Boundary e Heal do smoke também estão dentro de
`assert` e, portanto, não são exercitadas em Release. Em Debug, foram executadas
e aprovadas no mesmo teste. Seus resultados usam o mesmo `output() → store()`.

### Shell, Solid e Sew

Esses caminhos também retornam shapes pelo mesmo `output() → store()`:

- Shell: `flcad_occ_create_shell()`;
- Solid: `flcad_occ_create_solid()`;
- Sew: `flcad_occ_create_shell()` ou operação `SEW` do bridge de superfícies.

Não há evidência de perda de token específica nesses operadores. Entretanto, o
smoke Release atual não é evidência válida para eles, pois chamadas em
`assert(...)` não são executadas.

### Generalização

O defeito pode se repetir em qualquer teste Release que:

1. produza um token exclusivamente dentro de `assert(...)`; e
2. consuma esse token posteriormente fora de `assert(...)`.

Isso é uma limitação do test harness, não do tipo geométrico.

## Evidência de reprodução

| Configuração | Resultado | Explicação |
|---|---|---|
| Release | Falha em `transform` com token vazio | `assert` removido por `NDEBUG` |
| Debug | 100% aprovado | produtores dentro de `assert` são executados |

Nenhum arquivo funcional foi alterado como parte desta auditoria. Este documento
não autoriza correção do teste nem alteração da Categoria A.
