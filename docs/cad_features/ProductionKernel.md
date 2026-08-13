# Production CAD Kernel

The production feature surface includes Extrude, Revolve, Sweep, Loft, Union, Subtract, Intersect, Offset, Shell, Draft, Mirror and linear/circular pattern contracts. OpenCascade remains encapsulated behind its adapter and private bridge.

The repository currently has no OCCT native host. Consequently, production plugin selection and operations report explicit unavailability until that host is installed. Test contract kernels verify orchestration and never become production geometry providers.

Sketch solving, Class-A/NURBS editing, freeform modeling, CAM, CNC, GD&T, PMI, assemblies, motion and FEA are outside this release.

