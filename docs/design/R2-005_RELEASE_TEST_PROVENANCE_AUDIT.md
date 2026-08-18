# R2-005 — Release/Test Provenance Audit

## Conclusão

O teste e o Release incluem o mesmo arquivo-fonte
`native/render_engine/cad_camera_system.h`, mas **não executam o mesmo caminho
binário**. O teste prova somente o módulo isolado. Ele não prova o caminho real
`MethodChannel → NativeViewportHost → constant buffer → draw`.

Portanto, até esta auditoria, não estava provado que o comportamento aprovado
pelo teste era o comportamento exercitado pelo operador.

## Targets distintos

| Artefato | Target | Unidade principal | Padrão C++ |
|---|---|---|---|
| Teste | `flcad_camera_contract_test` | `camera_contract_test.cpp` | C++20 |
| Render Lab | `flcad_render_lab` | `main.cpp` | C++20 |
| FLCAD Release | `flcad_mobile` | `native_viewport_host.cpp` | C++17 |

Os três arquivos de dependência do MSVC registram o mesmo header compartilhado.
Porém cada target compila sua própria cópia inline desse header dentro de um
objeto e executável diferente.

## Condicionais

Não existe `#ifdef DEBUG`, `RELEASE` ou `TEST` selecionando uma implementação
alternativa de `CadCameraSystem`.

As únicas condicionais encontradas no caminho relevante habilitam o D3D debug
device:

- `#ifndef NDEBUG` no NativeViewportHost;
- `#ifdef _DEBUG` no Render Lab.

Elas não alteram World, View, Projection ou WVP.

## O que o teste não executa

O teste chama diretamente:

```text
CadCameraSystem::Fit
CadCameraSystem::OrbitPixels
CadCameraSystem::SetPose
CadCameraSystem::BuildFrame
```

O Release executa:

```text
Dart CadCameraController
→ StandardMethodCodec
→ NativeViewportHost::SetCamera
→ validação e conversão double/float
→ CadCameraSystem::SetPose
→ CadCameraSystem::SetLens
→ NativeViewportHost::Render
→ BuildFrame com aspecto real
→ XMStoreFloat4x4
→ UpdateSubresource
→ Vertex Shader
→ DrawIndexed
```

O teste não cobre o caminho anterior nem o posterior ao módulo compartilhado.

## Artefatos encontrados

Existem simultaneamente dois executáveis FLCAD diferentes:

```text
Debug   2026-08-18 15:52:46  1,551,872 bytes
Release 2026-08-18 16:07:56    185,856 bytes
```

No momento da auditoria, ambos estavam em execução com o mesmo título de
janela. O Debug foi compilado antes da alteração do Camera Contract
(`16:04:37`) e, portanto, contém implementação anterior. O Release foi
recompilado depois dela.

Como as duas janelas possuem o mesmo título, é possível operar o binário Debug
antigo acreditando estar no Release atual.

## Identidade do Release atual

```text
Path:   C:\flcad_mobile\build\windows\x64\runner\Release\FLCAD Reverse AI.exe
SHA256: 2D68E950CE62C31CF863967BD5AD1372AC9011FD642D12865FAE9E05641EEC98
Data:   2026-08-18 16:07:56
```

O objeto `native_viewport_host.obj` desse Release foi compilado às
`16:07:55`, depois do header compartilhado (`16:04:37`). O log de dependências
do MSVC confirma a inclusão do header pelo Release.

## Resposta ao gate

Está provado que o Release atual compila o mesmo header usado no teste.

Não está provado que o teste exercita o mesmo caminho executado pelo operador;
ele não exercita. Além disso, havia um processo Debug antigo concorrente com o
Release e indistinguível pelo título da janela.
