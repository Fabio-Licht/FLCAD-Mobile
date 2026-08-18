# R2-005 — Frame-by-frame Matrix Divergence

## Método

Comparação de 200 eventos do mesmo Orbit, usando em cada frame o mesmo Eye,
Target, World, Projection e viewport (`521 × 697`). A transformação esperada
usa o Up mantido pela câmera da Plataforma. A transformação efetiva do Native
usa o contrato canônico do Render Lab, com Y-Up.

Vértice de controle: `(1, 0, 0, 1)`.

## Primeira divergência

No frame 1 as matrizes coincidem dentro da precisão numérica. A primeira
divergência ocorre no **frame 2**, exclusivamente em `View`.

| Frame | Δ World | Δ View | Δ Projection | Δ WVP | deslocamento do vértice |
|---:|---:|---:|---:|---:|---:|
| 1 | 0 | 2.78e-17 | 0 | 9.67e-17 | 0 px |
| 2 | 0 | 0.008414 | 0 | 0.029323 | 3.25 px |
| 5 | 0 | 0.034637 | 0 | 0.120714 | 13.30 px |
| 10 | 0 | 0.081316 | 0 | 0.283394 | 30.65 px |
| 20 | 0 | 0.183402 | 0 | 0.639178 | 63.84 px |
| 40 | 0 | 0.462102 | 0 | 1.400623 | 115.26 px |
| 100 | 0 | 0.768662 | 0 | 2.678879 | 299.25 px |
| 200 | 0 | 0.049323 | 0 | 0.171898 | 9.73 px |

## Localização exata

O primeiro evento parte de uma base equivalente. Depois dele, a Plataforma
atualiza seu Up para o Up local da câmera. No evento seguinte, seu Orbit usa
esse Up local como eixo do próximo yaw. O Native, pelo contrato do Render Lab,
reconstrói cada View usando Y-Up mundial.

Assim, no segundo evento:

```text
World:      igual
View:       primeira divergência
Projection: igual
WVP:        diverge como consequência de View
Clip-space: diverge como consequência de WVP
```

A diferença não é escalar nem numérica. É uma diferença acumulativa de base de
orientação entre dois contratos de Orbit: yaw em torno do Up local da
Plataforma versus yaw em torno do Y-Up mundial do Render Lab.

