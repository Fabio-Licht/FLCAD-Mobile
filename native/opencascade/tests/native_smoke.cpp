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
