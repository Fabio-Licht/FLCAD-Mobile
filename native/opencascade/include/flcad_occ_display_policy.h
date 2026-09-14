#pragma once
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <stdexcept>

namespace flcad::display {
struct Policy {
  double deflection;
  double angle;
  static constexpr uint64_t max_triangles = 250000;
  static constexpr uint64_t max_edge_points = 200000;
  static constexpr uint64_t max_json_bytes = 64 * 1024 * 1024;
  static Policy ForDiagonal(double diagonal) {
    if (!std::isfinite(diagonal) || diagonal <= 0)
      throw std::invalid_argument("Invalid display diagonal");
    return {std::clamp(diagonal * 1e-4, 1e-5, 10.0), 0.08};
  }
};
} // namespace flcad::display
