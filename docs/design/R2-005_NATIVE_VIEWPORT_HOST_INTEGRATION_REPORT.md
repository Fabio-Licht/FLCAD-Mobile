# R2-005 — Native Viewport Host Integration

## Resultado desta implementação

O Release Windows do FLCAD agora contém um `NativeViewportHost` registrado no
runner principal. O host publica uma textura D3D11 por meio da API oficial de
External Texture do Flutter Windows. Não existe janela auxiliar nem processo do
Render Lab.

```text
CadSceneGraph (somente leitura)
        │
        ▼
CadSceneDisplayAdapter
        │  snapshot inicial / deltas
        ▼
MethodChannel: flcad/native_viewport
        │
        ▼
NativeViewportHost ── D3D11 texture ── Flutter Texture widget
        │
        └─ Toolbar / Explorer / Inspector / overlays continuam Flutter
```

## Dependência

A dependência é unidirecional. O host nativo recebe dados serializados da
camada de apresentação e não inclui nem acessa `CadDocument`, `CadRuntime`,
Geometry Kernel, Recognition, Sketch, Surface, Solid ou Engineering Assistant.

Nenhum contrato público desses componentes foi alterado.

## Snapshot e delta

- o primeiro frame envia todas as display meshes;
- alterações geométricas enviam somente a entidade modificada;
- seleção/visibilidade enviam somente estado, sem reenviar os buffers;
- remoção envia um delta tombstone;
- notificações sucessivas são agrupadas em uma janela de 16 ms.

## Composição Flutter

`IntegratedCadViewportWidget` mantém o widget profissional existente como
camada de interação e overlay. Quando Native GPU está ativo:

- a textura D3D11 desenha as meshes;
- referências, WCS, grid, labels e controles continuam no Canvas transparente;
- picking é convertido para o mesmo `CadViewportPick` já consumido pela
  Plataforma;
- a câmera do Canvas envia a mesma matriz view-projection ao host nativo;
- existe alternância visível entre `Flutter Canvas` e `Native GPU`.

Se a criação da textura falhar, a seleção retorna automaticamente ao Canvas.

## Diagnóstico

Em Debug, o painel apresenta:

- FPS;
- draw calls;
- triângulos;
- tempo de upload;
- tempo de renderização;
- tempo de picking;
- GPU.

O painel não é criado em Release.

## Validação executada

- `flutter analyze`: sem problemas;
- 24 testes do viewport profissional: aprovados;
- teste específico de snapshot/delta: aprovado;
- `flutter build windows --release`: aprovado;
- abertura, fechamento e segunda abertura do Release: aprovados;
- processo permaneceu responsivo nas duas inicializações.

Executável: `build/windows/x64/runner/Release/FLCAD Reverse AI.exe`.

## Estado do gate

A arquitetura de host, textura externa, fallback, snapshot/delta e composição
foi implementada. O gate operacional completo ainda não deve ser declarado
aprovado nesta revisão: o smoke automatizado não concluiu o fluxo de importação
e seleção dentro do workspace, e o host integrado ainda utiliza o bridge de
picking compatível da Plataforma enquanto o ID Buffer do R2-004 é transferido
do Render Lab para o `NativeViewportHost`.

Portanto, o Release é apropriado para validação incremental, mas ainda não para
remover ou desativar o fallback Canvas.
