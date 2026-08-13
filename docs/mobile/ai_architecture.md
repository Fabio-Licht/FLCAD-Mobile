# FLCAD Smart Reconstruction Assistant

## Princípios

A IA é consultiva: observa, explica e recomenda; o usuário mantém o controle. Todo contexto, cache, benchmark, conhecimento e histórico pertence ao Projeto.

## AI Engine e plugins

`AIPlugin` é o único contrato consumido pelo `AIEngine`. O engine seleciona por tarefa e prioridade, consulta cache, executa, registra benchmark e tenta o próximo plugin em caso de falha. `PluginManager` suporta registro, remoção e hot swap de plugins/providers em runtime. `AIRegistry` mantém metadados de nome, versão, hash, autor, data e compatibilidade.

`ProviderPluginAdapter` transforma providers ONNX, TensorFlow Lite, Cloud ou futuros runtimes FLCAD em plugins normais. Os providers ONNX/TFLite/Cloud atuais declaram indisponibilidade porque nenhum runtime, modelo ou endpoint foi incorporado. O plugin Alpha local é o fallback executável e roda heurísticas em Isolate.

## Capability Discovery

Na inicialização são descobertos CPU e providers realmente disponíveis. GPU/NPU permanecem `false` até uma integração nativa fornecer detecção confiável. Isso evita anunciar aceleração inexistente.

## Assistentes e motores

`AdvisorEngine` contém Capture, Scale, Coverage, Quality, Cleanup e Reconstruction Advisors. Todos chamam exclusivamente `AIEngine`. `MeasurementAdvisor` solicita apenas referências necessárias. Segmentação Alpha produz classificação de máscara simples; Cleanup recomenda operações não destrutivas. `QualityEngine` agrega fotos, cobertura, escala, reconstrução e mesh.

## Smart Knowledge Layer

Resultados e decisões são persistidos em `AI/knowledge.json`; recomendações em `AI/advisor.json`; inferências em `AI/Cache/<task>`. O fingerprint impede reprocessamento de entrada inalterada. O formato JSON é portátil entre Mobile e Desktop.

## Benchmark e privacidade operacional

Cada inferência não cacheada registra plugin, tarefa, duração, núcleos de CPU e memória residente. GPU, temperatura e bateria ficam nulos até existirem APIs multiplataforma confiáveis. Nenhum dado é enviado para Cloud sem um provider explicitamente instalado e configurado.

## Extensões futuras

Interfaces foram reservadas para Smart Regions, preparação CAD, superfícies, sketches, STL, otimização de mesh e Cloud. Download de modelos possui apenas contrato; instalação e rede não fazem parte da Sprint M-004.
