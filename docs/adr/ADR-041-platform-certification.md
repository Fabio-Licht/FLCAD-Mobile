# ADR-041 — Platform Certification

## Status

Accepted.

## Decision

Certification is evidence-based. Missing architectural evidence blocks a check, and any failed official API step fails the demonstration. A real, non-empty part file and every mandatory workflow step are required. The engine does not substitute callbacks, geometry, kernels or production fallbacks and never starts work during bootstrap.

The first audit identified a blocking gap: the official interchange kernel API supports STEP, IGES and BREP but no Project First STL importer exists. Consequently the available `bearing.stl` cannot yet complete the official end-to-end workflow and the platform must remain uncertified until that integration exists.
