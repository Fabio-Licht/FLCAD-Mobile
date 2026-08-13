# Engineering Core

`core/engineering` é a camada canônica transversal. Ela contém EngineeringObject, Context, EPB, CQRS, History, Cache, DNA, Graph, Analytics, Validation, Learning, Runtime, Kernel, Services, Logger, Metrics, Benchmark e Diagnostics.

A migração preserva APIs públicas: event buses, caches, histories e graphs de domínio continuam como adapters legados. Novos fluxos devem usar `EngineeringContext`; remoção dos tipos antigos exige uma futura major version.
