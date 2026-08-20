# R2-006A — Operational Navigation Contract

Status: **APPROVED — ARCHITECTURE FREEZE**

## Princípio operacional

Durante o Pan, o operador percebe exclusivamente a translação contínua da
`Operational Scene`. O gesto deve transmitir contato direto: o cursor empurra a
`Operational Scene`; a câmera nunca parece perseguir o cursor.

O Pan não possui início, meio ou fim perceptíveis. O primeiro movimento, o
movimento contínuo e a parada formam um único deslocamento, sem saltos,
acomodação, atraso ou transição visível.

## Unidade de publicação

A Plataforma nunca publica elementos visuais individuais durante a navegação.
A única unidade publicável é uma revisão completa e imutável da
`Operational Scene`.

Todos os consumidores recebem exatamente a mesma revisão. Uma revisão somente
pode ser apresentada quando estiver completa. É proibida a apresentação parcial
ou a combinação de conteúdo proveniente de revisões diferentes.

```text
Navigation Gesture
        ↓
Camera System
        ↓
Operational Scene — Revision N
        ↓
Presentation Consumers
        ↓
Single Composed Frame — Revision N
```

## Corpo rígido visual

Durante todo o Pan, a `Operational Scene` comporta-se como um único corpo
rígido. Entre duas revisões consecutivas, a única mudança visual autorizada é a
translação conjunta da cena no viewport.

Devem permanecer invariáveis:

- orientação aparente;
- escala aparente;
- distância operacional;
- centro visual da região controlada;
- perspectiva;
- silhueta;
- relações espaciais internas;
- estados de apresentação.

Nenhuma região visual pode percorrer trajetória diferente das demais. O
operador nunca pode perceber pivô, inclinação, torção, escorregamento ou
deformação perceptiva.

## Propriedade e responsabilidades

O `cad_camera_system` é o proprietário exclusivo do estado da câmera. O
interpretador de gestos produz comandos de navegação, mas não modifica estado
visual. Os consumidores de apresentação recebem revisões imutáveis da
`Operational Scene` e não reinterpretam, suavizam ou complementam o Pan.

Pan, Orbit, Zoom e Fit utilizam o mesmo estado interno. Nenhum consumidor ou
backend mantém uma câmera operacional independente.

## Consistência de revisão

Cada revisão da `Operational Scene` possui uma identidade monotônica. Todos os
consumidores devem confirmar a mesma identidade antes da composição do quadro.
Até que a nova revisão esteja integralmente disponível, a revisão anterior
permanece apresentada.

É proibido:

- apresentar consumidores em revisões diferentes;
- publicar uma revisão incompleta;
- atualizar uma parte da apresentação independentemente;
- aplicar novamente um comando já incorporado à revisão;
- permitir que um backend altere o estado recebido.

## Fluxo oficial

```text
Operator Input
      ↓
Navigation Gesture Interpreter
      ↓
Camera Command
      ↓
cad_camera_system
      ↓
Operational Scene Revision
      ↓
Atomic Presentation
```

## Critério de aprovação

O Pan é aprovado somente quando o operador percebe a `Operational Scene` presa
ao gesto durante todo o deslocamento. Se qualquer região parecer mover-se de
forma diferente das demais, se houver atualização independente ou se surgir a
sensação de rotação, o comportamento permanece reprovado.

## Freeze

Este contrato está congelado. A próxima etapa é exclusivamente implementação.
Qualquer alteração arquitetural futura exige uma limitação real comprovada
durante o desenvolvimento.
