# G-109 — Categoria B — Especificação funcional do Design Review

Status: **DESIGN REVIEW — SEM IMPLEMENTAÇÃO**  
Referência técnica: `G109_CATEGORY_B_OCCT_AUDIT.md`  
Data: 2026-08-17

## 1. Escopo e invariantes

Este documento define exclusivamente o fluxo operacional e a experiência do usuário para:

- Match Surface;
- Blend Surface;
- Offset + Walls;
- Boundary Extend;
- Boundary Trim.

Não autoriza implementação. A Categoria A permanece congelada e em QA. A Categoria C permanece bloqueada.

Invariantes obrigatórios:

- todas as entradas geometricamente compatíveis são resolvidas automaticamente pelo Geometry Input Resolver existente;
- o operador nunca precisa converter manualmente Sketch, Curve, Edge, Wire, Boundary ou Section;
- `ShapeHandle` é uma representação interna, nunca um item solicitado ao usuário;
- nenhum preview altera o `CadDocument`;
- somente `Apply` cria o resultado definitivo e participa de persistência, histórico, Undo e Redo;
- `Cancel` elimina integralmente os artefatos transitórios;
- uma falha do kernel nunca substitui silenciosamente a operação por Filling ou por geometria visual artificial;
- toda operação exibe diagnóstico, entidades afetadas, tolerâncias e validade antes de habilitar `Apply`.

## 2. Padrão de interação comum

### 2.1 Estados do comando

Toda ferramenta segue a mesma máquina de estados:

`Idle → Selecting Inputs → Ready → Preview Computing → Preview Valid/Invalid → Apply ou Cancel`.

- `Apply` permanece desabilitado até existir preview válido.
- Uma alteração de seleção ou parâmetro invalida o preview anterior e solicita novo cálculo.
- Durante cálculo, o painel mostra progresso e impede submissões duplicadas.
- Erro recuperável mantém o comando aberto e identifica o campo ou seleção problemática.
- Mudança para outro comando pede confirmação apenas quando existe preview válido ainda não aplicado.

### 2.2 Linguagem visual

| Elemento | Cor/representação |
|---|---|
| Entidade a modificar | ciano, contorno reforçado |
| Referência/alvo | verde |
| Boundary/Edge ativa | magenta |
| Preview válido | laranja, 55% de opacidade |
| Resultado selecionado | amarelo |
| Entrada inválida/conflito | vermelho pulsante discreto |
| Geometria não afetada | cor normal, atenuada durante o comando |

O preview deve respeitar profundidade, permanecer selecionável apenas para inspeção e nunca entrar no Explorer como entidade definitiva.

### 2.3 Controles comuns

- `Enter`: Apply, somente com preview válido.
- `Esc`: Cancel; em uma etapa de seleção ainda vazia, encerra imediatamente.
- `Ctrl+Z`/`Ctrl+Y`: indisponíveis enquanto há preview; voltam a atuar após Apply ou Cancel.
- Clique no viewport ou Explorer: seleciona a entrada solicitada na etapa atual.
- `Ctrl+clique`: adiciona/remover múltiplas boundaries/edges quando a ferramenta permitir.
- `Backspace`: remove a última entrada do coletor atual, sem apagar geometria documental.
- Tooltip e barra de estado sempre informam a entrada esperada.

### 2.4 Estrutura de UI

Toolbar `Surface`:

- grupo `Edit`: Match, Boundary Extend, Boundary Trim;
- grupo `Create/Transition`: Blend;
- grupo `Offset`: Offset + Walls.

Cada comando abre um painel de tarefa não modal à direita. O painel contém, nesta ordem:

1. entradas;
2. parâmetros;
3. qualidade/continuidade;
4. diagnóstico do preview;
5. `Preview`, `Apply`, `Cancel`.

O menu de contexto apresenta o comando apenas quando a seleção atual contém uma combinação potencialmente compatível. A toolbar permanece acessível e conduz a seleção passo a passo.

## 3. Match Surface

### 3.1 Fluxo do operador

1. Acionar `Surface > Edit > Match`.
2. Selecionar a Surface/Face a modificar.
3. Selecionar a Boundary/Edge dessa superfície.
4. Selecionar a Face/Surface alvo ou uma Boundary alvo associada a uma superfície de suporte.
5. Escolher continuidade `G0`, `G1` ou `G2`.
6. Ajustar tolerância e, quando disponível, lado/influência da deformação.
7. Inspecionar o preview e os erros medidos.
8. Aplicar ou cancelar.

### 3.2 Entradas aceitas

- **Superfície móvel:** Surface ou Face.
- **Limite móvel:** Boundary, Edge, Curve, Wire, Section compatível ou contorno de Sketch.
- **Alvo:** Surface, Face, Boundary ou Edge com superfície de suporte.
- Curves/Wires/Sections são materializados transitoriamente pelo resolver existente.
- Para G1/G2, o alvo deve permitir recuperar a superfície de suporte e sua informação diferencial.

### 3.3 Ordem de seleção

`Surface móvel → Boundary móvel → Surface/Face/Boundary alvo → continuidade → Preview`.

Seleções prévias compatíveis preenchem os campos nessa ordem. Seleção ambígua abre somente um pequeno seletor de função: `Modificar`, `Boundary` ou `Alvo`.

### 3.4 Preview

- Aparece após as três entradas e os parâmetros mínimos serem válidos.
- A superfície original permanece ciano; o alvo fica verde; a boundary casada fica magenta.
- O resultado é laranja translúcido.
- Vetores discretos ao longo do limite representam posição para G0, tangentes/normais para G1 e pente de curvatura para G2.
- Atualiza após mudança de continuidade, tolerância ou seleção, com debounce curto para campos numéricos.
- Gaps fora da tolerância aparecem em vermelho e tornam o preview inválido.

### 3.5 Apply

`Apply` fica disponível somente quando o kernel retornar resultado válido e os erros G0/G1/G2 estiverem dentro da tolerância aprovada. Nesse momento é criado o `ShapeHandle` definitivo, a Surface resultante substitui ou gera revisão da entidade móvel conforme a política documental existente, e a operação entra no histórico/Undo.

### 3.6 Cancel

Descarta o ShapeHandle transitório, restaura visibilidade/cores originais, limpa os coletores de seleção e fecha o painel sem revisão documental.

### 3.7 Engineering Assistant

- “G1/G2 requer uma superfície de suporte válida no alvo.”
- “A tolerância solicitada não foi atingida; revise a boundary ou reduza a continuidade.”
- “O Match alterará uma Surface associada. Deseja criar Working Copy?”
- Após preview válido: “Continuidade solicitada e medida estão dentro da tolerância.”

### 3.8 Property Inspector

- Surface e Boundary móveis;
- alvo e superfície de suporte;
- continuidade solicitada e obtida;
- erro máximo/médio G0;
- erro angular G1;
- diferença de curvatura G2;
- tolerâncias;
- número de amostras/restrições;
- faces afetadas;
- validade topológica e diagnóstico `OK`, `Atenção` ou `Crítico`.

### 3.9 UX

- Ícone: duas superfícies com bordas convergindo.
- Cursor: badge `M`; muda para boundary e alvo conforme a etapa.
- Menu de contexto em Face/Surface: `Match Surface…`.
- Tooltip explica a ordem das três seleções.
- Atalho proposto: `M`, `S` em sequência dentro do workbench Surface; não conflitar com Move global.

### 3.10 Smoke Test planejado

No Release Windows, exclusivamente pela interface:

1. abrir projeto com duas faces/superfícies adequadas;
2. executar Match G0 e confirmar preview, métricas e Apply;
3. Undo/Redo;
4. repetir com G1;
5. executar G2 em entrada suportada e confirmar métricas;
6. provocar alvo sem suporte para validar bloqueio explícito;
7. salvar, fechar e reabrir;
8. confirmar geometria, continuidade, histórico e ausência de preview residual.

## 4. Blend Surface

### 4.1 Fluxo do operador

1. Acionar `Surface > Create/Transition > Blend`.
2. Selecionar duas Faces/Surfaces ou a Edge compartilhada.
3. Se não houver topologia compartilhada, selecionar as duas Boundaries correspondentes.
4. Definir raio constante ou parâmetros suportados pela rota oficial.
5. Definir continuidade disponível.
6. Inspecionar preview, extensão consumida nas faces e diagnóstico.
7. Aplicar ou cancelar.

### 4.2 Entradas aceitas

- Edge compartilhada de Shell/Solid;
- duas Faces/Surfaces adjacentes;
- duas Boundaries/Edges/Curves/Wires compatíveis, cada uma associada à sua superfície de suporte;
- raio numérico e, futuramente dentro do mesmo contrato aprovado, lei oficial suportada pelo OCCT.

Sketch e Section só são aceitos como boundary quando houver associação inequívoca com a superfície de suporte; não podem simular duas faces ausentes.

### 4.3 Ordem de seleção

- Rota compartilhada: `Edge compartilhada → raio → Preview`.
- Rota geral: `Face/Surface 1 → Boundary 1 → Face/Surface 2 → Boundary 2 → parâmetros → Preview`.

### 4.4 Preview

- Surge quando a rota selecionada possui todas as entradas obrigatórias e raio válido.
- Faces de suporte ficam ciano e verde; boundaries ficam magenta; faixa do blend fica laranja translúcida.
- Linhas de seção discretas indicam raio e orientação.
- Atualização em tempo real ao editar raio/continuidade.
- Regiões consumidas ou recortadas nas faces são destacadas por hachura discreta.
- Auto-interseção, raio inviável ou falha topológica colore a zona problemática de vermelho e desabilita Apply.

### 4.5 Apply

Cria o ShapeHandle definitivo somente depois de o preview produzir shape válido. Na rota compartilhada, persiste o Shell/Solid modificado. Na rota geral, persiste a Face de blend e as revisões topológicas necessárias, sem apresentar Filling como Blend.

### 4.6 Cancel

Destrói blend e trims transitórios, restaura as faces originais e não altera relações documentais.

### 4.7 Engineering Assistant

- “Foi detectada uma Edge compartilhada; será usada a rota de fillet oficial.”
- “As superfícies não compartilham topologia; selecione uma Boundary em cada suporte.”
- “O raio excede o espaço geométrico disponível.”
- “A operação modificará faces dependentes. Deseja criar Working Copy?”

### 4.8 Property Inspector

- rota usada: shared-edge ou general-boundary;
- faces, boundaries e Edge compartilhada;
- raio mínimo/máximo ou lei;
- continuidade interna solicitada/obtida;
- tolerância angular com suportes;
- faces geradas/modificadas;
- auto-interseções;
- validade do Shell/Solid;
- diagnóstico final.

### 4.9 UX

- Ícone: faixa arredondada entre duas faces.
- Cursor: badge `B`; realça automaticamente Edges elegíveis.
- Menu de contexto em Edge compartilhada: `Create Blend…`.
- Atalho proposto: `B`, `L` no workbench Surface.
- O painel identifica claramente `Shared Edge Blend` ou `Boundary Blend`; a diferença técnica não exige conversão manual.

### 4.10 Smoke Test planejado

1. abrir shape com duas faces adjacentes;
2. selecionar Edge compartilhada e criar blend de raio válido;
3. alterar raio e confirmar atualização do preview;
4. validar recusa para raio inviável;
5. Apply, Undo e Redo;
6. testar rota de boundaries desconectadas quando suportada pela implementação aprovada;
7. salvar/reabrir e confirmar topologia e aparência;
8. confirmar que nenhuma falha retorna uma superfície de Filling rotulada como Blend.

## 5. Offset + Walls

### 5.1 Fluxo do operador

1. Acionar `Surface > Offset > Offset + Walls`.
2. Selecionar Face, Surface, Shell ou Body compatível.
3. Para Shell/Solid, selecionar opcionalmente faces de abertura/remoção.
4. Informar distância e direção (`Inside`, `Outside` ou inverter seta).
5. Escolher tipo de união suportado e opção `Close result` quando aplicável.
6. Inspecionar offset, paredes e estado de fechamento.
7. Aplicar ou cancelar.

### 5.2 Entradas aceitas

- Face/Surface isolada;
- Shell;
- Body/Solid;
- Faces de abertura pertencentes ao shape principal;
- Boundaries/Wires do shape são inferidos; seleção explícita é permitida para limitar paredes quando a rota aberta exigir.

### 5.3 Ordem de seleção

`Shape principal → faces de abertura ou boundaries laterais → distância/direção → opção de fechamento → Preview`.

### 5.4 Preview

- Aparece após shape e distância não nula válidos.
- Original fica ciano; offset fica laranja translúcido; paredes ficam em laranja mais escuro; faces removidas ficam vermelhas hachuradas.
- Uma seta normal indica sinal e distância.
- Atualiza em tempo real com distância, direção, join e abertura.
- Badge no viewport informa `Open Shell`, `Closed Shell` ou `Solid`.
- Auto-interseções e paredes não construídas ficam vermelhas.

### 5.5 Apply

Cria o ShapeHandle definitivo após validação. O tipo persistido deve refletir o resultado real: Surface/Face, Shell ou Solid. `Apply` não pode promover Shell aberto a Solid.

### 5.6 Cancel

Remove offset, paredes, tampas e marcações transitórias; restaura o shape original sem alteração.

### 5.7 Engineering Assistant

- “A distância excede o raio local estimado em uma região.”
- “O resultado é um Shell aberto; selecione Close result para tentar fechá-lo.”
- “As faces selecionadas serão removidas como aberturas.”
- “Deseja manter o original em uma Working Copy?”

### 5.8 Property Inspector

- shape de origem e tipo;
- distância assinada;
- direção;
- join utilizado;
- faces removidas;
- paredes criadas/que falharam;
- tolerância de sewing;
- número de shells e free edges;
- fechado/aberto;
- tipo topológico final;
- auto-interseções e diagnóstico.

### 5.9 UX

- Ícone: duas superfícies paralelas ligadas por paredes.
- Cursor: badge `O+W` e seta normal manipulável apenas como editor do valor, não como novo gizmo arquitetural.
- Menu de contexto em Face/Shell/Body: `Offset + Walls…`.
- Atalho proposto: `O`, `W`.
- Controle de distância aceita digitação, incremento pelo mouse e inversão por botão central no manipulador.

### 5.10 Smoke Test planejado

1. selecionar Face aberta, gerar offset com paredes e confirmar Shell;
2. inverter direção e observar preview;
3. selecionar Body/Solid, remover face de abertura e executar thick solid;
4. validar relatório de paredes, free edges e estado topológico;
5. provocar espessura inviável e confirmar Apply bloqueado;
6. Apply, Undo, Redo;
7. salvar/reabrir e confirmar o tipo e a geometria finais.

## 6. Boundary Extend

### 6.1 Fluxo do operador

1. Acionar `Surface > Edit > Boundary Extend`.
2. Selecionar Surface/Face.
3. Selecionar a Boundary/Edge a estender.
4. Escolher modo `By Length` ou `Up To Geometry`.
5. Informar comprimento e continuidade, ou selecionar o alvo.
6. Definir lado quando a boundary tiver duas soluções possíveis.
7. Inspecionar preview e aplicar ou cancelar.

### 6.2 Entradas aceitas

- Surface/Face proprietária da boundary;
- Boundary, Edge, Curve, Wire, Section ou contorno de Sketch compatível;
- alvo de `Up To`: Plane, Face, Surface, Boundary, Edge, Curve ou Wire;
- valor numérico de comprimento para `By Length`.

### 6.3 Ordem de seleção

- Por comprimento: `Surface/Face → Boundary → lado → comprimento/continuidade → Preview`.
- Até geometria: `Surface/Face → Boundary → alvo → lado/continuidade → Preview`.

### 6.4 Preview

- Surge depois que modo e entradas mínimas forem válidos.
- Face original em ciano, boundary ativa em magenta, alvo em verde e extensão em laranja translúcido.
- Marcadores indicam lado U/V e before/after quando aplicável.
- Atualiza em tempo real ao mudar comprimento, lado ou continuidade.
- O trecho adicionado recebe isolinhas discretas para leitura da deformação.
- Extensão excessiva, alvo ambíguo ou auto-interseção gera vermelho e bloqueia Apply.

### 6.5 Apply

O ShapeHandle definitivo é criado somente após a reconstrução e validação da Face completa. A operação registra a boundary anterior, a nova boundary, o comprimento real e o alvo utilizado.

### 6.6 Cancel

Descarta superfície/curvas estendidas transitórias, elimina marcadores e mantém a Face original intacta.

### 6.7 Engineering Assistant

- “A extensão é grande em relação à dimensão da superfície e pode perder qualidade.”
- “A superfície é periódica na direção escolhida; esta extensão não é aplicável.”
- “Foram encontrados múltiplos encontros com o alvo; selecione a solução desejada.”
- “A continuidade selecionada descreve a extensão interna, não um Match com outra superfície.”

### 6.8 Property Inspector

- Surface/Face e Boundary;
- modo e alvo;
- direção paramétrica/lado;
- comprimento solicitado e obtido;
- continuidade solicitada;
- tolerância;
- interseções encontradas;
- alteração de área;
- validade da boundary/face;
- diagnóstico final.

### 6.9 UX

- Ícone: boundary com seta de prolongamento.
- Cursor: badge `EX`; seta junto à boundary indica o lado.
- Menu de contexto em Boundary/Edge: `Extend Boundary…`.
- Atalho proposto: `E`, `B`.
- Clique na seta alterna o lado; não altera o documento antes de Apply.

### 6.10 Smoke Test planejado

1. estender boundary de uma Face por comprimento;
2. alternar lado e continuidade, confirmando preview;
3. estender até Plane/Face alvo;
4. validar escolha quando existirem múltiplos encontros;
5. validar recusa de extensão periódica/inviável;
6. Apply, Undo, Redo;
7. salvar/reabrir e confirmar boundary, Face e parâmetros.

## 7. Boundary Trim

### 7.1 Fluxo do operador

1. Acionar `Surface > Edit > Boundary Trim`.
2. Selecionar Surface/Face.
3. Selecionar Boundary/Edge a recortar.
4. Selecionar Curve, Wire, Plane, Face ou Surface de corte.
5. Clicar na região que deverá permanecer.
6. Inspecionar fragmentos, nova boundary e topologia.
7. Aplicar ou cancelar.

### 7.2 Entradas aceitas

- Surface/Face objeto;
- Boundary, Edge, Curve, Wire, Section ou contorno de Sketch do objeto;
- ferramenta: Plane, Surface, Face, Boundary, Curve, Edge, Wire, Section ou Sketch compatível;
- ponto de retenção escolhido no viewport.

### 7.3 Ordem de seleção

`Surface/Face → Boundary → ferramenta de corte → região a manter → Preview`.

Quando o comando for iniciado por seleção prévia de Face + ferramenta, a boundary poderá ser inferida somente se houver uma única boundary intersectada; caso contrário, o usuário deverá escolhê-la.

### 7.4 Preview

- As interseções aparecem imediatamente após selecionar a ferramenta.
- Face original em ciano, ferramenta em verde, boundary em magenta.
- Regiões candidatas recebem números e hover amarelo.
- A região escolhida permanece laranja translúcida; regiões descartadas ficam vermelhas e atenuadas.
- Atualiza quando ferramenta, tolerância ou região retida mudar.
- Fragmentos ambíguos, loops abertos ou gaps aparecem em vermelho e bloqueiam Apply.

### 7.5 Apply

Cria o ShapeHandle definitivo apenas após o usuário escolher inequivocamente o domínio retido e a Face reconstruída passar na validação. Registra ferramenta, fragmentos, domínio preservado e tolerância.

### 7.6 Cancel

Descarta splitter, interseções e faces transitórias; remove numeração de regiões e restaura seleção/visual original.

### 7.7 Engineering Assistant

- “Foram criados N fragmentos; selecione a região que deve permanecer.”
- “O corte é tangencial/coincidente e não define um domínio inequívoco.”
- “O resultado possui boundary aberta ou gap acima da tolerância.”
- “Inner wires afetados serão preservados/removidos conforme a região escolhida.”

### 7.8 Property Inspector

- Face/Surface e Boundary objeto;
- ferramenta de corte;
- número de interseções e fragmentos;
- região retida;
- comprimento removido/mantido;
- outer wire e inner wires antes/depois;
- gaps e tolerância;
- validade e orientação da Face;
- entidades afetadas e diagnóstico final.

### 7.9 UX

- Ícone: boundary atravessada por uma lâmina/linha de corte.
- Cursor: badge de tesoura; sobre regiões muda para `Keep`.
- Menu de contexto: `Trim Boundary…` em Boundary/Edge e `Use as Trim Tool` em Curves/Planes/Faces.
- Atalho proposto: `T`, `B`.
- Clique único escolhe a região; duplo clique não aplica para evitar commits acidentais. Apply continua explícito.

### 7.10 Smoke Test planejado

1. recortar uma Face por Curve/Wire e escolher região;
2. repetir com Plane/Surface;
3. confirmar atualização do preview ao alternar domínio retido;
4. validar inner wire preservado em caso aplicável;
5. provocar corte tangencial/ambíguo e confirmar bloqueio;
6. Apply, Undo, Redo;
7. salvar/reabrir e verificar Face, boundaries, parâmetros e histórico.

## 8. Smoke Test integrado planejado para a Categoria B

Depois da implementação e antes de QA, o Release Windows deverá executar exclusivamente pela interface:

`Abrir projeto → Match G0/G1/G2 → Blend por Edge compartilhada → Offset + Walls → Boundary Extend por comprimento → Boundary Extend até alvo → Boundary Trim → Undo de cada operação → Redo de cada operação → Salvar → Fechar → Reabrir → verificar Shapes, topologia, parâmetros, relatórios e viewport`.

Critérios transversais:

- todos os comandos abrem painel funcional;
- preview nunca altera Explorer ou documento;
- Apply só habilita para shape válido;
- Cancel não deixa ShapeHandle, entidade ou desenho residual;
- Property Inspector e Engineering Assistant refletem o comando ativo e o resultado;
- nenhuma operação altera entidades não declaradas no relatório de impacto;
- persistência restaura resultado e parâmetros;
- Undo/Redo restaura tanto geometria quanto relações topológicas;
- falhas são técnicas e específicas, nunca genéricas nem substituídas por outro operador.

## 9. Gate de saída do Design Review

A implementação só poderá começar após aprovação explícita deste documento. Depois disso, o ciclo obrigatório será:

`Implementação → Feature Freeze → Smoke Test → QA → Aprovação`.

Categoria C permanece bloqueada durante todo esse ciclo.
