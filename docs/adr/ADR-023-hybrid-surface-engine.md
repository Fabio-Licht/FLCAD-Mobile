# ADR-023: Hybrid Surface Engine

- Status: Accepted
- Date: 2026-08-13

## Context

Surface Intelligence proposes individual surfaces and Surface Generation can create limited analytical shapes, but professional reconstruction needs a global strategy combining analytical and irregular regions before further geometry is executed.

## Decision

Create a kernel-independent Hybrid Surface domain that builds a complete network from planned candidates. Group compatible regions, evaluate continuity without modification, compare consolidated and segmented strategies, plan patch roles, predict quality and emit a reconstruction DAG whose execution stages are explicitly deferred.

Persist the plan, network, strategies, patch planning and reconstruction network in project-owned directories. Expose the same portable state to Studio and FEL.

## Consequences

- global reconstruction decisions precede CAD execution;
- manufacturing, inspection and editability influence strategy choice;
- future kernels receive an explicit, validated execution network;
- no NURBS, patch, blend, trim, extension, B-Rep or hybrid geometry is created in this sprint.

