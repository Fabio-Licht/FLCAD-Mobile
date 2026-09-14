#include "../src/flcad_occ_api.cpp"
#include <BRepPrimAPI_MakeBox.hxx>
#include <BRepPrimAPI_MakeSphere.hxx>
#include <filesystem>
#include <iostream>
#include <set>
#include <thread>
#define CHECK(x)                                                               \
  do {                                                                         \
    if (!(x)) {                                                                \
      std::cerr << "FAIL " << __LINE__ << ": " << #x << "\n";                  \
      return 1;                                                                \
    }                                                                          \
  } while (false)
struct Sink {
  std::vector<uint8_t> bytes;
  size_t calls = 0, stop = 0;
  int mode = 0;
  bool wrongThread = false;
  std::thread::id thread = std::this_thread::get_id();
};
int32_t OCC_STREAM_CALL write_bytes(void *ctx, const uint8_t *p, uint32_t n,
                                    uint32_t *accepted) {
  if (!ctx) {
    *accepted = n;
    return 0;
  }
  auto &s = *static_cast<Sink *>(ctx);
  ++s.calls;
  s.wrongThread |= s.thread != std::this_thread::get_id();
  if (n > 64000)
    throw std::runtime_error("oversize chunk");
  if (s.stop == s.calls) {
    if (s.mode >= 4) {
      s.bytes.insert(s.bytes.end(), p, p + n / 2);
      *accepted = n / 2;
      if (s.mode == 5)
        throw Standard_Failure("consumer OCCT exception after effect");
      if (s.mode == 6)
        throw 42;
      throw std::overflow_error("consumer exception after effect");
    }
    *accepted = s.mode == 2 ? n + 1 : s.mode == 1 ? n / 2 : 0;
    if (*accepted <= n)
      s.bytes.insert(s.bytes.end(), p, p + *accepted);
    return s.mode == 3 ? -1 : s.mode == 1 ? 0 : 71;
  }
  *accepted = n;
  s.bytes.insert(s.bytes.end(), p, p + n);
  return 0;
}
uint32_t u32(const uint8_t *p) {
  return uint32_t(p[0]) | (uint32_t(p[1]) << 8) | (uint32_t(p[2]) << 16) |
         (uint32_t(p[3]) << 24);
}
std::set<std::filesystem::path> inventory() {
  std::set<std::filesystem::path> r;
  for (const auto &e : std::filesystem::recursive_directory_iterator(
           std::filesystem::current_path()))
    r.insert(e.path());
  return r;
}
int main() {
  const auto before = inventory();
  auto original = BRepPrimAPI_MakeSphere(10).Shape();
  shapes.emplace("test", original);
  const auto seq = sequence.load();
  occ_stream_result_v1 result{};
  auto run = [&](Sink &s) {
    occ_stream_sink_v1 sink{sizeof(sink), 1, &s, write_bytes};
    return flcad_occ_mesh_stream_v1("test", 0.02, 0.15, UINT32_MAX, &sink,
                                    &result, sizeof(result));
  };
  CHECK(flcad_occ_mesh_stream_version() == 1);
  Sink all;
  CHECK(run(all) == 0);
  CHECK(all.calls >= 3 && !all.wrongThread);
  CHECK(all.bytes.size() == 84 + 50 * result.triangles &&
        result.bytes_accepted == all.bytes.size());
  CHECK(u32(all.bytes.data() + 80) == result.triangles);
  const auto expected = all.bytes;
  for (size_t stop : {size_t(1), size_t(2), all.calls})
    for (int mode = 0; mode <= 6; ++mode) {
      Sink s;
      s.stop = stop;
      s.mode = mode;
      CHECK(run(s) != 0);
      CHECK(s.calls == stop);
      if (mode >= 4)
        CHECK(result.bytes_accepted < s.bytes.size() &&
              result.status == OCC_STREAM_SINK);
      else
        CHECK(result.bytes_accepted == s.bytes.size());
      CHECK(result.accepted_count_valid == (mode != 2 && mode < 4));
      if (mode == 0)
        CHECK(result.consumer_code == 71 && result.status == OCC_STREAM_SINK);
      if (mode == 3)
        CHECK(result.status == OCC_STREAM_CANCELLED);
      CHECK(shapes.size() == 1 && meshes.empty() && sequence.load() == seq);
    }
  occ_stream_sink_v1 sink{sizeof(sink), 1, nullptr, write_bytes};
  CHECK(flcad_occ_mesh_stream_v1("test", 0.02, 0.15, UINT32_MAX, &sink, &result,
                                 sizeof(result)) == 0);
  CHECK(flcad_occ_mesh_stream_v1("test", .02, .15, UINT32_MAX, nullptr, &result,
                                 sizeof(result)) == OCC_STREAM_INVALID);
  CHECK(flcad_occ_mesh_stream_v1("test", .02, .15, UINT32_MAX, &sink, nullptr,
                                 sizeof(result)) == OCC_STREAM_INVALID);
  CHECK(flcad_occ_mesh_stream_v1("test", .02, .15, UINT32_MAX, &sink, &result,
                                 sizeof(result) - 1) == OCC_STREAM_INVALID);
  auto badVersion = sink;
  badVersion.version = 2;
  CHECK(flcad_occ_mesh_stream_v1("test", .02, .15, UINT32_MAX, &badVersion,
                                 &result,
                                 sizeof(result)) == OCC_STREAM_INVALID);
  shapes.emplace("empty", BRepBuilderAPI_MakeVertex(gp_Pnt(0, 0, 0)).Shape());
  CHECK(flcad_occ_mesh_stream_v1("empty", .02, .15, UINT32_MAX, &sink, &result,
                                 sizeof(result)) == OCC_STREAM_TESSELLATION);
  shapes.erase("empty");
  shapes.emplace("extreme", BRepPrimAPI_MakeBox(1, 2, 3).Shape());
  for (double d : {1e-6, 1e6})
    CHECK(flcad_occ_mesh_stream_v1("extreme", d, 0.5, UINT32_MAX, &sink,
                                   &result, sizeof(result)) == OCC_STREAM_OK);
  shapes.erase("extreme");
  auto valid = sink;
  sink.write = nullptr;
  CHECK(flcad_occ_mesh_stream_v1("test", 0.02, 0.15, UINT32_MAX, &sink, &result,
                                 sizeof(result)) == OCC_STREAM_INVALID);
  sink = valid;
  CHECK(flcad_occ_mesh_stream_v1("absent", 0.02, 0.15, UINT32_MAX, &sink,
                                 &result, sizeof(result)) == OCC_STREAM_SHAPE);
  for (double d :
       {0., -1., 1e-20, 1e100, std::numeric_limits<double>::infinity(),
        std::numeric_limits<double>::quiet_NaN()})
    CHECK(flcad_occ_mesh_stream_v1("test", d, 0.15, UINT32_MAX, &sink, &result,
                                   sizeof(result)) == OCC_STREAM_INVALID);
  for (double a :
       {0., -1., 1e-20, 4., std::numeric_limits<double>::quiet_NaN()})
    CHECK(flcad_occ_mesh_stream_v1("test", 0.02, a, UINT32_MAX, &sink, &result,
                                   sizeof(result)) == OCC_STREAM_INVALID);
  CHECK(flcad_occ_mesh_stream_v1("test", 0.02, 0.15, UINT64_MAX, &sink, &result,
                                 sizeof(result)) == OCC_STREAM_INVALID);
  CHECK(flcad_occ_mesh_stream_v1("test", 0.02, 0.15, 1, &sink, &result,
                                 sizeof(result)) == OCC_STREAM_LIMIT);
  stream_count_override = UINT64_MAX;
  Sink over;
  CHECK(run(over) == OCC_STREAM_LIMIT && over.calls == 0);
  stream_count_override = 0;
  for (int point : {1, 2, 3})
    for (int kind : {0, 1, 2}) {
      stream_fault_point = point;
      stream_fault_kind = kind;
      Sink s;
      CHECK(run(s) == (point == 1   ? OCC_STREAM_TESSELLATION
                       : point == 2 ? OCC_STREAM_SINK
                                    : OCC_STREAM_SERIALIZATION));
      CHECK(result.message[0] != 0);
      CHECK(s.calls == (point == 3 ? 1 : 0));
      CHECK(result.bytes_accepted == s.bytes.size());
    }
  for (int repeat = 0; repeat < 20; ++repeat) {
    Sink s;
    CHECK(run(s) == 0 && s.bytes == expected);
  }
  for (TopExp_Explorer ex(original, TopAbs_FACE); ex.More(); ex.Next()) {
    TopLoc_Location loc;
    CHECK(BRep_Tool::Triangulation(TopoDS::Face(ex.Current()), loc).IsNull());
  }
  CHECK(shapes.size() == 1 && meshes.empty() && sequence.load() == seq &&
        BRepCheck_Analyzer(original).IsValid());
  CHECK(inventory() == before);
  // Legacy comparison is test-only file IO, after the no-file assertion above.
  char error[1024] = {};
  int vertices = 0, triangles = 0;
  const auto legacy =
      std::filesystem::temp_directory_path() /
      ("occ-stream-" +
       std::to_string(
           std::chrono::steady_clock::now().time_since_epoch().count()) +
       ".stl");
  // Legacy angle is fixed at .5. Compare a box: triangulation is unambiguous.
  for (int fixture = 0; fixture < 3; ++fixture) {
    TopoDS_Shape controlled = fixture == 0
                                  ? BRepPrimAPI_MakeBox(1, 2, 3).Shape()
                                  : BRepPrimAPI_MakeSphere(10).Shape();
    if (fixture == 2) {
      gp_Trsf tr;
      tr.SetTranslation(gp_Vec(3, -7, 2));
      controlled.Location(TopLoc_Location(tr));
      controlled.Reverse();
    }
    shapes["compare"] = controlled;
    Sink box;
    occ_stream_sink_v1 bs{sizeof(bs), 1, &box, write_bytes};
    CHECK(flcad_occ_mesh_stream_v1("compare", 0.1, 0.5, UINT32_MAX, &bs,
                                   &result, sizeof(result)) == 0);
    CHECK(flcad_occ_mesh("compare", legacy.string().c_str(), 0.1, &vertices,
                         &triangles, error, sizeof(error)) == 1);
    std::ifstream f(legacy, std::ios::binary);
    std::vector<uint8_t> bytes((std::istreambuf_iterator<char>(f)), {});
    f.close();
    CHECK(bytes.size() == box.bytes.size());
    CHECK(std::equal(bytes.begin() + 80, bytes.end(), box.bytes.begin() + 80));
    std::filesystem::remove(legacy);
  }
  // Transient BREP presentation must preserve geometry/residency and must not
  // infer CAD edges from tessellation. Check analytic sphere normals including
  // a located, reversed face and a box with exactly twelve topological edges.
  CHECK(flcad::display::Policy::ForDiagonal(100).deflection == 0.01);
  CHECK(flcad::display::Policy::ForDiagonal(1000).deflection == 0.1);
  CHECK(flcad::display::Policy::ForDiagonal(1e-9).deflection == 1e-5);
  CHECK(flcad::display::Policy::ForDiagonal(1e12).deflection == 10);
  bool invalid_diagonal = false;
  try {
    flcad::display::Policy::ForDiagonal(
        std::numeric_limits<double>::infinity());
  } catch (const std::invalid_argument &) {
    invalid_diagonal = true;
  }
  CHECK(invalid_diagonal);
  auto array = [](const std::string &json, const std::string &key) {
    const auto start = json.find("\"" + key + "\":[") + key.size() + 4;
    const auto end = json.find(']', start);
    std::string text = json.substr(start, end - start);
    std::replace(text.begin(), text.end(), ',', ' ');
    std::istringstream stream(text);
    std::vector<double> values;
    double value;
    while (stream >> value)
      values.push_back(value);
    return values;
  };
  std::vector<char> presentation(64 * 1024 * 1024);
  for (int fixture = 0; fixture < 3; ++fixture) {
    auto shape = fixture == 0 ? BRepPrimAPI_MakeBox(10, 20, 30).Shape()
                              : BRepPrimAPI_MakeSphere(10).Shape();
    if (fixture == 2) {
      gp_Trsf location;
      location.SetTranslation(gp_Vec(3, -7, 2));
      shape.Location(TopLoc_Location(location));
      shape.Reverse();
    }
    shapes["presentation"] = shape;
    std::ostringstream before_brep;
    BRepTools::Write(shape, before_brep);
    const auto owners = shapes.size(), mesh_owners = meshes.size();
    CHECK(flcad_occ_display_geometry("presentation", presentation.data(),
                                     presentation.size(), error,
                                     sizeof(error)) == 1);
    const std::string json(presentation.data());
    const auto nodes = array(json, "nodes"), normals = array(json, "normals"),
               indices = array(json, "triangles");
    CHECK(!nodes.empty() && nodes.size() == normals.size() && nodes.size() == indices.size() * 3);
    CHECK(indices.size() / 3 <= flcad::display::Policy::max_triangles);
    if (fixture == 0) {
      const auto begin = json.find("\"topologicalEdges\":[");
      const auto end = json.find("],\"bounds\"", begin);
      CHECK(std::count(json.begin() + begin, json.begin() + end, '[') == 13);
    }
    for (size_t i = 0; i < normals.size(); i += 3) {
      const gp_Vec n(normals[i], normals[i + 1], normals[i + 2]);
      CHECK(std::abs(n.Magnitude() - 1) < 1e-10);
      if (fixture) {
        gp_Vec expected(nodes[i] - (fixture == 2 ? 3 : 0),
                        nodes[i + 1] - (fixture == 2 ? -7 : 0),
                        nodes[i + 2] - (fixture == 2 ? 2 : 0));
        expected.Normalize();
        if (fixture == 2)
          expected.Reverse();
        CHECK(n.Dot(expected) > 0.999999);
      }
    }
    std::ostringstream after_brep;
    BRepTools::Write(shapes.at("presentation"), after_brep);
    CHECK(before_brep.str() == after_brep.str());
    CHECK(shapes.size() == owners && meshes.size() == mesh_owners);
    CHECK(BRepCheck_Analyzer(shape).IsValid());
    char small[8] = "stable";
    CHECK(flcad_occ_display_geometry("presentation", small, sizeof(small),
                                     error, sizeof(error)) == 0);
    CHECK(std::string(small) == "stable");
  }
  shapes.clear();
  CHECK(meshes.empty());
  std::cout
      << "PASS stream: chunks, failures, contracts, overflow, exceptions, 20 "
         "repeats, borrowed shape, no files, legacy equivalence\n";
}
