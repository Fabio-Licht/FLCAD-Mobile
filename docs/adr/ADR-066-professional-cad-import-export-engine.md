# ADR-066 — Professional CAD Import / Export Engine

## Status

Accepted with explicit capability limits.

## Context

The desktop application needs a single professional file pipeline backed exclusively by the official OpenCascade Geometry Kernel. Parallel parsers, fabricated geometry and automatic mesh-to-BRep reconstruction are prohibited.

## Decision

`lib/core/import_export` owns the API, engines, format adapters, validation, passive runtime, repository and workspace projection. Every import follows file validation → Geometry Kernel → geometry validation → Project Repository → Explorer → Viewport. Every export follows geometry diagnostics → topology/export validation → Geometry Kernel → output validation → Project Repository.

STL import uses `MeshGeometryKernelAPI.importStl`, including OpenCascade auto-detection for ASCII and binary data. STEP and IGES import/export use `InterchangeGeometryKernelAPI`. STEP AP203/AP214 are declared supported by the adapter contract and AP242 is reserved; schema interpretation remains OpenCascade-owned. STL export uses OpenCascade triangulation and `StlAPI_Writer`, replacing the former non-interchange binary diagnostic payload.

OBJ and PLY import and OBJ export are represented in the public format vocabulary and native menu filters, but deliberately return `UnsupportedError` until the official kernel exposes those capabilities. No fallback parser is present. An STL mesh cannot be exported as STEP because that would require a reconstruction algorithm; users must explicitly reconstruct or supply a BRep shape first.

## Validation

Imports reject missing, empty, mismatched, incomplete, empty-kernel and degenerate files. Shape diagnostics with errors reject the import. Exports reject temporary shapes, mismatched extensions, empty output, invalid/open/degenerate/orientation diagnostics and empty triangulation.

## Persistence and UI

Sources and outputs are registered under `CAD/Imports` and `CAD/Exports`; JSONL audit records are stored in `RecentFiles`, `ImportHistory` and `ExportHistory`. The Windows `Arquivo` menu invokes the native file picker. Successful imports update the official Explorer and Viewport projection, including Fit View, bounding box and validation state. Progress is synchronous and passive: no timer, isolate, worker, polling or parallel thread is introduced.

## Consequences

The engine never changes Recognition, AI Engineering, Primitive Intelligence, Smart References, Playbooks or Engineering Knowledge. Full OBJ/PLY support and mesh-to-BRep reconstruction require future, explicitly authorized kernel and reconstruction work and are not certified by B-001C.
