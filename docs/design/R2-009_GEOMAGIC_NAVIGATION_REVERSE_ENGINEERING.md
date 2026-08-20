# R2-009 — Geomagic Navigation Reverse Engineering

Status: estudo operacional, sem implementação

## Referência observada

Vídeo: `Gravando TESTE PAN GEOMAGIC COM AS CONFIGURAÇÕES DO CATIA.mp4`

- duração: 27,99 s;
- captura: 30 quadros por segundo;
- resolução: 1196 × 762;
- aplicação: Geomagic Design X com perfil CATIA, conforme identificação do operador.

Este documento registra somente comportamentos visíveis na gravação. Ele não
deduz algoritmo, estrutura de câmera, matriz ou implementação interna. O vídeo
não mostra o estado dos botões do mouse; por isso, os gestos abaixo são
classificados pelo resultado visual apresentado na tela.

A leitura inicial foi feita em toda a duração, em intervalos de 0,5 s. As quatro
transições de comportamento foram então verificadas em 120 quadros consecutivos
(30 quadros em cada transição), preservando a cadência original de 30 fps.

## Sequência observada

| Intervalo aproximado | Início | Meio | Fim | Comportamento visível |
|---|---|---|---|---|
| 0,0–5,8 s | Peça enquadrada | A cena atravessa repetidamente o viewport e chega a sair parcialmente da tela | Retorna ao enquadramento | Translação: orientação e tamanho aparente permanecem constantes |
| 6,0–11,2 s | Peça enquadrada | A silhueta revela sucessivamente lateral, cavidade interna e extremidades | Termina em outra orientação | Orbit: mudança contínua de orientação, sem saltos visíveis |
| 11,3–14,6 s | Vista média | A geometria ocupa quase todo o viewport e depois se afasta | A peça passa para uma vista geral | Zoom: mudança de tamanho com orientação visual preservada |
| 14,7–16,3 s | Peça pequena e enquadrada | A silhueta e os planos mudam continuamente de orientação | Termina mostrando a cavidade inferior | Orbit: mudança contínua de orientação |
| 16,4–25,2 s | Peça pequena e enquadrada | A cena percorre centro, bordas e cantos, ficando parcialmente fora da tela | Retorna para uma posição legível | Translação: a cena mantém orientação e tamanho aparente |
| 25,3–27,9 s | Peça enquadrada | Não há transformação relevante perceptível | Estado permanece estável | Repouso: não se observa movimento residual |

Os limites são aproximados porque a gravação não expõe eventos de entrada.

## Pan — o que realmente acontece

### Início

- A cena começa a responder no primeiro deslocamento visível.
- Não aparece uma preparação, recentralização ou mudança de escala antes da
  translação.
- A orientação existente no instante inicial é preservada.

### Meio

- Peça, planos e demais referências espaciais atravessam o viewport juntos.
- A silhueta conserva a mesma orientação aparente.
- O tamanho aparente da peça permanece estável.
- Os planos mantêm seus ângulos e suas interseções relativas.
- Não se observa uma região da peça chegando antes de outra.
- A cena pode sair parcialmente ou quase totalmente do viewport sem ser
  automaticamente reenquadrada.
- A triad fixa no canto inferior esquerdo não acompanha a translação.

### Fim

- A cena para na posição alcançada.
- Não se observa continuação, retorno, assentamento ou correção posterior.
- Orientação e escala no último quadro do gesto permanecem iguais às observadas
  durante a translação.

### Resultado operacional observado

O Pan se apresenta como deslocamento direto e rígido da cena projetada. No
vídeo, ele não acrescenta rotação, zoom, reenquadramento nem movimento residual.

## Orbit — o que realmente acontece

### Início

- A rotação começa a partir da orientação e do enquadramento existentes.
- Não se observa salto inicial da peça.
- Não há Fit ou mudança brusca de escala antes da rotação.

### Meio

- A silhueta muda continuamente: faces externas, cavidades e extremidades são
  reveladas em sequência.
- Peça e referências espaciais giram de forma coerente entre si.
- Não se observa troca perceptível de pivô dentro do mesmo gesto contínuo.
- A região em torno da qual a peça gira permanece visualmente previsível e
  associada à própria geometria.
- Não se observa aceleração independente depois que o cursor deixa de comandar
  o movimento.

### Fim

- A orientação alcançada é mantida.
- Não se observa rotação residual, correção automática ou retorno.
- O próximo gesto parte do estado visual deixado pelo anterior.

### Resultado operacional observado

O Orbit se apresenta como manipulação direta da orientação da peça. A rotação
não parece ocorrer em torno de um ponto distante ou externo ao contexto visual
da geometria durante a sequência registrada.

## Zoom — o que realmente acontece

### Início

- O tamanho da peça começa a mudar sem alteração prévia de orientação.
- Não se observa salto lateral antecedendo a aproximação ou o afastamento.

### Meio

- A variação de escala é contínua entre os quadros observados.
- A orientação e a silhueta direcional permanecem iguais; muda principalmente
  a ocupação da peça no viewport.
- A passagem entre vista de detalhe e vista geral não produz Orbit visível.
- Não se observa reenquadramento automático durante a sequência.

### Fim

- A escala final é mantida.
- Não se observa continuação inercial ou correção posterior.

### Resultado operacional observado

O Zoom se apresenta como aproximação ou afastamento contínuo da região já
observada. No trecho gravado, ele não introduz uma nova orientação.

## Centro de rotação

O que o vídeo demonstra:

- durante o Orbit contínuo, não existe mudança perceptível de centro;
- a rotação permanece associada à região ocupada pela peça;
- o centro não salta para o centro do viewport nem para uma referência distante
  durante o gesto;
- Pan e Zoom não mostram uma mudança visível do centro de rotação.

O que o vídeo não permite afirmar:

- a coordenada tridimensional exata do centro;
- se o centro corresponde a um ponto selecionado, ponto sob o cursor, centro da
  geometria ou outro estado interno;
- em quais eventos internos esse centro é redefinido;
- se uma seleção não mostrada poderia alterá-lo.

Conclusão estritamente observável: o centro permanece perceptivamente estável
durante cada Orbit registrado. A gravação não prova sua regra interna de
definição ou mudança.

## O operador percebe câmera ou peça?

O comportamento registrado comunica manipulação da peça.

Essa percepção é sustentada visualmente por:

1. resposta imediata ao gesto, sem etapa intermediária visível;
2. coerência rígida entre peça, planos e referências espaciais;
3. Pan sem mudança perceptível de orientação ou escala;
4. Orbit associado à região da geometria, sem pivô errante visível;
5. Zoom sem rotação ou reenquadramento inesperado;
6. ausência de movimento residual ao terminar qualquer gesto;
7. continuidade do estado final: cada gesto seguinte começa exatamente da vista
   deixada pelo gesto anterior;
8. estabilidade das referências fixas de interface, especialmente a triad do
   canto, enquanto a cena espacial é manipulada.

## Resposta objetiva da R2-009

Durante a navegação mostrada no Geomagic:

- o Pan translada rigidamente a cena, preservando orientação e escala;
- o Orbit altera continuamente a orientação em torno de uma região visualmente
  estável da própria peça;
- o Zoom altera continuamente a escala da região observada, sem introduzir
  rotação;
- o centro de rotação não muda perceptivelmente durante o Orbit, mas o vídeo não
  revela sua definição interna;
- o início, o meio e o fim dos gestos formam uma resposta direta, sem saltos,
  inércia ou correções posteriores;
- o conjunto transmite ao operador a sensação de manipular a peça e suas
  referências espaciais, não de administrar uma câmera.

Nenhuma proposta de implementação faz parte deste estudo.
