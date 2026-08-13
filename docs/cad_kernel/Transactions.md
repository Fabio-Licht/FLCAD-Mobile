# Kernel Transactions

`KernelTransactionManager` provides begin, operation registration, commit and rollback. Transactions are project-scoped and immutable snapshots; only active transactions accept operations or terminal transitions.

The manager delegates lifecycle events to the active kernel. Future geometry mutations must occur inside this boundary so workflow replay and rollback remain auditable.

