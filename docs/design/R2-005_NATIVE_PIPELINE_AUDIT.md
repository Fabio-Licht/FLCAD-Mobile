# R2-005 — Native Pipeline Audit

## Conclusão

A STL permanece íntegra durante todo o pipeline D3D11. Ela deixa de ser
apresentada **depois do Pixel Shader e do Render Target**, na fronteira entre a
`GpuSurfaceTexture` D3D11 e o compositor Flutter executado em modo software.

O executável principal relança obrigatoriamente a si mesmo com:

```text
--enable-software-rendering
```

Ao mesmo tempo, o `NativeViewportHost` registra uma textura do tipo:

```text
kFlutterDesktopGpuSurfaceTypeD3d11Texture2D
```

Esses dois caminhos são incompatíveis para a composição pretendida: o host
renderiza em D3D11, porém a instância Flutter ativa utiliza o renderizador de
software e não apresenta a superfície GPU no widget `Texture`.

## Evidência do pipeline

Modelo auditado:

- 251.796 vértices;
- 1.508.184 índices;
- 502.728 triângulos;
- zero índices inválidos.

Contadores D3D11:

| Etapa | Resultado |
|---|---:|
| Draw calls | 1 |
| IA primitives | 502.728 |
| Vertex Shader invocations | 722.246 |
| Clipper invocations | 502.728 |
| Clipper output primitives | 502.728 |
| Pixel Shader invocations | 815.356 |
| Render target | 521 × 697 |

Buffers confirmados:

- Vertex Buffer: 6.043.104 bytes;
- Index Buffer: 6.032.736 bytes;
- ambos criados como recursos GPU válidos.

## Respostas obrigatórias

### O Snapshot chega corretamente ao NativeViewportHost?

**Sim.** Uma entidade de mesh chegou contendo 251.796 vértices e 1.508.184
índices.

### O Vertex Buffer realmente recebe os dados?

**Sim.** O buffer foi criado com 6.043.104 bytes.

### O Index Buffer possui índices válidos?

**Sim.** Foram verificados 1.508.184 índices e nenhum estava fora do intervalo
dos 251.796 vértices.

### Os Buffers são enviados para a GPU?

**Sim.** `CreateBuffer` retornou sucesso para os dois buffers e eles foram
associados ao Input Assembler antes do draw.

### O Vertex Shader está sendo executado?

**Sim.** O contador registrou 722.246 invocações.

### O Pixel Shader está sendo executado?

**Sim.** O contador registrou 815.356 invocações.

### A geometria está sendo descartada pelo clipping?

**Não.** O clipper recebeu 502.728 primitivas e produziu 502.728 primitivas.

### O Render Target recebe draw calls?

**Sim.** Um `DrawIndexed` com 502.728 triângulos foi enviado ao Render Target
de 521 × 697.

### O Depth Buffer está ocultando toda a geometria?

**Não.** O depth foi limpo antes do único draw; todas as primitivas atravessaram
o clipper e houve 815.356 execuções do Pixel Shader. Não existe geometria
anterior capaz de ocluir integralmente a mesh.

### O problema ocorre antes ou depois do Vertex Shader?

**Depois.** Mais precisamente, ocorre depois do Pixel Shader/Render Target, na
apresentação da textura D3D11 pelo compositor Flutter em modo software.

## Escopo preservado

Nenhuma correção funcional foi implementada. CadDocument, Runtime, SceneGraph,
Picking, Camera, Geometry Kernel e Flutter Canvas não foram modificados nesta
auditoria. A instrumentação temporária foi removida após a coleta.

Dados brutos: `smoke/r2-005-native-pipeline-audit.log`.
