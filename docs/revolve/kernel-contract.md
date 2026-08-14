# Kernel contract

Confirmation follows `GeometryKernelAPI -> RevolveFeatureKernelAdapter -> kernel plugin`. It begins a transaction, invokes `REVOLVE`, validates the returned official handle, then commits or rolls back atomically.
