# FLCAD Reconstruction Engine Alpha

## Visão geral

O motor segue Project First Architecture: contexto, cache, resultados, relatório e logs são armazenados dentro do workspace do Projeto. A apresentação não acessa arquivos; ela conversa com `ReconstructionManager`, que usa `ReconstructionRepository` e um `ReconstructionBackend` intercambiável.

## Fluxo

1. O repositório cria um `PipelineContext` com caminhos, imagens e fingerprint.
2. O backend Alpha abre um Isolate dedicado.
3. `ReconstructionPipeline` executa 12 `PipelineStep` independentes.
4. Progresso e eventos retornam por `SendPort`.
5. Cada etapa concluída grava um marcador associado ao fingerprint.
6. O Job e os indicadores do Projeto são persistidos durante a execução.
7. O relatório fica em `Reconstruction/reconstruction.json` e o modelo Alpha em `Mesh/alpha_model.json`.

## Responsabilidades

- `pipeline/`: contratos, contexto, orquestração, cache e etapas.
- `domain/`: backend, manager, exceções e interfaces de advisors.
- `services/`: backend em Isolate e análise Alpha de qualidade.
- `repositories/`: persistência do Job e preparação do workspace.
- `presentation/`: controle do usuário e visualizador inicial.
- `models/`: estados, progresso, eventos, resultado e Job.

## Cache e retomada

O fingerprint considera nome, tamanho e modificação de cada imagem. Uma etapa só reutiliza cache quando o fingerprint coincide. Jobs persistidos como `running`, `waiting` ou `paused` geram a pergunta de retomada. A execução recomeça pelo pipeline, reutilizando todos os marcadores válidos.

## Backend intercambiável

`ReconstructionBackend` isola o aplicativo de COLMAP, OpenMVG/OpenMVS, processamento remoto ou um motor próprio. O backend Alpha atual valida a arquitetura e gera artefatos determinísticos; ele não afirma produzir fotogrametria de produção.

COLMAP e OpenMVG/OpenMVS não foram empacotados nesta Sprint: o projeto não possui toolchain/binários Android ou licenciamento de distribuição configurados. Uma integração futura deve implementar `ReconstructionBackend`, mantendo pipeline, UI, cache e persistência inalterados.

## Extensibilidade

Novas etapas implementam `PipelineStep`. IA entra pelos advisors. Escala, Smart Regions, exportação e Cloud possuem contratos próprios sem implementação nesta Sprint. Todos recebem `PipelineContext`, preservando isolamento entre módulos e compatibilidade futura Mobile/Desktop.
