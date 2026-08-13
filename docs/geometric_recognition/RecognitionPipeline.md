# Recognition Pipeline

The canonical sequence is Observation → Candidate Generation → Region Growing → Primitive Detection → Statistical Fitting → Outlier Rejection → Least-Squares Refinement → Validation → Confidence → Recognition DNA → Decision Engine. `RecognitionPipelineStage<I,O>` makes stages replaceable. The current engine executes supported fitting directly while preserving stage contracts for specialized Ω-003B algorithms.
