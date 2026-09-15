# Auditoria de unificação de referências

Data da auditoria: 2026-09-15
Base auditada: `6945c979`
Método: rastreamento somente leitura de UI → handler → modelo/runtime → teste.

## Escopo e conclusão

Há dois contratos duráveis que hoje podem aparecer para o usuário como uma
“referência”:

1. entidades do `CadDocument`, publicadas pelo `CadRuntime`, normalmente em
   `collection:references`;
2. `ReferenceEntity` do `ReferenceEngine`, persistido também em
   `References/references.json` e espelhado no documento por
   `OperationalReverseEngineeringController._upsertReference`.

Eles não devem ser fundidos por aparência. A seleção STEP/BREP managed usa a
face B-Rep real e um contrato `ManagedCadReference`; Recognition usa uma
região de malha, ajuste e confiança. As duas fontes podem produzir um plano,
eixo, ponto ou curva visualmente semelhantes, mas a precisão, a proveniência
e a política de invalidação são diferentes.

### Estados de evidência usados neste documento

- **Comprovado**: há teste automatizado que alcança a criação/contrato citado.
- **Parcial**: há runtime e teste unitário, mas não uma prova completa de
  save/open e Undo/Redo para aquela rota de UI.
- **Não é referência**: entidade visualmente parecida, mas que representa
  geometria B-Rep/superfície real ou contexto de sistema.

## 1. Sistema padrão

| Item visível | UI / handler / modelo | Entrada e saída na árvore | Natureza e ciclo de vida | Evidência |
|---|---|---|---|---|
| World Coordinate System, Origin, X/Y/Z Axis, XY/XZ/YZ Plane | Criado por `WorldCoordinateSystem.ensure` ao abrir/sanitizar documento; visível na árvore como `World Coordinate System`. | Sem entrada do usuário. Sete `CadDocumentEntityKind.reference` protegidas (`systemProtected`). | Contexto de sistema, não referência de autoria. É documento durável, protegido contra remoção; a projeção de cena é derivada. | **Comprovado**: `g120_4_workspace_recovery_test.dart`; proteção também é aplicada por `CadRuntime`. |
| XY/YZ/ZX de Geometria | Menu `Geometria` → `Planos` → `_EntityPlanePanel` → `EntityPlaneService.create`. | Manual, sem origem, produz `CadDocumentEntityKind.reference` em `References`, tipo de construção `plane`. | Referência construtiva de autoria; uma operação `CadRuntime.upsertEntity`, logo participa de Undo/Redo e do documento. Não é o plano padrão protegido, embora tenha geometria igual. | **Comprovado**: `entities_plane_command_test.dart`. |
| X/Y/Z de Geometria | `Geometria` → `Vetores` → `_EntityVectorPanel` → `EntityVectorService.create`. | Manual, produz `reference` em `References`, cena `axis`, tipo `vector`. | Referência construtiva de autoria; não é um eixo de sistema. Persistência/histórico seguem `upsertEntity`. | **Comprovado**: `entities_vector_command_test.dart`. |

**Redundância:** o sistema padrão e os construtores XY/YZ/ZX ou X/Y/Z são
parecidos visualmente, mas não são funcionalmente redundantes: o primeiro é
contexto imutável do projeto e o segundo é autoria removível com proveniência.

## 2. References

| Item visível | UI / handler / modelo | Entrada e saída na árvore | Natureza, persistência e histórico | Evidência |
|---|---|---|---|---|
| Plano por face planar | Workspace `Reference` → `_ManagedCadReferencePanel.createPlane` → `CadRuntime.createManagedCadPlaneReference` → `ManagedCadReference.plane`. | Clique/hit de face de STEP/BREP managed; `presentationTriangleId` só resolve a face e não é persistido. Produz `reference`, `sceneKind: plane`, em `References`. | Referência B-Rep exata: persiste entidade, formato, hash B-Rep, índice topológico, origem, normal e eixo X. Fica órfã se a origem não estiver presente ou o hash divergir. Undo/Redo, save/open e Hide/Show estão cobertos. | **Comprovado**: `cad_runtime_managed_step_test.dart`, `managed_cad_reference_test.dart`, `sketch_on_managed_reference_test.dart`. |
| Eixo por face cilíndrica | Mesmo painel → `createAxis` → `CadRuntime.createManagedCadCylinderAxisReference` → `ManagedCadReference.cylindricalAxis`; OCCT `flcad_occ_managed_cad_face`. | Face cilíndrica de STEP/BREP managed. Produz `reference`, `sceneKind: axis`, em `References`; Inspector mostra origem, direção, raio, origem, formato, face e estado. | Referência B-Rep exata; a direção é unitária/canônica por ser uma linha sem sentido. Persiste hash/face/geometria, não token, ponteiro, pathname ou `primitiveId`; suporta órfão, Undo/Redo, save/open e Hide/Show. Overlay seguro para Native GPU. | **Comprovado**: `cad_runtime_managed_step_test.dart`, `cad_runtime_managed_brep_test.dart`, `managed_cad_reference_test.dart`, smoke OCCT. |
| Referência de plano reconhecido | `RecognitionWorkspacePanel` → `Accept Plane & Create Reference` → comando `reverse.reference.plane` → `ReferenceBridge` / `ReferenceEngine` → `_upsertReference`. | Região homogênea de malha + hipótese planar aceita. Produz `ReferenceEntity` de plano e espelho `CadDocumentEntityKind.reference`. | Fitting de região, com DNA, analytics, confiança e receita. O engine persiste em `References/references.json`; o espelho usa transação do runtime. Não equivale a uma face B-Rep. | **Parcial**: `reference_engine_test.dart`, `smart_reference_test.dart`, `professional_recognition_test.dart`; auditoria anterior aponta necessidade de ensaio STL completo save/open. |
| Referência reconhecida de eixo/ponto | Mesmo painel → `createRecognizedReference`; eixo para cilindro/cone/toro, ponto para esfera. | Região STL/mesh e hipótese aceita; parâmetros reconhecidos. Produz `ReferenceEntity` de eixo ou ponto e espelho no documento. | Ajuste com proveniência da região; não há hash/índice de face B-Rep. Undo/Redo é registrado nos comandos `reverse.reference.recognized`. | **Parcial**: comandos e builders `AxisBuilder`/`PointBuilder` existem; não há prova localizada de todo o fluxo STL → reabrir. |
| Eixo, ponto e CSYS derivados de plano reconhecido | `RecognitionWorkspacePanel` → `Create Axis`, `Create Origin`, `Create CSYS` → `reverse.reference.axis/point/coordinateSystem`. | Plano de Recognition aprovado. Produz `ReferenceEntity` correspondente e espelho documental. | Construção derivada, não extração de uma nova face. O `ReferenceEngine` armazena receita, dependências, estado e histórico próprio; o runtime armazena a entidade visual. | **Parcial**: `reference_engine_test.dart` e `smart_reference_test.dart`; requer teste integrado de reabertura. |

### Demais referências expostas pelo motor

`ReferenceEngine` contém builders de plano, eixo, ponto, curva e sistema de
coordenadas. Seus builders aceitam, entre outros, `bestFit`, três pontos,
offset, paralelo, plano médio, dois pontos, normal de plano, interseção de
planos, centróide de região, borda/região e pontos explícitos. Isso é uma
capacidade de domínio; não significa que todos os métodos tenham comando UI
dedicado hoje.

## 3. Geometria: pontos, planos, vetores e curvas

O menu comum é `Geometria de Referência` no toolbar (`_entityToolbarMenu`),
que abre `_EntitiesHubPanel`.

| Tipo / comandos visíveis | Handler e entrada | Saída / classificação | Persistência, Undo/Redo e evidência | Redundância |
|---|---|---|---|---|
| Pontos: Coordenadas, endpoint inicial/final, midpoint, equidistantes, sobre entidade | `_EntitiesWorkspacePanel` → `EntityPointService.create`; coordenadas, curva/linha/malha publicada ou ponto de pick. | `CadDocumentEntityKind.vertex`, cena `point`, em `References`; `constructionEntity.type: point`. | `upsertEntityBatch`; persistido no documento e histórico runtime. **Comprovado**: `entities_point_command_test.dart`. | Pode parecer o “Origin” do sistema ou o ponto reconhecido, mas difere por autoria/proveniência. |
| Planos: XY/YZ/ZX, origem+normal, três pontos, offset, paralelo, médio, perpendicular, angular, normal a curva, tangente, linha+ponto, duas linhas, best-fit, extrair planar | `_EntityPlanePanel` → `EntityPlaneService.create`; entrada manual, entidades de construção ou amostras/pick publicados. | `reference`, cena `plane`, em `References`; `constructionEntity.type: plane`, incluindo métricas para fit. | Uma transação runtime. **Comprovado** para principais, três pontos, offset, fit e tangência: `entities_plane_command_test.dart`. | Sobrepõe visualmente plano B-Rep e plano reconhecido, mas o serviço genérico usa geometria publicada; não preserva topologia STEP/BREP. |
| Vetores: eixos, componentes, dois pontos, entidades, curva, tangência, normal, interseção, produto, bissetor, projeção, inversão, best-fit | `_EntityVectorPanel` → `EntityVectorService.create`; manual, seleção de entidades e normal/pick. | `reference`, cena `axis`, em `References`; `constructionEntity.type: vector`. | Uma transação runtime. **Comprovado** para componentes, dois pontos, normal/interseção, normal local e fit: `entities_vector_command_test.dart`. | “Vetor” pode ser apresentado como eixo, mas mantém magnitude/método; o eixo B-Rep é uma referência analítica sem orientação. |
| Curvas: extrair aresta, limites, limite externo, iso U/V, interseção superfície-plano, seção mesh | `_EntityCurvePanel` → `EntityCurveService.create`; curvas ou malhas/superfícies publicadas e, quando aplicável, plano/pick. | `CadDocumentEntityKind.curve`, cena `curve`, em `Modified`, não em `References`; `constructionEntity.type: curve`. | `upsertEntityBatch`; documento/histórico runtime. **Comprovado**: `entities_curve_command_test.dart`. | Não é uma referência por definição atual da árvore; extrair limite de mesh não é extração topológica de aresta STEP/BREP. |

## 4. Superfícies primitivas

| Comando visível | UI / handler / entrada | Saída e classificação | Persistência e evidência | Relação com referências |
|---|---|---|---|---|
| Plano, Cilindro, Cone, Esfera, Toro | `Geometria` → `Superfícies primitivas` → `_EntityPrimitiveSurfacePanel` → `EntityPrimitiveSurfaceService.create`; parâmetros manuais. | Face B-Rep criada pelo kernel (`GENERATE …`), `CadDocumentEntityKind.surface`, em `Modified`, com `surfaceKind` e shape persistente. | Transação do kernel seguida de `CadRuntime.upsertEntity`; **Comprovado** para as cinco primitivas e validação: `entities_primitive_surface_command_test.dart`. | **Não é referência.** Um plano primitivo é uma superfície B-Rep finita e editável/validável; um plano de referência é construção sem superfície B-Rep. Cilindro primitivo não é o eixo extraído de uma face cilíndrica. |
| Surface Assistant de Recognition | `RecognitionWorkspacePanel` → `Create Surface` → `RecognitionSurfaceAssistantAdapter.confirm` → `SurfaceGenerationApi`. | Superfície gerada em `Surfaces`, com proveniência de Recognition. | **Parcial**: confirmação e proveniência em `g136_intelligent_surface_assistant_test.dart`; `freeform` é explicitamente recusado. | É reconstrução de superfície a partir de mesh; não deve substituir uma referência de ajuste/medição. |

## 5. Recognition, Inspection e Mesh Regions

| Item | UI / handler / entrada | Saída e persistência | Classificação / evidência |
|---|---|---|---|
| Mesh Region | Pick de mesh no viewport → `OperationalEntityResolver._segment` e `MeshRegionBuilder`; apresentado em `RecognitionWorkspacePanel`. | Região operacional por índices de triângulos da malha-fonte, com área, curvatura, confiança e saúde. Não é uma entidade CAD persistida independente. | Ferramenta de STL/mesh. **Comprovado** para conectividade e seleção: `engineering_interaction_bridge_test.dart`, `professional_cad_viewport_test.dart`. Nunca deve ser usada como topologia STEP/BREP ou malha de apresentação. |
| Detect Plane/Cylinder/Cone/Sphere/Torus | `RecognitionWorkspacePanel` → `OperationalReverseEngineeringController.detect` → `ProfessionalRecognitionApi`. | Resultado `CadDocumentEntityKind.recognition`, grupo `Recognition`, visibilidade de cena desligada; hipótese/decisão e proveniência são gravadas. | Inspection/Recognition, não referência até aceitação. **Parcial**: testes de Recognition acima; o contexto exige região de malha. |
| Inspection / árvore Recognition | Explorer agrupa `Recognition` por tipo; Surface Assistant pode confirmar uma superfície. | Resultado persistido no documento; preview é transitório. | Não confundir uma hipótese com referência, superfície ou sólido. |

## Taxonomia única proposta para a árvore

```text
Sistema padrão
  Origin
  Eixos (X, Y, Z)
  Planos (XY, XZ, YZ)

Referências
  Pontos
  Eixos
  Planos
  Curvas

Geometria
  Superfícies
  Sólidos
```

Regras propostas:

1. O grupo é decidido pelo **tipo final**: `PointGeometry`/ponto, eixo/vetor,
   plano, curva. Não pelo workspace que o criou e nem pela origem.
2. Proveniência deve aparecer como badge/metadado, por exemplo `Manual`,
   `STEP/BREP · topologia exata`, `STL · fit`, `Derivada`, com tolerância,
   RMS/confiança ou hash/índice de face quando pertinentes.
3. `Sistema padrão` é raiz separada, sempre protegida; não se mistura a
   entidades de autoria chamadas XY/X/Y.
4. Um plano, cilindro, cone, esfera ou toro primitivo permanece em
   `Geometria > Superfícies`, com badge `Superfície B-Rep`; não entra em
   `Referências` só porque oferece normal, eixo ou centro.
5. `Mesh Region` fica como contexto transitório de Recognition/Inspection.
   Uma referência criada de STL recebe o badge de fit e a evidência da região,
   mas não persiste a região como se fosse B-Rep.
6. Durante migração, o adaptador de árvore deve aceitar tanto
   `ManagedCadReference` quanto `ReferenceEntity` e `constructionEntity`, mas
   não reserializar um contrato no outro sem migração explícita/versionada.

## Proposta: comando unificado “Criar referência”

Um único ponto de entrada de UX não deve significar um único algoritmo. O
comando primeiro classifica a seleção e só então oferece ações compatíveis.

| Contexto selecionado | Opções oferecidas | Algoritmo que deve permanecer | Resultado proposto |
|---|---|---|---|
| Face STEP/BREP managed | Plano se `GeomAbs_Plane`; eixo se `GeomAbs_Cylinder`; ponto somente quando houver picking topológico de vértice seguro. | `TopoDS_Face`/OCCT e contrato `ManagedCadReference`; triângulo de apresentação apenas mapeia a subforma transitória. | Referência com badge `STEP/BREP · exata`, entidade, formato, hash, índice topológico e estado órfão. |
| Região STL/mesh | Plano best-fit/extraído, eixo de primitiva reconhecida, ponto/centro reconhecido, curva de região/seção quando a ferramenta a suportar. | `MeshRegion`, fitting/Recognition, tolerância, RMS, cobertura e confiança. | Referência com badge `STL · fit`, métricas e proveniência da região; requer confirmação quando a confiança estiver abaixo do limiar. |
| Sem seleção ou entidades construtivas | Ponto por coordenadas, plano origem+normal/três pontos/offset, eixo por componentes/dois pontos/normal, curva explícita/derivada. | `EntityPointService`, `EntityPlaneService`, `EntityVectorService`, `EntityCurveService` ou builder equivalente. | Referência com badge `Manual` ou `Derivada`; método e dependências explícitos. |
| Superfície B-Rep manual/Reconhecida | Não oferecer “converter em referência” automaticamente. Oferecer extrair normal/eixo/centro apenas se houver contrato analítico explícito. | Kernel/SurfaceGeneration para a superfície; referência derivada somente após confirmação. | Superfície permanece em `Surfaces`; a referência nova registra que é derivada. |

### Menor sequência de implementação recomendada

1. Criar um descritor de apresentação de referência somente para árvore e
   Inspector (`finalType`, `provenance`, métricas, estado), adaptando os três
   contratos existentes sem alterar a geometria persistida.
2. Substituir os acessos dispersos por um launcher `Criar referência` que
   roteie por capacidade da seleção, mantendo os handlers atuais como
   implementações internas.
3. Migrar a árvore para `Pontos`, `Eixos`, `Planos` e `Curvas`; deixar
   `Sistema padrão` e `Superfícies` separados.
4. Só depois avaliar uma migração versionada entre `ReferenceEngine` e
   `ManagedCadReference`; não reduzir topologia B-Rep a dados de mesh nem
   fingir que um fit STL possui a mesma exatidão.

## Lacunas objetivas encontradas

- O workspace `Reference` hoje é específico de face STEP/BREP, enquanto
  construções manuais vivem em `Geometria` e Recognition em outro painel.
- Curvas de `EntityCurveService` vão para `Modified`, apesar de muitas serem
  auxiliares; a classificação deve ser decidida por propósito/resultado antes
  de uma mudança de coleção.
- O serviço genérico de plano/vetor pode consumir nós/normais publicados; ele
  não deve ser apresentado como substituto da extração topológica managed.
- O fluxo Recognition tem testes de domínio e de confirmação, mas ainda pede
  prova integrada STL real → referência → fechar/abrir para receber o mesmo
  nível de evidência do contrato managed.
