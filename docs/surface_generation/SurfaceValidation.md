# Surface Validation

Pre-validation checks required parameters, positive dimensions and tolerances, consistent bounds, valid regions and candidate confidence. Post-validation delegates geometry, bounds, continuity, tolerance, orientation and degeneration checks to the active kernel.

Any error prevents registration and rolls back an active kernel transaction.

