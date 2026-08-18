# R2-005 — Flutter ↔ D3D11 External Texture Audit

## Escopo

Auditoria isolada da fronteira `Direct3D 11 -> External Texture -> Flutter`.
Nenhum STL, SceneGraph, Picking ou geometria CAD participa do teste mínimo.

## Resultado observado

- Texture ID da última execução: `1987527286320`.
- Registro: aceito (`textureId >= 0`).
- Estado: registrado durante toda a execução.
- Callbacks de superfície: `62`.
- Frequência em repouso: `1.0 callback/s`.
- Tamanho solicitado pelo Flutter: `631 x 645`.
- Atualizações marcadas: `4`.
- Atualizações aceitas pelo registrar: `4/4`.
- Formato produtor: `DXGI_FORMAT_B8G8R8A8_UNORM`.
- Formato declarado ao Flutter: `kFlutterDesktopPixelFormatBGRA8888`.
- Tipo declarado: `kFlutterDesktopGpuSurfaceTypeD3d11Texture2D`.

## Teste mínimo

O teste cria três vértices locais, sem acessar STL ou SceneGraph, e utiliza shaders
locais exclusivos do diagnóstico:

1. Limpa o Render Target com azul conhecido.
2. Lê o pixel central diretamente na textura D3D11.
3. Desenha um triângulo com Pixel Shader vermelho constante.
4. Lê novamente o pixel central.
5. Marca o frame e mantém a mesma textura registrada no widget `Texture`.

Resultados:

- Após o clear azul: `0xff051fcc`, exatamente o BGRA esperado.
- Após o draw vermelho: `0xff000000`, preto.
- O triângulo não aparece no Flutter.

## Localização da falha

A falha não ocorre no registro nem na chamada do callback. Também não é uma
incompatibilidade nominal entre BGRA e DXGI: o clear possui conteúdo válido e é
lido corretamente antes do draw.

O ponto restante é o handoff/sincronização do recurso compartilhado entre o
dispositivo D3D11 criado pelo `NativeViewportHost` e o dispositivo consumidor do
Flutter. O host utiliza uma única textura com `D3D11_RESOURCE_MISC_SHARED`, mas
não possui keyed mutex, fence, double buffering ou outro protocolo explícito de
posse entre produtor e consumidor.

Portanto, o defeito está **durante a integração Flutter ↔ D3D11**, na coerência
do recurso compartilhado, depois da criação do Render Target e antes da
composição confiável do conteúdo pelo Flutter.

## Conclusão do gate

O teste mínimo falhou: o triângulo vermelho não aparece. Conforme o critério da
R2-005, o problema está isolado na integração Flutter ↔ D3D11 e não pertence a
STL, SceneGraph, CAD, Picking ou Geometry Kernel.

