# R2-005 — Final Transform Comparison

## Frame comparado

Frame determinístico após um único Orbit contínuo com 40 deltas de ponteiro
`dx = 4`, `dy = -1.5`, partindo do estado inicial comum. Viewport `521 × 697`,
raio `1`, distância `2.7`, FOV `42°`, near `0.001`, far `1000`.

Vértice conhecido: `(1, 0, 0, 1)`.

## Primeira divergência

`World` é idêntica. A primeira divergência aparece em `View`, antes de
Projection e antes da composição WVP.

### World — ambos

```text
1 0 0 0
0 1 0 0
0 0 1 0
0 0 0 1
```

### View — Render Lab

```text
 0.060758881 -0.019961719 -0.997952849 0
 0.000000000  0.999800007 -0.019998667 0
 0.998152472  0.001215097  0.060746730 0
 0.000000000  0.000000000  2.700000000 1
```

### View — Native Viewport

```text
 0.197896762 -0.447625486 -0.872048333 0
-0.401886580  0.774380751 -0.488693799 0
 0.894049243  0.447175443 -0.026647233 0
 0.000000000  0.000000000  2.700000000 1
```

Diferença absoluta máxima em View: `0.468695132`.

## Projection — ambos

```text
3.485119152 0           0           0
0           2.605089065 0           0
0           0           1.000001000 1
0           0          -0.001000001 0
```

Diferença em Projection: `0`.

## WorldViewProjection

### Render Lab

```text
0.211751941 -0.052002055 -0.997953847 -0.997952849
0.000000000  2.604568064 -0.019998687 -0.019998667
3.478680298  0.003165435  0.060746791  0.060746730
0.000000000  0.000000000  2.699002699  2.700000000
```

### Native Viewport

```text
 0.689693794 -1.166104259 -0.872049206 -0.872048333
-1.400622618  2.017330826 -0.488694288 -0.488693799
 3.115868138  1.164931856 -0.026647260 -0.026647233
 0.000000000  0.000000000  2.699002699  2.700000000
```

## Clip-space do mesmo vértice

```text
Render Lab: (0.211751941, -0.052002055, 1.701048852, 1.702047151)
Native:     (0.689693794, -1.166104259, 1.826953493, 1.827951667)
```

## Diagnóstico

A ordem `World × View × Projection`, a matriz World e o frustum/projection
coincidem. A Bounding Box não participa desta primeira divergência.

O Render Lab deriva o frame do Orbit de `yaw/pitch` e reconstrói View com Up
mundial fixo `(0,1,0)`. O Native recebe Eye/Target/Up da câmera da Plataforma;
após o mesmo gesto, o Up recebido é `(-0.447625486, 0.774380751,
0.447175443)` e a posição Eye também diverge. Consequentemente, a matriz View
já é diferente antes da multiplicação por Projection.

Nenhum componente do produto foi alterado para produzir esta comparação.

