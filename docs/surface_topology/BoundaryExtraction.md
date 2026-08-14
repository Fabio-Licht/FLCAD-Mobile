# Boundary Extraction

Boundaries come directly from `TopoDS_Edge` members of each `TopoDS_Wire`. Length uses `BRepGProp::LinearProperties`; closure uses `BRep_Tool::IsClosed`. Zero-length edges are invalid.
