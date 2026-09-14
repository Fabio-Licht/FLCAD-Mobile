# G-105A — Inventário de transformação e alinhamento

Base auditada: `9d246f9c4a8ff801b14c21349a9ce3ded1ad74a6`, branch local
`feat/g105a-transform-alignment`. Esta entrega é documental. As decisões abaixo
são propostas para implementação posterior; não declaram suporte novo.

## Evidência no repositório

| Fronteira | Arquivo e símbolos verificados | Estado e lacuna |
| --- | --- | --- |
| Documento | `lib/core/cad_document/cad_document.dart`: `CadDocument`, `CadDocumentEntity`, `mutate`, `fromJson` | Documento `flcad.cad-document`, versão declarada 1; entidade contém ID, kind, data e handles opcionais. Não existe campo tipado de placement. O leitor verifica schema, mas não rejeita explicitamente versão documental desconhecida. |
| Assets | Mesmo arquivo: validadores `managedBrepAssets`, `managedStlAssets`, `managedStepAssets`; `managed_step_contract.dart` | BREP managed referencia BREP + STL; STL é mesh-only; STEP exige BREP + STL + manifest. STEP tem whitelist estrita de data: adicionar `transformMatrix` ali hoje não é uma extensão válida. |
| Persistência | `lib/core/cad_document/cad_document_repository.dart`: `save`, `saveHistory`, `captureFiles`, `restoreFiles` | Documento e histórico são JSON separados; snapshots completos nas pilhas Undo/Redo. Recovery em processo; os dois arquivos não são crash-atomic. Não aumentar essa garantia nesta fase. |
| Snapshots | `lib/app/runtime/cad_runtime_snapshots.dart` | Caminho documental de reconstrução deve reconhecer o novo contrato em documento e histórico, sem defaults permissivos para dados inválidos. |
| Seleção | `lib/app/runtime/cad_runtime.dart`: `selection`; `lib/app/engineering_bridge/selection/geometry_selection_manager.dart`; `lib/app/operational_entities/operational_entity.dart` | Seleção documental e seleção operacional são distintas. Transformar a entidade proprietária, sem confundir região de mesh com corpo CAD. |
| Picking | `lib/app/operational_entities/operational_entity_resolver.dart`: `resolve`, `_segment`, `_signature`; `lib/app/cad_viewport/selection/viewport_picking_controller.dart` | Mesh gera regiões por triângulos; subIDs e fingerprints de apresentação não são identidade topológica durável. Caches precisam considerar placement/revisão. |
| Cena | `lib/app/cad_viewport/scene/cad_scene_graph.dart`: `CadSceneEntity`, `replaceAll`; `lib/app/runtime/cad_document_scene_projection.dart`: `installPrepared` | Cena guarda geometry e flags; não há matriz model tipada na entidade. Instalação preparada permite substituir a cena sem estados intermediários. |
| Canvas/native | `professional_cad_viewport_widget.dart`; `native/native_viewport_bridge.dart`: adaptação de nodes, normals e `brepPresentation`; `windows/runner/native_viewport_host.cpp` | Renderização consome coordenadas de apresentação. Não há contrato único documental de model matrix atravessando os dois backends. Transformar apenas a câmera não posiciona uma entidade. |
| Matemática | `lib/core/geometric_kernel/linear_algebra/matrices.dart`: `Matrix4`; `transforms/transform3.dart`: `compose`, `align`, `decompose` | Row-major, pontos coluna, translação em índices 3/7/11. `compose(other)` é matrix × other. `decompose` não serve como canonicalizador geral: perde sinal da escala e tem fallback de rotação identidade para trace não positivo. |
| Ferramentas atuais | `lib/app/desktop/desktop_application.dart`: `_transformTools`; `operational_reverse_engineering_controller.dart`: `previewMove`, `previewRotate`, `previewScale`, `applyManualTransform` | Já há valores numéricos e eixos de preview de comprimento fixo 25. Isso não é prova de gizmo 3D manipulável profissional. Preview usa sceneGeometry ou ShapeHandle legado. |
| Transformação atual | `lib/app/runtime/cad_runtime.dart`: `applyEntityTransform`, `_transformEntityData`, `transformedSceneGeometry` | Transforma coordenadas documentais e, quando há entity.shape, cria/persiste shape pelo kernel. Acumula `transformMatrix` e `alignmentMatrix` como delta × anterior; mistura placement e geometria aplicada. Não reutilizar esse fluxo como contrato managed não destrutivo. |
| Lifecycle | `cad_runtime.dart`: `undoDocument`, `redoDocument`; `cad_runtime_transactions.dart`: `_commitManagedSnapshot`, preparação/commit/publicação, `_prepareManagedOpen` | Fila transacional, snapshots, revogação e preparação integral existentes. Retém pares managed quando assets não mudam; restaura via CAF quando necessário. Falta projetar placement em todas essas variantes. |
| Custody | `lib/core/cad_kernel/opencascade/native_allocation_custody.dart`: `OwnedNativeShape`, `OwnedNativeMesh`, leases, diagnostics | Owners residenciais independentes da identidade durável. Dispose espera leases; estados de quarentena observáveis. Placement não deve criar owner nem transferir authority. |
| Kernel | `native/opencascade/src/flcad_occ_api.cpp`: `flcad_occ_transform_shape`, `BRepBuilderAPI_Transform`, `BRepBuilderAPI_GTransform` | Existe transformação pelo registro legado de shape IDs. Existência do símbolo não prova operação managed via capability/lease. Não usar esse atalho para G-105A. |
| Alinhamento | `lib/core/alignment_engine/engine/alignment_engine.dart`, `integration/alignment_kernel_adapter.dart`, `preview/alignment_preview.dart`; `docs/adr/ADR-034-professional-alignment-suite.md` | Domínio separado com matriz, grafo, persistência e histórico próprios. Commit chama `kernel.create('ALIGNMENT_TRANSFORM', …)` com ShapeHandle. Preview calcula RMS por contagem de referências, não distância geométrica medida. |
| Referências | `lib/core/reference_geometry/models/reference_models.dart`; `lib/core/reference_engine`; métodos `threePoints`, `cylinderAxis`, `planeAxis`, `meshPick` | Há modelos de planos/eixos/pontos/frames e reconhecimento. Alguns inputs persistem handles legados; não promover esses inputs a referência durável managed. |

Os arquivos são relativos à raiz. Inventário feito por leitura de símbolos e
fluxos, não por execução de operações novas. A compatibilidade STEP de `7a422f7`
e o viewport aprovado permanecem intactos.

## Fluxos e limites atuais

Import managed admite a origem pelo CAF, usa bridges C→C e custody, promove
assets e só então publica documento/cena/retenção. STEP restaura aparência pelo
manifest validado; sua geometria é canônica em milímetros, com unidade declarada
preservada como metadado (`managed_step_contract.dart`). BREP direto e STL não
oferecem a mesma declaração confiável de unidade: não inferir unidade de STL.

Open e Redo preparam recursos antes da publicação. Undo remove a entidade da
projeção e da retenção antes de liberar recursos; close segue visual → retenção
→ dispose. Uma mudança de placement deve reutilizar esses limites, sem
reimportar origem ou alterar assets. Os caminhos genéricos de sceneGeometry e
transformação de ShapeHandle são recursos anteriores, não fallback managed.

Há três operações diferentes:

1. **Preview visual:** delta efêmero, sem gravação, owner ou alteração de BREP.
2. **Placement persistido:** muda posição/registro da instância documental;
   geometria original, hashes e manifest permanecem iguais.
3. **Aplicar à geometria:** futura operação explícita que produz novos assets
   geometricamente transformados, validados e promovidos antes do commit.

Não acumular coordenadas já transformadas e reaplicar a matriz no renderer.
Cada apresentação deve partir de coordenadas locais originais. Para a primeira
implementação, adaptar cópias de apresentação nos dois backends é uma opção sem
ABI nova; custo de grandes meshes deverá ser medido antes de escolher entre
projeção CPU e matriz por instância no host. Essa escolha é um bloqueio técnico
de A1, não autorização para alterar a ABI agora.

## Contrato durável proposto

Adicionar futuramente um campo **top-level de entidade** `placement`, separado
de data e dos contratos de assets, com schema `flcad.entity-placement`, versão 1.
Ausência significa identidade para documentos antigos; presença inválida é erro
em open/Redo. A evolução do documento deve ter versão explicitamente validada e
política de migração; não simplesmente relaxar a whitelist STEP.

Exemplo conceitual, não schema já implementado:

```json
{
  "schema": "flcad.entity-placement",
  "version": 1,
  "frameUnit": "mm",
  "matrixLayout": "row-major-column-vector",
  "pivotLocal": [0, 0, 0],
  "scaleIntent": "registration",
  "operations": [
    {"id": "op-1", "kind": "translate", "space": "world", "delta": [10, 0, 0]}
  ]
}
```

Proposta: stack ordenada de operações tipadas é a fonte de verdade; matriz 4×4
composta é derivada/cache runtime e não uma segunda verdade persistida. Incluir
rotação quaternion `[x,y,z,w]`, escala e pivot por operação; operações futuras
de alinhamento guardam a matriz rígida resolvida e proveniência documental
validada. IDs de operação são lógicos, sem identidade de residência. Limitar
quantidade de operações, profundidade JSON e magnitudes; proibir NaN, infinito,
quaternion nulo, escala zero/negativa, perspectiva e shear nas fases iniciais.
Não canonicalizar pela decomposição atual de Transform3.

O contrato não contém token, pointer, capability, pathname, handle ou
fingerprint nativo. Referências opcionais usam entidade documental + ID/hash do
asset e definição geométrica local; não índices de face de uma tesselação.
Ausência ou mudança de uma referência invalida recomputação, preservando o
placement já confirmado. Undo/Redo restaura snapshots da stack, sem recalcular
um alinhamento com dados diferentes.

### Composição, unidade e pivot

Sistema destro; ponto coluna `pWorld = M × pLocal`. Operações cronológicas em
world: `Mnext = Dworld × M`; operações locais: `Mnext = M × Dlocal`.
Rotação/escala em torno de pivot usam `T(p) × R × S × T(-p)`; uma operação
combinada, se introduzida, aplica escala, depois rotação, depois translação.
Exemplo de teste: mover +10 em X e depois rotacionar +90° em Z no mundo leva a
origem local a (0,10,0), não (10,0,0).

Pivot persistido em coordenadas locais; mudar pivot sozinho não move a peça.
Converter pivot para world pela matriz vigente para operações em world. Pivot
de grupo é capturado no início do gesto, nunca recalculado a cada mouse move.
Default proposto: centro do bounds local; origem original permanece disponível.
Ângulo UI em graus, contrato em quaternion normalizado; distâncias canônicas
em mm. Unidade exibida converte entrada numérica uma vez. STL/BREP sem unidade
requerem decisão explícita de interpretação, registrada separadamente do
placement, sem escalar bytes dos assets silenciosamente.

Bounds world vêm dos oito cantos do AABB local transformados; picking converte
raios para local ou usa a mesma projeção da apresentação. Normais usam inversa
transposta da parte linear e normalização. Linhas CAD, seleção e inspeção devem
seguir a mesma matriz; espessura de linha continua em pixels. Camera/Fit e
navegação aprovados não ganham novas regras nesta auditoria.

### Escala e aplicação posterior

**Registro visual de malha:** escala positiva uniforme pode ajustar um STL para
comparação. Não afirma dimensão metrológica original; relatório futuro precisa
mostrar fator/unidade/confiança. Escala não uniforme fica fora de A1–A3.

**BREP/STEP dimensional:** mover/rotacionar é placement rígido. Escalar altera
dimensões efetivas; deve ser uma intenção explícita `dimensional`, com aviso e
valores auditáveis, nunca correção implícita de unidade. Recomenda-se bloquear
escala CAD nas primeiras fases até validar medição/export/kernel. A aparência
de origem (nome, unidade, cor) permanece no manifest original; não falsificar
a unidade declarada porque a instância foi escalada.

**Aplicar transformação**, fora de A1–A3: consumir original e placement sob
leases managed, gerar nova BREP/display/manifest apropriados e lineage
documental; promover conjunto completo, trocar referências atomicamente e
zerar placement apenas após commit. Preservar originais e histórico, sem GC.
STL aplicado gera nova mesh, sem shape artificial. STEP requer política de
remapeamento de aparência antes de alterar geometria. Export/medição devem
consumir placement ou rejeitar a operação explicitamente: nunca exportar a
origem fingindo exportar a instância posicionada.

## Integração transacional recomendada

Um comando de placement deve adquirir a fila uma vez, capturar documento,
seleção, sessão e revisão, validar todos os alvos e preparar toda a apresentação
antes de persistir. Preview é separado e revogável; confirmar um gesto gera
uma revisão e um item Undo, não um item por frame. Não chamar APIs enfileiradas
de dentro da fila. Cancelamento, open substituto e shutdown invalidam preview
e preparação antes de qualquer publicação atrasada.

Reutilizar owners/retenções de assets idênticos; placement não altera custody.
Falha pré-commit preserva documento/histórico/cena/seleção/owners. Pós-commit
segue recoveryRequired existente, sem rollback silencioso. Open/Redo valida
stack e assets como uma preparação integral; cor STEP continua convertida uma
vez, independente da transformação. Close mantém a ordem aprovada.

## Comparação e alinhamento profissional

No caminho inspecionado não foi comprovado pipeline metrológico integrado
malha × CAD com distâncias assinadas, correspondências e tolerância rastreável.
Enums bestFit/ICP e métricas do AlignmentPreviewEngine não comprovam solver.
Reutilizar modelos/referências e matemática somente com testes geométricos;
não reutilizar métricas sintéticas como aprovação profissional.

Plano restringe normal e distância, mas deixa rotação no plano; eixo/cilindro
deixa deslocamento axial e rotação axial. Exigir referência secundária ou
explicitar graus livres. Cilindro exige eixo/radius confiáveis e tratamento de
sinal. Pontos exigem correspondências ordenadas, rejeição de coincidência e
colinearidade e solver rígido real; RMS deve vir dos resíduos medidos. Usar
referências manuais explícitas até haver extração managed de topologia estável.
Comparação futura trabalha em world com placement de ambas as entidades e
registra IDs/hashes, unidade, fatores de escala e amostragem; não altera BREP.

## Fases propostas e aceitação

| Fase | Escopo pequeno | Gate de aceitação |
| --- | --- | --- |
| G-105A1 | Contrato/migração de placement; entidade proprietária STEP/BREP/STL; mover/rotacionar numericamente, pivot local; lifecycle não destrutivo; sem gizmo | Identidade em documentos antigos; rejeição de schema/stack inválida; composição e pivot matemáticos; Canvas/native e picking concordam; import → transformar → Undo/Redo → save/close/open; hashes/owners estáveis; falhas da segunda entidade e revogação sem publicação parcial. |
| G-105A2 | Gizmo 3D, world/local, captura de gesto, valores numéricos sincronizados; escala uniforme de registro STL após unidade explícita | Um gesto = um Undo; cancelamento restaura preview; hit testing e escala em tela previsíveis; nenhuma regressão pan/orbit/zoom/modos; normais/bounds corretos; teste de integração do comando até ambos os hosts. |
| G-105A3 | Alinhamento rígido por planos/eixos/cilindros/pontos com referências explícitas e provenance; sem best-fit/ICP ou aplicação ao kernel | Casos conhecidos com resíduos reais; ambiguidades/degenerescência rejeitadas; graus livres declarados; Undo/Redo/open restaura resultado exato; referências alteradas não recomputam silenciosamente. |

Testes existentes a reutilizar como regressão: `cad_runtime_managed_step_test`,
`cad_runtime_managed_brep_test`, `cad_runtime_managed_stl_test`,
`cad_runtime_transaction_test`, `native_allocation_custody_test`,
`professional_cad_viewport_test`, `native_viewport_display_adapter_test`,
`cad_material_lighting_test`, `alignment_engine_test`, `reference_engine_test`
e `reference_geometry_test`. Eles não substituem os gates novos de placement.

## Riscos e confirmações necessárias antes da implementação

- Confirmar stack tipada como verdade durável, evolução versionada e migração
  dos `transformMatrix` legados: coordenadas já aplicadas não podem sofrer
  dupla transformação. Não converter registros legados sem identificar base.
- Confirmar mm como frame canônico e UX de unidade desconhecida em STL/BREP.
- Confirmar pivot default, world/local e política multi-seleção; evitar incluir
  simultaneamente pai e filho, causando delta duplicado.
- Confirmar bloqueio inicial de escala dimensional CAD, escala não uniforme,
  espelhamento, shear e “Aplicar transformação”. São fases futuras explícitas.
- Definir política segura para export/medição com placement antes de habilitar
  edição de posição; não permitir divergência visual e dimensional silenciosa.
- Medir custo de projeção transitória e escolher adaptador comum sem modificar
  ABI/viewport aprovado sem tarefa autorizada; preservar budgets nativos.
- Referências topológicas duráveis managed e aplicação ao kernel ainda exigem
  desenho próprio; subIDs de picking não resolvem essa lacuna.
- Crash-atomicidade documental permanece a limitação atual do repositório.

## Validação desta entrega

Revisão somente leitura dos contratos, projeções, transformação existente,
custody e domínio de referências/alinhamento. Apenas este documento foi
adicionado. Checks proporcionais: `git diff --check` e conferência do diff/status
para garantir ausência de alterações produtivas. Não foram necessários testes,
analyze, builds ou arquivos temporários para sustentar as evidências de leitura.
