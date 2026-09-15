# Matriz de capacidade dos comandos CAD

Data: 2026-09-15. Base auditada: `b6dbc63`, branch
`audit/cad-command-capability-matrix`.

## Método e limites

Auditoria estática: um comando só é considerado utilizável quando há evidência
de interface para handler, domínio/runtime e, quando existente, teste. Botão,
menu ou workspace não é evidência de operação CAD. `Pronto para teste manual`
significa que a rota e a persistência foram rastreadas; não substitui validação
visual recente. `Parcial` tem rota principal, mas requisito, cobertura ou
confirmação material pendente. `Somente UI` não executa operação CAD. `Ausente`
não possui handler utilizável.

STL managed é `Meshes`/`Malha STL`. STEP/BREP managed é `Solids` ou
`Surfaces` segundo topologia nativa persistida, nunca pela tesselação de
apresentação. Mesh Regions são próprias de STL/mesh real, não do display mesh
de STEP/BREP.

## 1. References

| Comando e local UI | Rota rastreada | Entrada → saída/árvore | Persistência, testes e status |
| --- | --- | --- | --- |
| Workspace `Reference` | `workspace.reference` em `desktop_command_coordinator.dart`; `_WorkspaceEnvironmentPlaceholder` em `desktop_application.dart`. | Nenhuma → nenhuma. | **Somente UI.** Sem domínio, runtime, Undo/Redo ou criação documental. Próxima ação: ligar aos comandos de Geometria ou ocultar a promessa visual. |
| Geometria → `Ponto`, `Plano`, `Vetor`, `Curva` | `_entityToolbarMenu` → `_EntitiesHubPanel` → `EntityPointService`, `EntityPlaneService`, `EntityVectorService`, `EntityCurveService` → `CadRuntime.mutate`. | Campos numéricos/ponto do viewport → construção em `Entidades`, `References` ou `Curves`, conforme kind/sceneKind. | Lifecycle, documento e histórico do runtime. Evidência: `entities_vector_command_test.dart`, `reference_geometry_test.dart`, `reference_engine_test.dart`, `cad_runtime_document_writers_test.dart`. **Pronto para teste manual** para referências analíticas manuais. Risco: não é extração automática de STEP/BREP. Próxima ação: expor a mesma rota no workspace Reference. |
| Recognition → `Create Plane`, `Create Axis`, `Create Point`, `Create Coordinate System` | `SketchSurfaceWorkspacePanel` → `OperationalReverseEngineeringController.createRecognizedPlane/createAxis/createPoint/createCoordinateSystem` → `reverse.reference.*`. | Hipótese de Recognition aceita → referência documental/entidade de construção. | Há comandos internos com undo/redo; evidência: `reference_engine_test.dart`, `smart_reference_test.dart`, `professional_recognition_test.dart`. **Parcial.** Exige Recognition de STL/mesh; não usar a malha de display de STEP/BREP. Próxima ação: validar STL → hipótese → referência → save/open. |

## 2. Sketch

| Comando e local UI | Rota rastreada | Entrada → saída/árvore | Persistência, testes e status |
| --- | --- | --- | --- |
| `Sketch` → XY/YZ/ZX ou suporte | `_SketchEntryWorkspace`, `_openSketchSupportFallback`, `_selectWorldSketchSupport` → `selectWorldSketchPlane`/`selectSketchSupport` → `openSketch`/`reverse.sketch.open`. | Projeto aberto e plano mundial, referência planar, face ou superfície planar → Sketch em `Sketches`. | Cena/documento sincronizados e comando com undo/redo. Evidência: `sketch_editor_test.dart`, `sketch_constraint_solver_test.dart`, `professional_cad_viewport_test.dart`. **Pronto para teste manual.** Risco: suporte STEP/BREP requer face planar selecionável, não Mesh Region. Próxima ação: testar XY e uma face CAD. |
| Ponto, linha, retângulo, círculo, arcos e edição | `_SketchWorkspaceFoundation` → controller (`drawRectangle`, comandos de linha/círculo/arco, editor API). | Sketch ativo + cliques/valores → entidades de sketch em `Sketches`. | Editor/constraints/documento; evidência: `sketch_editor_test.dart`, `sketch_constraint_solver_test.dart`, `g134_sketch_assistant_test.dart`. **Pronto para teste manual** para modos implementados. Risco: enum com `implemented == false` não inicia comando. Próxima ação: ocultar modos não implementados. |
| Restrições, dimensões, health, auto-heal | Painel de sketch → controller/editor/constraint API (`createDrivingDimension`, `autoHealSketchGap`). | Sketch e seleção compatíveis → atualiza geometria/constraints do sketch. | Estado documental; evidência: `sketch_constraint_solver_test.dart`, `intelligent_sketch_test.dart`. **Parcial.** Cobertura não demonstra todos os gestos. Próxima ação: perfil fechado + dimensão + save/open + Undo/Redo. |
| `Finish Sketch` / `Preview Surface` | `_finishSketch` → `finishSketch` (`reverse.sketch.finish`); `previewPlanarSurface`. | Perfil válido → sketch terminado / preview transitório. | Finish tem undo/redo; evidência: `g129_surface_preview_test.dart`, `professional_cad_viewport_test.dart`. **Pronto para teste manual.** Preview não é entidade durável. Próxima ação: indicar isso explicitamente no UI. |

## 3. Curves

| Comando e local UI | Rota rastreada | Entrada → saída/árvore | Persistência, testes e status |
| --- | --- | --- | --- |
| Workspace `Curves` | `workspace.curves` → `_WorkspaceEnvironmentPlaceholder` (“prepared for future tools”). | Nenhuma → nenhuma. | **Somente UI.** Próxima ação: ligar comandos reais ou ocultar. |
| Geometria → `Curva` | `_EntityCurvePanel` → `EntityCurveService.create` → `CadRuntime.mutate`. | Pontos/campos manuais e, se houver, ponto de viewport → `Curves`. | Documento/runtime; evidência: `reference_engine_test.dart`, `reference_geometry_test.dart`. **Pronto para teste manual** como curva de construção manual. Risco: não é Project/Extract/Intersection. Próxima ação: renomear para “Curva de construção”. |
| Reference Curve / Sections | `createWorldReferenceCurve`, `createSection`, `createMultipleSections`, `createSketchFromSelectedSection`; `SectionManager`. | Plano/seção de mesh → `Reference Curves`/`Sections`, opcionalmente Sketch associado. | Documento/SectionManager; evidência: `professional_cad_viewport_test.dart`. **Parcial.** Caminho para STL/mesh, não extração direta de aresta STEP/BREP. Próxima ação: testar STL → Section → Sketch → save/open. |
| `Splines`, `Projected`, `Extracted`, `Intersection` | Apenas capabilities declaradas no placeholder. | N/A. | **Ausente.** Próxima ação: entregar uma curva CAD, por exemplo projetar sketch em face, antes de anunciar as quatro. |

## 4. Surfaces

| Comando e local UI | Rota rastreada | Entrada → saída/árvore | Persistência, testes e status |
| --- | --- | --- | --- |
| Geometria → primitivas `Plano`, `Cilindro`, `Cone`, `Esfera`, `Toro` | `_EntityPrimitiveSurfacePanel` → `EntityPrimitiveSurfaceService.create` → kernel OCCT/`CadRuntime.mutate`. | Parâmetros analíticos → face B-Rep validada; `Surfaces`. | Documento/lifecycle/histórico; evidência: `adaptive_surface_test.dart`, `surface_generation_test.dart`, `opencascade_integration_test.dart`. **Pronto para teste manual.** Risco: não reconstrói mesh. Próxima ação: testar cada primitiva com save/open. |
| Sketch → `Confirm Surface` | `confirmSurface` → `reverse.surface.confirm` → geração de superfície/kernel. | Sketch terminado e saudável → superfície em `Surfaces`. | Comando com undo/redo; evidência: `g129_surface_preview_test.dart`, `surface_generation_test.dart`, `professional_cad_viewport_test.dart`. **Pronto para teste manual.** Próxima ação: testar perfil fechado e aberto. |
| Toolbar `Surfaces`: Loft, Sweep, Fill, Patch, Blend, Fillet, Sew, Offset | `_surfaceToolbarMenu` → `SketchSurfaceWorkspacePanel` → `previewProfessional*` → `ProfessionalSurfaceApi.confirm`/adapters/kernel. | Loft: 2 sketches/reference curves/edges; Sweep: perfil+path; Blend: 2 superfícies; Fill/Patch: bordas; Fillet: suportes+topologia; Sew: >=2 superfícies; Offset: 1 superfície → feature em `Surfaces`. | Preview é transitório; confirmação usa documento/lifecycle. Evidência: `professional_surface_modeling_test.dart`, `g139_professional_surface_continuity_test.dart`, `surface_generation_test.dart`. **Parcial.** Seleções são estritas e exigem validação manual de topologia. Próxima ação: validar Loft de dois sketches e Offset de uma superfície criada. |
| `Join` / `Unjoin` | Botões condicionais → `operational.joinSurfaces/unjoinSurfaces`. | Exatamente duas superfícies documentais → associação alterada em `Surfaces`. | Evidência: `g139_professional_surface_continuity_test.dart`. **Parcial.** STEP/BREP classificado como surface não vira automaticamente superfície profissional editável. Próxima ação: testar duas superfícies geradas. |
| `Zebra`, `Reflection`, `Curvature` | Botões de `SketchSurfaceWorkspacePanel` têm `onPressed: null`. | N/A. | **Ausente.** Próxima ação: conectar uma análise real ou remover os botões. |

## 5. Solids

| Comando e local UI | Rota rastreada | Entrada → saída/árvore | Persistência, testes e status |
| --- | --- | --- | --- |
| `Solids` → `Extrude` | `_ProfessionalExtrudePanel` → `selectExtrudeSource`, `previewProfessionalExtrude`, `confirmProfessionalExtrude` → professional extrude/kernel OCCT. | Sketch ou Surface, distância, draft, direção, output → preview e feature em `Solids` ou `Surfaces`. | Documento, preview cancelável e Undo/Redo; evidência: `extrude_feature_test.dart`, `g143_professional_extrude_test.dart`, `professional_cad_viewport_test.dart`. **Pronto para teste manual** no contrato básico. Risco: import STEP/BREP não é perfil automaticamente. Próxima ação: sketch fechado → extrude sólido → save/open → Undo/Redo. |
| `Solids` → `Revolve` | Painel de solids → `previewProfessionalRevolve`, `confirmProfessionalRevolve` → professional revolve/kernel OCCT. | Perfil + eixo, ângulo, direção/output → feature CAD. | Preview/confirm/documento; evidência: `revolve_feature_test.dart`, `professional_cad_viewport_test.dart`. **Pronto para teste manual** básico. Risco: “Symmetric/Thin/Up To Surface/Multi Axis” é declarado como architecture prepared, não operação confirmada. Próxima ação: limitar UI aos parâmetros efetivos. |
| STEP/BREP em `Solids` | Import managed → `ManagedCadIdentity.shape`/descriptor nativo; árvore por `cadSemanticKind`. | STEP sólido/BREP com sólido → `Solids`; não cria feature paramétrica. | Assets managed, save/open/Undo/Redo; evidência: `cad_runtime_managed_step_test.dart`, `cad_runtime_managed_brep_test.dart`, `managed_cad_identity_test.dart`. **Pronto para teste manual** para identidade/visualização; não para edição paramétrica. Próxima ação: definir “usar face/import como perfil” antes de habilitar. |

## 6. Geometria, Recognition e Inspection

| Comando e local UI | Rota rastreada | Entrada → saída/árvore | Persistência, testes e status |
| --- | --- | --- | --- |
| `Recognition` / pick de região | `RecognitionWorkspacePanel`/viewport → `recognizePick` → Professional Recognition. | STL/mesh completo + triângulo/região homogênea → resultado de Recognition. | Resultado publicado no documento; evidência: `professional_recognition_test.dart`, `geometric_recognition_test.dart`, `professional_cad_viewport_test.dart`. **Parcial.** Controller recusa LOD simplificado; STEP/BREP não deve entrar como Mesh Region. Próxima ação: ensaio STL real completo com persistência. |
| Recognition → Surface Assistant | `confirmSurfaceAssistantSuggestion` → `RecognitionSurfaceAssistantAdapter.confirm` → `SurfaceGenerationApi`. | Resultado aceito plane/cylinder/cone/sphere/fillet → superfície em `Surfaces`. | Feature/documento; evidência: `professional_recognition_test.dart`, `surface_generation_test.dart`. **Parcial.** `freeform` lança erro de futuro tool. Próxima ação: ocultar freeform ou implementar fluxo supervisionado. |
| Inspection `G0`/`G1` | Painel de superfícies → `inspectSelectedG0`, `previewSelectedG1`, Join/Unjoin. | Duas superfícies profissionais → análise/preview condicionado. | Evidência: `g139_professional_surface_continuity_test.dart`. **Parcial.** Não é inspeção geral de import STEP/BREP. Próxima ação: exibir elegibilidade e bloqueio no painel. |
| Inspection `Zebra`/`Reflection`/`Curvature` | UI desabilitada. | N/A. | **Ausente.** Próxima ação: implementar uma análise por vez. |

## Caminho mínimo para modelar uma peça simples

| Etapa | Caminho atual | Estado |
| --- | --- | --- |
| 1 | Importar STL para engenharia reversa; STEP/BREP somente como referência CAD sólida/superficial. | Pronto para teste manual |
| 2 | Plano manual por Geometria, ou em STL: Recognition → aceitar plano → Create Plane. | Plano manual pronto; Recognition parcial |
| 3 | Criar Sketch em plano XY/YZ/ZX, referência ou suporte planar elegível. | Pronto para teste manual |
| 4 | Fechar/validar sketch com constraints e health. | Pronto para teste manual, gestos pendentes de ensaio |
| 5 | Solids → Extrude sólido; alternativa Revolve com perfil+eixo. | Pronto para teste manual básico |
| 6 | Conferir árvore, salvar/reabrir, Undo/Redo. | Pronto para teste manual |

O caminho de menor dependência hoje é: **plano manual → sketch fechado →
extrude sólido → salvar/reabrir**. Para STL, inserir Recognition somente para
obter a referência. Não usar Mesh Regions como atalho para STEP/BREP.

## Três blocos recomendados

1. **References utilizáveis:** trocar o placeholder Reference por Point, Plane,
   Vector e Curve reais, com promoção explícita de face planar STEP/BREP e
   teste save/open/Undo/Redo.
2. **Curva CAD mínima:** entregar projeção de sketch em face e ocultar
   Splines/Projected/Extracted/Intersection até seus handlers existirem.
3. **Ciclo de peça simples:** roteiro automatizado/manual plano → sketch →
   extrude, seguido por Loft/Offset, com elegibilidade explícita para STL
   versus STEP/BREP.
