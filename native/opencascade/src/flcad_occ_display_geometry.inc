// Transient presentation only. Never publishes a shape/mesh registry entry or
// writes an asset; the caller holds the existing managed shape custody lease.
#include "flcad_occ_display_policy.h"
#include <BRepBndLib.hxx>
#include <Bnd_Box.hxx>
#include <GCPnts_QuasiUniformDeflection.hxx>
#include <iomanip>
#include <iostream>
#include "flcad_occ_mesh_lod.inc"

extern "C" int flcad_occ_display_geometry(const char *token, char *out,
                                          size_t size, char *error,
                                          size_t error_size) {
  auto reject = [&](const char *category) {
#ifndef NDEBUG
    std::cerr << "[viewport.native] " << category << '\n';
#endif
    return fail(category, error, error_size);
  };
  try {
    Handle(Poly_Triangulation) mesh;
    {
      std::lock_guard<std::mutex> lock(registry_mutex);
      const auto found = meshes.find(token ? token : "");
      if (found != meshes.end()) mesh = found->second;
    }
    if (!mesh.IsNull())
      return stl_lod_geometry(mesh, out, size, error, error_size);
    const auto original = get(token);
    Bnd_Box box;
    BRepBndLib::AddOptimal(original, box, false, false);
    if (box.IsVoid() || box.IsOpen())
      return reject("Invalid display bounds");
    double bounds[6];
    box.Get(bounds[0], bounds[1], bounds[2], bounds[3], bounds[4], bounds[5]);
    const double diagonal =
        std::hypot(bounds[3] - bounds[0],
                   std::hypot(bounds[4] - bounds[1], bounds[5] - bounds[2]));
    const auto policy = flcad::display::Policy::ForDiagonal(diagonal);
    TopoDS_Shape display;
    uint64_t triangles = 0;
    double deflection = policy.deflection, angle = policy.angle;
    for (int attempt = 0; attempt < 6; ++attempt) {
      BRepBuilderAPI_Copy copy(original, true, false);
      display = copy.Shape();
      BRepMesh_IncrementalMesh mesher(display, deflection, false, angle, false);
      if (!mesher.IsDone())
        return reject("Display tessellation incomplete");
      triangles = 0;
      for (TopExp_Explorer ex(display, TopAbs_FACE); ex.More(); ex.Next()) {
        TopLoc_Location location;
        const auto mesh =
            BRep_Tool::Triangulation(TopoDS::Face(ex.Current()), location);
        if (!mesh.IsNull())
          triangles += mesh->NbTriangles();
      }
      if (triangles && triangles <= policy.max_triangles)
        break;
      deflection *= 2;
      angle = std::min(angle * std::sqrt(2.0), 0.5);
    }
    if (!triangles || triangles > policy.max_triangles)
      return reject("Display triangle budget exceeded");
    std::ostringstream json;
    json.imbue(std::locale::classic());
    json << std::setprecision(17) << "{\"nodes\":[";
    bool first = true;
    auto number = [&](double value) {
      if (!std::isfinite(value))
        throw std::runtime_error("Invalid display coordinate");
      if (!first)
        json << ',';
      first = false;
      json << value;
    };
    auto corners = [&](auto consume, bool with_normals) {
      for (TopExp_Explorer ex(display, TopAbs_FACE); ex.More(); ex.Next()) {
        const auto face = TopoDS::Face(ex.Current());
        TopLoc_Location location;
        const auto mesh = BRep_Tool::Triangulation(face, location);
        if (mesh.IsNull())
          continue;
        BRepAdaptor_Surface surface(face, false);
        std::vector<gp_Vec> analytic(with_normals ? mesh->NbNodes() : 0);
        std::vector<uint8_t> normal_state(analytic.size(), 0);
        for (int i = 1; i <= mesh->NbTriangles(); ++i) {
          int a, b, c;
          mesh->Triangle(i).Get(a, b, c);
          if (face.Orientation() == TopAbs_REVERSED)
            std::swap(b, c);
          const gp_Pnt pa =
              mesh->Node(a).Transformed(location.Transformation());
          const gp_Pnt pb =
              mesh->Node(b).Transformed(location.Transformation());
          const gp_Pnt pc =
              mesh->Node(c).Transformed(location.Transformation());
          gp_Vec fallback = gp_Vec(pa, pb).Crossed(gp_Vec(pa, pc));
          if (fallback.SquareMagnitude() > 1e-30)
            fallback.Normalize();
          else
            fallback = gp_Vec(0, 0, 1);
          for (int node : {a, b, c}) {
            const auto point =
                mesh->Node(node).Transformed(location.Transformation());
            gp_Vec normal = fallback;
            if (with_normals && mesh->HasUVNodes()) {
              const auto index = static_cast<size_t>(node - 1);
              if (!normal_state[index]) {
                const auto uv = mesh->UVNode(node);
                BRepLProp_SLProps props(surface, uv.X(), uv.Y(), 1, 1e-9);
                normal_state[index] = props.IsNormalDefined() ? 2 : 1;
                if (normal_state[index] == 2) {
                  analytic[index] = gp_Vec(props.Normal());
                  if (face.Orientation() == TopAbs_REVERSED)
                    analytic[index].Reverse();
                }
              }
              if (normal_state[index] == 2)
                normal = analytic[index];
            }
            consume(point, normal);
          }
        }
      }
    };
    corners(
        [&](const gp_Pnt &p, const gp_Vec &) {
          number(p.X());
          number(p.Y());
          number(p.Z());
        },
        false);
    json << "],\"normals\":[";
    first = true;
    corners(
        [&](const gp_Pnt &, const gp_Vec &n) {
          number(n.X());
          number(n.Y());
          number(n.Z());
        },
        true);
    json << "],\"triangles\":[";
    for (uint64_t i = 0; i < triangles * 3; ++i) {
      if (i)
        json << ',';
      json << i;
    }
    // Transient presentation topology. The ranges are emitted from the same
    // tessellation pass as nodes/triangles, so hover never remeshes the shape.
    // Each pair is [first SV_PrimitiveID + 1, triangle count] for one OCCT
    // face in TopExp traversal order.
    json << "],\"faceTriangleRanges\":[";
    bool first_face = true;
    uint64_t first_face_triangle = 1;
    for (TopExp_Explorer ex(display, TopAbs_FACE); ex.More(); ex.Next()) {
      TopLoc_Location location;
      const auto mesh =
          BRep_Tool::Triangulation(TopoDS::Face(ex.Current()), location);
      const uint64_t count = mesh.IsNull() ? 0 : mesh->NbTriangles();
      if (!first_face)
        json << ',';
      first_face = false;
      json << '[' << first_face_triangle << ',' << count << ']';
      first_face_triangle += count;
    }
    json << "],\"topologicalEdges\":[";
    TopTools_IndexedDataMapOfShapeListOfShape adjacency;
    TopExp::MapShapesAndAncestors(original, TopAbs_EDGE, TopAbs_FACE,
                                  adjacency);
    bool first_edge = true;
    uint64_t edge_points = 0;
    for (int i = 1; i <= adjacency.Extent(); ++i) {
      const auto edge = TopoDS::Edge(adjacency.FindKey(i));
      if (BRep_Tool::Degenerated(edge))
        continue;
      bool seam = false;
      for (TopTools_ListIteratorOfListOfShape it(adjacency.FindFromIndex(i));
           it.More(); it.Next())
        seam |= BRep_Tool::IsClosed(edge, TopoDS::Face(it.Value()));
      if (seam)
        continue;
      BRepAdaptor_Curve curve(edge);
      GCPnts_QuasiUniformDeflection points(curve, deflection);
      if (!points.IsDone() || points.NbPoints() < 2)
        return reject("Display edge sampling incomplete");
      edge_points += points.NbPoints();
      if (edge_points > policy.max_edge_points)
        return reject("Display edge budget exceeded");
      if (!first_edge)
        json << ',';
      first_edge = false;
      json << '[';
      first = true;
      for (int p = 1; p <= points.NbPoints(); ++p) {
        const auto point = points.Value(p);
        number(point.X());
        number(point.Y());
        number(point.Z());
      }
      json << ']';
    }
    json << "],\"bounds\":[";
    first = true;
    for (double value : bounds)
      number(value);
    json << "],\"displayDeflection\":" << deflection
         << ",\"displayAngle\":" << angle << '}';
    const auto result = json.str();
    if (!out || result.size() >= size || result.size() >= policy.max_json_bytes)
      return reject("Display buffer budget exceeded");
    std::memcpy(out, result.c_str(), result.size() + 1);
    return 1;
  } catch (const Standard_Failure &) {
    return reject("Native display geometry failed");
  } catch (const std::exception &) {
    return reject("Display geometry failed");
  } catch (...) {
    return reject("Unknown display geometry failure");
  }
}

extern "C" int flcad_occ_managed_cad_face(
    const char *token, size_t presentation_triangle_id, char *out, size_t size,
    char *error, size_t error_size) {
  try {
    if (!presentation_triangle_id)
      return fail("Display triangle ID must be positive", error, error_size);
    const auto original = get(token);
    Bnd_Box box;
    BRepBndLib::AddOptimal(original, box, false, false);
    if (box.IsVoid() || box.IsOpen())
      return fail("Invalid managed B-Rep bounds", error, error_size);
    double bounds[6];
    box.Get(bounds[0], bounds[1], bounds[2], bounds[3], bounds[4], bounds[5]);
    const double diagonal =
        std::hypot(bounds[3] - bounds[0],
                   std::hypot(bounds[4] - bounds[1], bounds[5] - bounds[2]));
    const auto policy = flcad::display::Policy::ForDiagonal(diagonal);
    TopoDS_Shape display;
    uint64_t triangles = 0;
    double deflection = policy.deflection, angle = policy.angle;
    for (int attempt = 0; attempt < 6; ++attempt) {
      BRepBuilderAPI_Copy copy(original, true, false);
      display = copy.Shape();
      BRepMesh_IncrementalMesh mesher(display, deflection, false, angle, false);
      if (!mesher.IsDone())
        return fail("Display tessellation incomplete", error, error_size);
      triangles = 0;
      for (TopExp_Explorer ex(display, TopAbs_FACE); ex.More(); ex.Next()) {
        TopLoc_Location location;
        const auto mesh =
            BRep_Tool::Triangulation(TopoDS::Face(ex.Current()), location);
        if (!mesh.IsNull())
          triangles += mesh->NbTriangles();
      }
      if (triangles && triangles <= policy.max_triangles)
        break;
      deflection *= 2;
      angle = std::min(angle * std::sqrt(2.0), 0.5);
    }
    if (presentation_triangle_id > triangles)
      return fail("Display triangle is outside managed B-Rep", error,
                  error_size);

    uint64_t first_triangle = 1;
    int face_index = 0;
    for (TopExp_Explorer ex(display, TopAbs_FACE); ex.More(); ex.Next()) {
      ++face_index;
      const auto face = TopoDS::Face(ex.Current());
      TopLoc_Location location;
      const auto mesh = BRep_Tool::Triangulation(face, location);
      const uint64_t count = mesh.IsNull() ? 0 : mesh->NbTriangles();
      if (presentation_triangle_id < first_triangle + count) {
        BRepAdaptor_Surface surface(face, true);
        std::ostringstream json;
        json.imbue(std::locale::classic());
        json << std::setprecision(17) << "{\"faceIndex\":" << face_index;
        if (surface.GetType() != GeomAbs_Plane) {
          const char *nature = surface.GetType() == GeomAbs_Cylinder
                                   ? "cylinder"
                                   : "unsupported";
          json << ",\"surfaceType\":\"" << nature << "\"}";
        } else {
          double u_min, u_max, v_min, v_max;
          BRepTools::UVBounds(face, u_min, u_max, v_min, v_max);
          gp_Pnt origin = surface.Plane().Location();
          if (std::isfinite(u_min) && std::isfinite(u_max) &&
              std::isfinite(v_min) && std::isfinite(v_max))
            origin = surface.Value((u_min + u_max) * .5, (v_min + v_max) * .5);
          gp_Dir normal = surface.Plane().Axis().Direction();
          if (face.Orientation() == TopAbs_REVERSED)
            normal.Reverse();
          const gp_Dir x = surface.Plane().XAxis().Direction();
          json << ",\"surfaceType\":\"plane\",\"origin\":[" << origin.X()
               << ',' << origin.Y() << ',' << origin.Z() << "],\"normal\":["
               << normal.X() << ',' << normal.Y() << ',' << normal.Z()
               << "],\"xDirection\":[" << x.X() << ',' << x.Y() << ','
               << x.Z() << "]}";
        }
        const auto result = json.str();
        if (!out || result.size() >= size)
          return fail("Managed CAD face buffer is too small", error,
                      error_size);
        std::memcpy(out, result.c_str(), result.size() + 1);
        return 1;
      }
      first_triangle += count;
    }
    return fail("Display triangle has no B-Rep face", error, error_size);
  } catch (const Standard_Failure &x) {
    return fail(x.GetMessageString(), error, error_size);
  } catch (const std::exception &x) {
    return fail(x.what(), error, error_size);
  } catch (...) {
    return fail("Unknown managed CAD face inspection failure", error,
                error_size);
  }
}
