# Operation Validation

Before commit, the validator checks topology membership, continuity, boundary health, patch health, surface quality and constraint conflicts. A failed result moves the operation to `failed`; the state machine then rejects commit before `GeometryKernelAPI` is called.
