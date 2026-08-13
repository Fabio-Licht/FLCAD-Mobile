#include "flcad_occ_api.h"
#include <cassert>

int main() {
  char error[1024] = {}, token[256] = {}, fingerprint[256] = {};
  assert(flcad_occ_initialize(error, sizeof(error)) == 1);
  assert(flcad_occ_create_vertex(1, 2, 3, token, sizeof(token), fingerprint,
                                 sizeof(fingerprint), error, sizeof(error)) == 1);
  assert(flcad_occ_shape_count() == 1);
  flcad_occ_shutdown();
  return 0;
}
