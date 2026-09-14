// Bounded transient STL presentation. The complete registry mesh stays
// untouched.
#include <memory_resource>
#include <set>

namespace {
struct StlDisplayBudget {
  static constexpr size_t vertices = 125000;
  static constexpr size_t triangles = flcad::display::Policy::max_triangles;
  static constexpr size_t input_vertices = 1000000;
  static constexpr size_t input_triangles = 2000000;
  static constexpr size_t json_bytes = 24 * 1024 * 1024;
  // Conservative peak: 4 MiB remap + bounded maps/vectors + two JSON copies.
  static constexpr size_t working_bytes = 128 * 1024 * 1024;
  static constexpr size_t container_bytes = 32 * 1024 * 1024;
};
// Enforce an allocator budget as well as element limits. This includes tree
// nodes requested by the STL implementation, without preallocating the budget.
class StlContainerMemory final : public std::pmr::memory_resource {
  size_t live = 0;
  void *do_allocate(size_t bytes, size_t alignment) override {
    if (bytes > StlDisplayBudget::container_bytes - live)
      throw std::runtime_error("STL display working memory budget exceeded");
    void *p = std::pmr::new_delete_resource()->allocate(bytes, alignment);
    live += bytes;
    return p;
  }
  void do_deallocate(void *p, size_t bytes, size_t alignment) override {
    std::pmr::new_delete_resource()->deallocate(p, bytes, alignment);
    live -= bytes;
  }
  bool
  do_is_equal(const std::pmr::memory_resource &other) const noexcept override {
    return this == &other;
  }
};
// Trees are freed before JSON encoding. Both peaks fit the extra 128 MiB
// envelope, including vector growth, remap and the bounded caller FFI buffer.
static_assert(StlDisplayBudget::container_bytes +
                  StlDisplayBudget::input_vertices * sizeof(int) +
                  StlDisplayBudget::vertices * 2 *
                      (sizeof(gp_Pnt) + sizeof(gp_Vec)) +
                  StlDisplayBudget::triangles * 2 * sizeof(std::array<int, 3>) +
                  StlDisplayBudget::json_bytes <
              StlDisplayBudget::working_bytes);
static_assert(StlDisplayBudget::vertices * 2 *
                      (sizeof(gp_Pnt) + sizeof(gp_Vec)) +
                  StlDisplayBudget::triangles * 2 * sizeof(std::array<int, 3>) +
                  StlDisplayBudget::json_bytes * 4 <
              StlDisplayBudget::working_bytes);
struct StlDisplayLod {
  std::vector<gp_Pnt> points;
  std::vector<std::array<int, 3>> faces;
  std::vector<gp_Vec> normals;
  std::array<double, 6> bounds{};
};
StlDisplayLod stl_display_lod(const Handle(Poly_Triangulation) & source) {
  if (source.IsNull() || source->NbNodes() <= 0 || source->NbTriangles() <= 0 ||
      size_t(source->NbNodes()) > StlDisplayBudget::input_vertices ||
      size_t(source->NbTriangles()) > StlDisplayBudget::input_triangles)
    throw std::runtime_error("STL display input budget exceeded");
  StlDisplayLod result;
  std::array<int, 6> extrema{};
  for (int i = 1; i <= source->NbNodes(); ++i) {
    const auto p = source->Node(i);
    for (int axis = 0; axis < 3; ++axis) {
      const double v = p.Coord(axis + 1);
      if (!std::isfinite(v))
        throw std::runtime_error("Invalid STL display node");
      if (i == 1 || v < result.bounds[axis]) {
        result.bounds[axis] = v;
        extrema[axis] = i;
      }
      if (i == 1 || v > result.bounds[axis + 3]) {
        result.bounds[axis + 3] = v;
        extrema[axis + 3] = i;
      }
    }
  }
  const double diagonal =
      std::hypot(result.bounds[3] - result.bounds[0],
                 std::hypot(result.bounds[4] - result.bounds[1],
                            result.bounds[5] - result.bounds[2]));
  if (!std::isfinite(diagonal) || diagonal <= 0)
    throw std::runtime_error("Invalid STL display bounds");
  // Only this remap scales with admitted source nodes, never with face corners.
  std::vector<int> remap(source->NbNodes());
  bool complete = false;
  for (int attempt = 0; attempt < 12; ++attempt) {
    const double cell = std::ldexp(diagonal / 512.0, attempt);
    StlContainerMemory memory;
    std::pmr::map<std::array<int, 3>, int> cells(&memory);
    std::pmr::set<std::array<int, 3>> faces(&memory);
    result.points.clear();
    result.faces.clear();
    bool exceeded = false;
    for (int i = 1; i <= source->NbNodes(); ++i) {
      const auto p = source->Node(i);
      std::array<int, 3> key{};
      for (int a = 0; a < 3; ++a)
        key[a] = int(std::floor((p.Coord(a + 1) - result.bounds[a]) / cell));
      // Retain actual extrema, even if several lie in the same spatial cell.
      if (std::find(extrema.begin(), extrema.end(), i) != extrema.end())
        key = {-i, -1, -1};
      auto it = cells.find(key);
      if (it == cells.end()) {
        if (result.points.size() == StlDisplayBudget::vertices) {
          exceeded = true;
          break;
        }
        const int id = int(result.points.size());
        it = cells.emplace(key, id).first;
        result.points.push_back(p);
      }
      remap[i - 1] = it->second;
    }
    if (exceeded)
      continue;
    for (int i = 1; i <= source->NbTriangles(); ++i) {
      int a, b, c;
      source->Triangle(i).Get(a, b, c);
      if (a < 1 || b < 1 || c < 1 || a > source->NbNodes() ||
          b > source->NbNodes() || c > source->NbNodes())
        throw std::runtime_error("Invalid STL display index");
      std::array<int, 3> f{remap[a - 1], remap[b - 1], remap[c - 1]};
      if (f[0] == f[1] || f[0] == f[2] || f[1] == f[2])
        continue;
      const auto cross =
          gp_Vec(result.points[f[0]], result.points[f[1]])
              .Crossed(gp_Vec(result.points[f[0]], result.points[f[2]]));
      if (cross.SquareMagnitude() <= 1e-30)
        continue;
      // Cyclic canonicalization removes duplicates without reversing winding.
      if (f[1] < f[0] && f[1] < f[2])
        std::rotate(f.begin(), f.begin() + 1, f.end());
      else if (f[2] < f[0] && f[2] < f[1])
        std::rotate(f.begin(), f.begin() + 2, f.end());
      if (faces.find(f) != faces.end())
        continue;
      if (result.faces.size() == StlDisplayBudget::triangles) {
        exceeded = true;
        break;
      }
      faces.insert(f);
      result.faces.push_back(f);
    }
    if (!exceeded && !result.faces.empty()) {
      complete = true;
      break;
    }
  }
  if (!complete)
    throw std::runtime_error("STL display reduction unavailable");
  result.normals.resize(result.points.size(), gp_Vec(0, 0, 0));
  for (const auto &f : result.faces) {
    const auto n =
        gp_Vec(result.points[f[0]], result.points[f[1]])
            .Crossed(gp_Vec(result.points[f[0]], result.points[f[2]]));
    for (const int id : f)
      result.normals[id] += n;
  }
  for (auto &n : result.normals) {
    if (n.SquareMagnitude() <= 1e-30)
      n = gp_Vec(0, 0, 1);
    else
      n.Normalize();
  }
  return result;
}
int stl_lod_geometry(const Handle(Poly_Triangulation) & source, char *out,
                     size_t size, char *error, size_t error_size) {
  const auto lod = stl_display_lod(source);
  std::ostringstream json;
  json.imbue(std::locale::classic());
  json << std::setprecision(17);
  auto budget = [&] {
    if (size_t(json.tellp()) > StlDisplayBudget::json_bytes)
      throw std::runtime_error("STL display byte budget exceeded");
  };
  json << "{\"nodes\":[";
  bool first = true;
  for (const auto &p : lod.points) {
    budget();
    for (int a = 1; a <= 3; ++a) {
      if (!first)
        json << ',';
      first = false;
      json << p.Coord(a);
    }
  }
  json << "],\"normals\":[";
  first = true;
  for (const auto &n : lod.normals) {
    budget();
    for (int a = 1; a <= 3; ++a) {
      if (!first)
        json << ',';
      first = false;
      json << n.Coord(a);
    }
  }
  json << "],\"triangles\":[";
  first = true;
  for (const auto &f : lod.faces) {
    budget();
    for (int id : f) {
      if (!first)
        json << ',';
      first = false;
      json << id;
    }
  }
  json << "],\"bounds\":[";
  for (int a = 0; a < 6; ++a) {
    if (a)
      json << ',';
    json << lod.bounds[a];
  }
  json << "],\"presentationLod\":{\"version\":1,\"originalTriangles\":"
       << source->NbTriangles() << ",\"displayTriangles\":" << lod.faces.size()
       << ",\"originalVertices\":" << source->NbNodes()
       << ",\"displayVertices\":" << lod.points.size()
       << ",\"method\":\"spatial-clustering-v1\",\"measurementSafe\":false}}";
  budget();
  const auto text = json.str();
  preflight(text, out, size);
  copy_complete(text, out);
  return 1;
}
} // namespace
