#include "flcad_occ_api.h"
#include <cassert>
#include <cstring>

int main() {
  char error[1024] = {}, token[256] = {}, fingerprint[256] = {};
  assert(flcad_occ_initialize(error, sizeof(error)) == 1);
  assert(std::strlen(flcad_occ_version()) > 0);
  assert(std::strstr(flcad_occ_capabilities(), "STEP") != nullptr);
  assert(std::strstr(flcad_occ_capabilities(), "IGES") != nullptr);
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
  for (int i = 0; i < 1000; ++i) {
    assert(flcad_occ_create_vertex(i, i, i, token, sizeof(token), fingerprint,
                                   sizeof(fingerprint), error, sizeof(error)) == 1);
    assert(flcad_occ_destroy_shape(token, error, sizeof(error)) == 1);
  }
  assert(flcad_occ_shape_count() == 0);
  flcad_occ_shutdown();
  assert(flcad_occ_shape_count() == 0);
  return 0;
}
