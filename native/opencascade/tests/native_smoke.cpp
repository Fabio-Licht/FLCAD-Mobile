#include "flcad_occ_api.h"
#include <cassert>
#include <cstring>
#include <filesystem>

int main() {
  char error[1024] = {}, token[256] = {}, fingerprint[256] = {};
  assert(flcad_occ_initialize(error, sizeof(error)) == 1);
  assert(std::strlen(flcad_occ_version()) > 0);
  assert(std::strstr(flcad_occ_capabilities(), "STEP") != nullptr);
  assert(std::strstr(flcad_occ_capabilities(), "IGES") != nullptr);
  assert(std::strstr(flcad_occ_capabilities(), "Loft") != nullptr);
  assert(flcad_occ_create_vertex(1, 2, 3, token, sizeof(token), fingerprint,
                                 sizeof(fingerprint), error, sizeof(error)) == 1);
  assert(flcad_occ_shape_count() == 1);
  assert(flcad_occ_destroy_shape(token, error, sizeof(error)) == 1);
  assert(flcad_occ_shape_count() == 0);
  const double center[3] = {0, 0, 0}, axis[3] = {0, 0, 1};
  assert(flcad_occ_create_torus(center, axis, 5, 1, token, sizeof(token),
                                fingerprint, sizeof(fingerprint), error,
                                sizeof(error)) == 1);
  char topology[4096] = {};
  assert(flcad_occ_surface_topology(token, topology, sizeof(topology), error,
                                    sizeof(error)) == 1);
  assert(std::strstr(topology, "boundaries") != nullptr);
  char quality[4096] = {};
  assert(flcad_occ_surface_quality(token, axis, 100, quality, sizeof(quality),
                                   error, sizeof(error)) == 1);
  assert(std::strstr(quality, "meanCurvature") != nullptr);
  assert(std::strstr(quality, "averageNormal") != nullptr);
  assert(std::strstr(quality, "draft") != nullptr);
  char operated[256] = {}, operated_fp[256] = {}, operated_type[64] = {};
  assert(flcad_occ_surface_operation("NURBS", token, "", nullptr, 0,
      operated, sizeof(operated), operated_fp, sizeof(operated_fp),
      operated_type, sizeof(operated_type), error, sizeof(error)) == 1);
  assert(std::strlen(operated_fp) > 0);
  assert(flcad_occ_destroy_shape(operated, error, sizeof(error)) == 1);
  const double trim_values[5] = {0, 3.0, 0, 3.0, 1e-6};
  assert(flcad_occ_surface_operation("TRIM", token, "", trim_values, 5,
      operated, sizeof(operated), operated_fp, sizeof(operated_fp),
      operated_type, sizeof(operated_type), error, sizeof(error)) == 1);
  assert(flcad_occ_destroy_shape(operated, error, sizeof(error)) == 1);
  assert(flcad_occ_surface_operation("BOUNDARY", token, "", nullptr, 0,
      operated, sizeof(operated), operated_fp, sizeof(operated_fp),
      operated_type, sizeof(operated_type), error, sizeof(error)) == 1);
  assert(std::strcmp(operated_type, "compound") == 0);
  assert(flcad_occ_destroy_shape(operated, error, sizeof(error)) == 1);
  assert(flcad_occ_surface_operation("HEAL", token, "", nullptr, 0,
      operated, sizeof(operated), operated_fp, sizeof(operated_fp),
      operated_type, sizeof(operated_type), error, sizeof(error)) == 1);
  assert(flcad_occ_destroy_shape(operated, error, sizeof(error)) == 1);
  assert(flcad_occ_shape_count() == 1);
  assert(flcad_occ_destroy_shape(token, error, sizeof(error)) == 1);
  char plane[256] = {}, cylinder[256] = {}, intersection[4096] = {};
  assert(flcad_occ_create_plane(center, axis, -10, 10, plane, sizeof(plane),
                                fingerprint, sizeof(fingerprint), error,
                                sizeof(error)) == 1);
  assert(flcad_occ_create_cylinder(center, axis, 3, -1, 1, cylinder,
                                   sizeof(cylinder), fingerprint,
                                   sizeof(fingerprint), error,
                                   sizeof(error)) == 1);
  assert(flcad_occ_intersect_surfaces(plane, cylinder, intersection,
                                      sizeof(intersection), error,
                                      sizeof(error)) == 1);
  assert(std::strstr(intersection, "edgeCount") != nullptr);
  assert(flcad_occ_destroy_shape(plane, error, sizeof(error)) == 1);
  assert(flcad_occ_destroy_shape(cylinder, error, sizeof(error)) == 1);
  char exported[256] = {}, imported_fp[256] = {}, imported_type[64] = {};
  assert(flcad_occ_create_torus(center, axis, 5, 1, exported,
                                sizeof(exported), fingerprint,
                                sizeof(fingerprint), error,
                                sizeof(error)) == 1);
  const char* step_path = "flcad_native_roundtrip.step";
  const char* iges_path = "flcad_native_roundtrip.iges";
  const char* stl_path = "flcad_native_roundtrip.stl";
  assert(flcad_occ_export_shape(exported, step_path, "step", error,
                                sizeof(error)) == 1);
  assert(std::filesystem::file_size(step_path) > 0);
  char roundtrip[256] = {};
  assert(flcad_occ_import_shape(step_path, "step", roundtrip,
                                sizeof(roundtrip), imported_fp,
                                sizeof(imported_fp), imported_type,
                                sizeof(imported_type), error,
                                sizeof(error)) == 1);
  assert(flcad_occ_export_shape(roundtrip, iges_path, "iges", error,
                                sizeof(error)) == 1);
  assert(std::filesystem::file_size(iges_path) > 0);
  int vertices = 0, triangles = 0;
  assert(flcad_occ_mesh(roundtrip, stl_path, 0.1, &vertices, &triangles,
                        error, sizeof(error)) == 1);
  assert(vertices > 0 && triangles > 0);
  assert(std::filesystem::file_size(stl_path) > 84);
  assert(flcad_occ_destroy_shape(exported, error, sizeof(error)) == 1);
  assert(flcad_occ_destroy_shape(roundtrip, error, sizeof(error)) == 1);
  std::filesystem::remove(step_path);
  std::filesystem::remove(iges_path);
  std::filesystem::remove(stl_path);
  for (int i = 0; i < 1000; ++i) {
    assert(flcad_occ_create_vertex(i, i, i, token, sizeof(token), fingerprint,
                                   sizeof(fingerprint), error, sizeof(error)) == 1);
    assert(flcad_occ_destroy_shape(token, error, sizeof(error)) == 1);
  }
  // Surface intersection above intentionally remains registered until shutdown.
  assert(flcad_occ_shape_count() == 1);
  flcad_occ_shutdown();
  assert(flcad_occ_shape_count() == 0);
  return 0;
}
