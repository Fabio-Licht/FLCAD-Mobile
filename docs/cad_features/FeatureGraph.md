# Feature Graph

`FeatureGraph` is independent from the low-level Geometry Graph. It connects Feature IDs, input and output handles, references and feature dependencies. It rejects cycles and exposes downstream impact and shape-based affected sets.

Snapshots are stored under `CAD/FeatureGraph/feature_graph.json` and can be projected into Engineering Graph without introducing kernel-specific types.

