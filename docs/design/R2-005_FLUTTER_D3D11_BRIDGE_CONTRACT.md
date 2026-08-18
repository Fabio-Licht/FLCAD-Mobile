# R2-005 — Flutter D3D11 Bridge Contract

## Conclusão

A causa foi localizada no tipo de recurso entregue ao Flutter:

- O FLCAD cria uma nova instância de `ID3D11Device`.
- A textura é criada nesse dispositivo independente.
- O descriptor declara `kFlutterDesktopGpuSurfaceTypeD3d11Texture2D` e entrega
  diretamente um `ID3D11Texture2D*`.
- O Flutter converte esse tipo em `EGL_D3D_TEXTURE_ANGLE`.
- O contrato do ANGLE exige que o objeto tenha sido criado pelo mesmo
  `ID3D11Device` usado pelo display EGL.

O adaptador físico ser o mesmo não satisfaz esse contrato. A instância do
dispositivo também precisa ser a mesma.

## Contrato real do Flutter

### ID3D11Texture2D direto

- O produtor mantém a textura viva até o Flutter abri-la.
- `AddRef` no callback e `Release` no release callback são adequados.
- Não existe transferência de ownership para o Flutter.
- Não existe chamada a `IDXGIKeyedMutex::AcquireSync` ou `ReleaseSync` na
  implementação `ExternalTextureD3d`.
- Não existe fence exposta pelo descriptor.
- A textura precisa pertencer ao dispositivo D3D11 do Flutter/ANGLE.

### DXGI shared handle

- O descriptor entrega um `HANDLE`, não um `ID3D11Texture2D*`.
- O Flutter utiliza `EGL_D3D_TEXTURE_2D_SHARE_HANDLE_ANGLE`.
- Esse é o contrato apropriado quando produtor e consumidor usam dispositivos
  D3D11 distintos.
- O produtor deve concluir/submeter suas escritas antes de marcar o frame.
- `Flush` é necessário no modelo de recurso compartilhado tradicional.
- O Flutter não solicita keyed mutex em seus atributos EGL atuais.

## Exemplo oficial do Flutter

O teste `PopulateD3dTexture` do embedder Windows:

1. Obtém o dispositivo com `engine->egl_manager()->GetDevice(...)`.
2. Cria uma única textura nesse dispositivo.
3. Usa `D3D11_USAGE_DEFAULT`.
4. Usa `DXGI_FORMAT_B8G8R8A8_UNORM`.
5. Usa `D3D11_BIND_RENDER_TARGET`.
6. Usa `D3D11_RESOURCE_MISC_SHARED`.
7. Entrega o ponteiro com
   `kFlutterDesktopGpuSurfaceTypeD3d11Texture2D`.

Não utiliza duas texturas, triple buffering, keyed mutex ou fence.

## Comparação com o FLCAD

| Item | Flutter oficial | FLCAD atual | Resultado |
|---|---|---|---|
| Device | Device interno do EGL/ANGLE | Novo `D3D11CreateDevice` | Incompatível |
| Tipo entregue | `ID3D11Texture2D*` | `ID3D11Texture2D*` | Igual nominalmente |
| Ownership do device | Mesmo device | Device diferente | Causa da falha |
| Usage | `D3D11_USAGE_DEFAULT` | `D3D11_USAGE_DEFAULT` | Correto |
| Format | `B8G8R8A8_UNORM` | `B8G8R8A8_UNORM` | Correto |
| Bind | Render target | Render target + shader resource | Compatível |
| Misc | Shared | Shared | Correto, mas handle não é usado |
| Flush | Não exercitado no teste estático | Executado | Não resolve device incorreto |
| Keyed mutex | Não utilizado | Não utilizado | Compatível com Flutter |

## Exemplos dinâmicos

O Flutter possui teste oficial do caminho D3D11, mas não fornece um exemplo
oficial completo de renderização D3D11 dinâmica. O exemplo de textura dinâmica
adicionado ao repositório Flutter utiliza `PixelBufferTexture`, não D3D11.

Implementações públicas que usam produtores gráficos separados adotam o outro
contrato: textura compartilhada e DXGI handle. O Agus Maps Flutter, por exemplo,
documenta no Windows uma textura D3D11 compartilhada entregue ao Flutter por
DXGI handle, com fallback por cópia quando o interop direto não está disponível.

## Decisão técnica para o próximo teste

Existem somente duas alternativas compatíveis:

1. Criar a textura no mesmo `ID3D11Device` usado pelo Flutter/ANGLE e continuar
   entregando `ID3D11Texture2D*`.
2. Manter o dispositivo independente do FLCAD, obter o DXGI shared handle e
   registrar a textura como `kFlutterDesktopGpuSurfaceTypeDxgiSharedHandle`.

Como a API pública do Flutter fornece o adaptador DXGI, mas não fornece o
`ID3D11Device` interno, a segunda alternativa é a transição pública suportada
para o desenho atual do FLCAD.

