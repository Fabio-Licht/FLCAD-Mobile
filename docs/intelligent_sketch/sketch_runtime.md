# Sketch Runtime

O runtime pesado usa `IsolateSketchRuntime`. `SketchCache` evita recomputação por DNA e `SketchRenderer`/`GPUSketchRenderer` definem atualização incremental futura. Nenhum kernel GPU está incluído no Alpha.

Eventos: created, updated, deleted, solved, projected, recognized e converted. Ações são enviadas a `SketchLearningSink`; a implementação padrão é privada/no-op e pode ser substituída por armazenamento ou IA autorizada.
