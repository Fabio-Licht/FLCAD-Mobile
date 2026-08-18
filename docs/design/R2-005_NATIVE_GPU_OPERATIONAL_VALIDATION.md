# R2-005 — Native GPU Operational Validation

## Escopo congelado

Validação executada sem implementar picking GPU, AO, HDR, tone mapping,
selection GPU ou alterações no pipeline.

## Ambiente

- Release Windows;
- STL: `CALOTA_INOXX.stl`;
- workspace completo com Toolbar, Explorer, Property Inspector e Assistant;
- alternância entre Native GPU e Flutter Canvas no mesmo projeto.

## Resultado

**REPROVADO.**

A importação concluiu e a Plataforma entrou corretamente no workspace. Com
`Native GPU` ativo, Toolbar, Explorer, Inspector, comandos de viewport e WCS
permaneceram visíveis, mas a malha não foi apresentada. O viewport mostrou
somente o fundo e os overlays Flutter.

Ao alternar para `Flutter Canvas`, a mesma malha apareceu imediatamente,
confirmando que:

- a STL foi importada;
- o SceneGraph contém a geometria;
- o workspace está operacional;
- a falha está no caminho integrado Snapshot/External Texture/Native Host;
- o fallback funciona corretamente.

Ao retornar para `Native GPU`, a malha voltou a desaparecer. O processo
permaneceu responsivo durante todas as alternâncias.

## Evidências

- `smoke/r2-005-native-operational-import.png` — Native GPU sem a malha;
- `smoke/r2-005-operational-canvas-fallback.png` — mesma cena no Canvas;
- `smoke/r2-005-operational-native-recheck.png` — retorno ao Native confirma a falha.

## Critério operacional

Orbit, Pan, Zoom e Fit não podem ser avaliados de forma válida no Native GPU
enquanto a geometria não estiver visível. Portanto, a validação deve parar
neste primeiro bloqueio observável. Nenhuma avaliação de picking ou qualidade
visual deve ser iniciada antes da correção do transporte/apresentação da mesh.
