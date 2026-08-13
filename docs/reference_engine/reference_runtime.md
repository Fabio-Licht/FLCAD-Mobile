# Reference Runtime

Operações pesadas são abstraídas por `ReferenceComputeRuntime`. `IsolateReferenceRuntime` executa analytics fora do isolate de UI. Implementações Desktop ou servidor podem substituir esse runtime sem alterar builders ou entidades.

`GPUReferenceFitter` é o contrato para aceleração futura; o Alpha não inclui kernel GPU. `ReferenceCache` indexa builder e fingerprint das origens para evitar recálculo quando a geometria não mudou.

Eventos suportados: created, updated, deleted, recognized, rebuilt e validated. Histórico e snapshots são persistidos em JSON versionado. O runtime não importa Flutter e pode ser usado por Mobile, Desktop ou Cloud.
