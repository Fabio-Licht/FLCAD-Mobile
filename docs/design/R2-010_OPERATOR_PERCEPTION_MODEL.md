# Operator Perception Model

Programa 2 — R2-010 Operator Perception Study  
Status: estudo perceptivo, sem implementação

## Pergunta central

Quais características perceptivas fazem um operador experiente acreditar que
está segurando a peça, em vez de movimentar uma câmera?

## Resposta curta

O operador sente que segura a peça quando o resultado visual confirma, a cada
instante, a previsão produzida pelo seu gesto.

A sensação não depende de a implementação transformar realmente a peça ou a
câmera. Para a percepção, ela surge quando cinco condições coexistem:

1. **Agência:** a cena responde como consequência imediata da mão.
2. **Correspondência espacial:** direção, amplitude e ritmo vistos correspondem
   ao gesto executado.
3. **Rigidez:** todos os sinais pertencentes à peça mantêm relações compatíveis
   com um único corpo sólido.
4. **Referência estável:** o ponto ou a região que organiza o gesto permanece
   previsível.
5. **Continuidade:** não existe descontinuidade entre intenção, movimento,
   parada e gesto seguinte.

Quando uma dessas condições é quebrada, o operador deixa de atribuir o movimento
diretamente à mão. Nesse momento, passa a perceber uma camada intermediária — a
“câmera”.

## 1. Agência perceptiva

Agência é a sensação de que “meu gesto causou este movimento”. Estudos
psicofísicos mostram que ela depende conjuntamente da contingência temporal e da
integridade do retorno visual. Atraso, ocultação ou resultado incompatível com o
comando motor reduzem essa atribuição de controle ([Imaizumi e Tanno,
2021](https://pmc.ncbi.nlm.nih.gov/articles/PMC8047305/)). A congruência temporal
entre movimento e retorno visual também participa diretamente dessa sensação
([Walsh et al., 2010](https://pmc.ncbi.nlm.nih.gov/articles/PMC2570482/)).

Para o operador de CAD, agência existe quando:

- a resposta começa junto com o gesto percebido;
- cada continuação do gesto produz uma continuação visual correspondente;
- a resposta não muda silenciosamente de regra durante a ação;
- a parada da mão coincide com a parada da cena;
- nenhum ajuste autônomo aparece depois da ação.

O operador não precisa conhecer a regra. Ele precisa conseguir prevê-la sem
pensar.

## 2. Correspondência entre mão e imagem

O cérebro compara a consequência visual recebida com a consequência esperada do
movimento. Uma diferença espacial — direção alterada, ganho variável, curva
inesperada ou atraso — produz erro sensório-motor. Pessoas conseguem adaptar-se
a perturbações, mas isso exige aprendizagem e compensação; previsões visuais
estáveis melhoram tanto o controle quanto a extração perceptiva do estímulo em
movimento ([Yon et al., 2016](https://pmc.ncbi.nlm.nih.gov/articles/PMC4808085/)).

A sensação de contato direto requer:

- mesma direção percebida entre mão e resposta;
- proporção estável entre movimento físico e movimento visual;
- ausência de ganho dependente do instante, posição ou evento recebido;
- trajetória visual contínua, sem degraus;
- reversibilidade imediata: inverter a mão deve inverter o movimento percebido.

Se o operador precisa corrigir a própria mão para compensar o sistema, ele deixa
de sentir contato com a peça.

## 3. Corpo rígido percebido

O cérebro avalia rigidez a partir das relações temporais entre características
visuais. Não basta a geometria ser matematicamente rígida: trajetórias locais
incompatíveis podem tornar a não rigidez extremamente evidente já entre dois
quadros consecutivos ([Perotti, Todd e Norman,
1996](https://pubmed.ncbi.nlm.nih.gov/8710446/)). Características salientes da
forma ajudam o sistema visual a acompanhar o objeto e sustentar a percepção de
rotação rígida; velocidades inadequadas podem destruir essa percepção
([Kwon et al., 2024](https://pmc.ncbi.nlm.nih.gov/articles/PMC10848565/)).

Para parecer uma peça segurada:

- silhueta, filetes, furos, planos, arestas e detalhes devem pertencer ao mesmo
  movimento global;
- nenhum detalhe pode atrasar, antecipar, escorregar ou seguir trajetória
  incompatível com os demais;
- referências espaciais ligadas ao modelo precisam conservar suas relações com
  ele;
- o movimento deve preservar a identidade da forma entre quadros;
- velocidade e continuidade precisam permitir o rastreamento dos detalhes que o
  operador usa como pontos de referência.

Uma única característica saliente que pareça “solta” pode quebrar a leitura de
corpo rígido, mesmo quando o restante da imagem está correto.

## 4. Pan: por que o operador sente que move a peça?

Durante um Pan percebido como manipulação direta:

- todos os pontos visíveis percorrem trajetórias paralelas e coerentes;
- a orientação aparente não muda;
- a escala aparente não muda;
- a região inicialmente tomada como contato não escorrega em relação ao gesto;
- distâncias e alinhamentos internos permanecem constantes;
- o fundo e as referências fixas da interface oferecem uma moldura estável
  contra a qual a peça se desloca;
- quando a mão para, o deslocamento para no mesmo instante perceptivo.

O cérebro interpreta esse conjunto como uma folha ou peça arrastada sobre uma
base estável.

A sensação de câmera aparece quando há qualquer sinal concorrente:

- uma extremidade percorre trajetória diferente da outra;
- a silhueta muda discretamente;
- ocorre expansão, contração ou paralaxe não solicitada;
- o ponto de contato deriva;
- o ganho varia durante o gesto;
- a cena continua, corrige-se ou assenta depois da mão.

Mesmo uma alteração pequena pode ser percebida como pivotamento porque deixa de
existir uma explicação única de translação rígida para todos os sinais visuais.

## 5. Orbit: por que o operador sente que gira a peça?

O movimento de uma projeção bidimensional permite ao cérebro recuperar uma
estrutura tridimensional. Essa percepção depende da coerência temporal da forma
e da atualização das posições de suas características ao longo da rotação
([McCarthy et al., 2015](https://pmc.ncbi.nlm.nih.gov/articles/PMC4818573/)).

O Orbit parece uma peça girando na mão quando:

- existe uma região de apoio perceptivamente estável dentro ou junto da peça;
- cada detalhe percorre a trajetória esperada para uma única rotação rígida;
- detalhes próximos e distantes apresentam mudanças relativas coerentes com a
  profundidade da forma;
- o pivô não salta durante o gesto;
- a escala global não muda sem que o gesto comunique aproximação;
- o ganho permite acompanhar filetes, furos e mudanças de curvatura;
- a orientação final permanece exatamente onde a mão a deixou.

O operador percebe câmera quando a peça parece orbitar um ponto externo,
escorregar ao redor do cursor ou trocar de pivô. Nesses casos, o gesto deixa de
ser explicado como “girei esta peça” e passa a exigir a explicação “a vista se
moveu ao redor dela”.

## 6. Zoom: por que a referência visual permanece confortável?

O Zoom confortável preserva uma referência perceptiva enquanto altera a escala.
O cérebro precisa conseguir tratar os sucessivos quadros como a mesma região
que está apenas ficando maior ou menor.

Isso ocorre quando:

- uma característica ou região permanece como âncora visual durante toda a
  sequência;
- a expansão ou contração é contínua e monotônica;
- não aparece rotação simultânea não solicitada;
- a região observada não deriva lateralmente de modo imprevisível;
- eventos consecutivos pertencem perceptivamente ao mesmo gesto;
- detalhes entram e saem da vista progressivamente;
- a sequência termina sem salto, reenquadramento ou correção.

Sem uma âncora estável, o operador precisa procurar novamente a região de
trabalho após cada aproximação. Essa busca quebra a sensação de segurar a peça e
transforma o Zoom em administração da vista.

## 7. Transições entre gestos

A percepção não reinicia quando muda de Pan para Orbit ou Zoom. O cérebro mantém
uma previsão contínua do objeto e do espaço de trabalho.

Para preservar a manipulação direta:

- o último quadro de um gesto deve ser o primeiro estado do próximo;
- a região de trabalho deve conservar sua identidade;
- nenhum estado oculto pode produzir salto ao trocar de gesto;
- velocidade, pivô, escala e orientação só podem mudar como consequência
  perceptível da nova ação;
- a ausência momentânea de geometria sob o cursor não pode destruir a referência
  já estabelecida.

Uma ruptura pequena na transição é particularmente incômoda para o especialista:
ela contradiz o modelo interno construído durante muitas horas de trabalho.

## 8. O papel da experiência do operador

O especialista não avalia cada gesto conscientemente. Pela repetição, ele possui
um modelo interno que prevê a resposta do sistema. A estabilidade dessa previsão
reduz a necessidade de atenção; perturbações visuomotoras, ao contrário, exigem
compensação e aprendizagem explícita ou implícita
([McDougle et al., 2015](https://pmc.ncbi.nlm.nih.gov/articles/PMC4473515/)).

Consequentemente:

- consistência é mais importante que novidade;
- pequenas surpresas repetidas custam atenção e fadiga;
- um comportamento pode ser geometricamente válido e perceptivamente errado;
- conforto significa que a previsão do operador é confirmada antes que ele
  precise analisá-la;
- “esquecer a câmera” significa não gastar atenção corrigindo o instrumento.

## 9. Características necessárias do modelo perceptivo

| Característica | O que o operador percebe quando existe | O que percebe quando falta |
|---|---|---|
| Contingência temporal | “Minha mão moveu isto” | atraso, perseguição ou intermediário |
| Congruência espacial | contato direto | ganho estranho ou direção inesperada |
| Rigidez global | uma peça sólida | torção, escorregamento ou pivotamento |
| Âncora estável | domínio da região de trabalho | perda de foco e procura visual |
| Pivô previsível | peça girando na mão | câmera orbitando a cena |
| Escala coerente | aproximação controlada | salto ou perda da região |
| Continuidade | um único ato manipulativo | gestos desconectados |
| Parada coincidente | peça deixada no lugar | inércia ou correção autônoma |
| Referências estáveis | espaço de trabalho confiável | desorientação espacial |
| Repetibilidade | memória muscular | necessidade de vigilância |

## 10. Modelo final

O operador acredita que está segurando a peça quando percebe uma cadeia causal
única e sem contradições:

**intenção → gesto → resposta visual imediata → corpo rígido previsível → estado
final estável.**

Pan, Orbit e Zoom são apenas variações dessa mesma relação perceptiva:

- no Pan, o contato produz translação rígida;
- no Orbit, o contato produz rotação rígida em torno de uma região previsível;
- no Zoom, o contato preserva uma região enquanto sua escala muda;
- nas transições, a mesma peça e o mesmo contexto permanecem presentes.

Quando o retorno visual confirma continuamente a previsão da mão, a câmera
desaparece da consciência. Quando há atraso, deriva, mudança silenciosa de
referência, movimento relativo incompatível ou correção autônoma, a câmera volta
a ser percebida como um mecanismo entre o operador e a peça.

Este documento define um modelo perceptivo. Ele não prescreve câmera, algoritmo,
arquitetura ou implementação.
