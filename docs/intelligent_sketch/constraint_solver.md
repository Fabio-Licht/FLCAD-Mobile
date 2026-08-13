# Adaptive Constraint Solver

`AdaptiveConstraintSolver` registra regras por tipo e pode receber regras externas. O núcleo Alpha resolve coincidência, horizontal, vertical, paralelo, perpendicular e distância. Todos os tipos FC-005 são serializáveis; os dependentes de Surface Engine aguardam adaptadores.

O resultado contém entidades corrigidas, convergência, graus de liberdade e diagnósticos explicáveis. Constraints equivalentes são marcadas como redundantes. Regras ausentes são `unsupported`, não consideradas resolvidas. Prioridades permitem evolução para solução incremental e alternativas sem alterar o modelo.
