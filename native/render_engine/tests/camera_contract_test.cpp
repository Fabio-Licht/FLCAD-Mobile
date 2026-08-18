#include "cad_camera_system.h"

#include <DirectXMath.h>

#include <cmath>
#include <iostream>

using flcad::render::CadCameraSystem;
using namespace DirectX;

namespace {
bool Equal(FXMMATRIX left, CXMMATRIX right, float tolerance = 1e-5f) {
  XMFLOAT4X4 a, b;
  XMStoreFloat4x4(&a, left);
  XMStoreFloat4x4(&b, right);
  const float* av = &a._11;
  const float* bv = &b._11;
  for (int i = 0; i < 16; ++i)
    if (std::abs(av[i] - bv[i]) > tolerance) return false;
  return true;
}
}  // namespace

int main() {
  const float minimum[]{-12.0f, -8.0f, -5.0f};
  const float maximum[]{18.0f, 14.0f, 9.0f};
  CadCameraSystem render_lab;
  render_lab.Fit(minimum, maximum);
  for (int i = 0; i < 40; ++i) render_lab.OrbitPixels(4.0f, -1.5f);

  XMFLOAT3 eye, target, up;
  XMStoreFloat3(&eye, render_lab.Eye());
  XMStoreFloat3(&target, render_lab.Target());
  XMStoreFloat3(&up, render_lab.Up());
  const float eye_values[]{eye.x, eye.y, eye.z};
  const float target_values[]{target.x, target.y, target.z};
  const float up_values[]{up.x, up.y, up.z};

  CadCameraSystem native;
  native.Fit(minimum, maximum);
  native.SetPose(eye_values, target_values, up_values);

  const auto lab_frame = render_lab.BuildFrame(521.0f / 697.0f);
  const auto native_frame = native.BuildFrame(521.0f / 697.0f);
  const XMVECTOR vertex = XMVectorSet(1, 0, 0, 1);
  const XMVECTOR lab_clip = XMVector4Transform(
      vertex, lab_frame.world_view_projection);
  const XMVECTOR native_clip = XMVector4Transform(
      vertex, native_frame.world_view_projection);
  XMFLOAT4 lab_clip_value, native_clip_value;
  XMStoreFloat4(&lab_clip_value, lab_clip);
  XMStoreFloat4(&native_clip_value, native_clip);

  const bool world_equal = Equal(lab_frame.world, native_frame.world);
  const bool view_equal = Equal(lab_frame.view, native_frame.view);
  const bool projection_equal =
      Equal(lab_frame.projection, native_frame.projection);
  const bool wvp_equal = Equal(lab_frame.world_view_projection,
                               native_frame.world_view_projection);
  const bool clip_equal =
      std::abs(lab_clip_value.x - native_clip_value.x) <= 1e-5f &&
      std::abs(lab_clip_value.y - native_clip_value.y) <= 1e-5f &&
      std::abs(lab_clip_value.z - native_clip_value.z) <= 1e-5f &&
      std::abs(lab_clip_value.w - native_clip_value.w) <= 1e-5f;

  CadCameraSystem platform_sequence;
  CadCameraSystem native_sequence;
  platform_sequence.Fit(minimum, maximum);
  native_sequence.Fit(minimum, maximum);
  float maximum_pixel_difference = 0.0f;
  bool sequence_equal = true;
  for (int frame_index = 1; frame_index <= 100; ++frame_index) {
    platform_sequence.OrbitPixels(4.0f, -1.5f);
    XMStoreFloat3(&eye, platform_sequence.Eye());
    XMStoreFloat3(&target, platform_sequence.Target());
    XMStoreFloat3(&up, platform_sequence.Up());
    const float sequence_eye[]{eye.x, eye.y, eye.z};
    const float sequence_target[]{target.x, target.y, target.z};
    const float sequence_up[]{up.x, up.y, up.z};
    native_sequence.SetPose(sequence_eye, sequence_target, sequence_up);
    const auto platform_frame =
        platform_sequence.BuildFrame(521.0f / 697.0f);
    const auto integrated_frame =
        native_sequence.BuildFrame(521.0f / 697.0f);
    sequence_equal = sequence_equal &&
                     Equal(platform_frame.world_view_projection,
                           integrated_frame.world_view_projection);
    const XMVECTOR platform_clip = XMVector4Transform(
        vertex, platform_frame.world_view_projection);
    const XMVECTOR integrated_clip = XMVector4Transform(
        vertex, integrated_frame.world_view_projection);
    XMFLOAT4 platform_value, integrated_value;
    XMStoreFloat4(&platform_value, platform_clip);
    XMStoreFloat4(&integrated_value, integrated_clip);
    const float pixel_x =
        (platform_value.x / platform_value.w -
         integrated_value.x / integrated_value.w) * 521.0f * 0.5f;
    const float pixel_y =
        (platform_value.y / platform_value.w -
         integrated_value.y / integrated_value.w) * 697.0f * 0.5f;
    maximum_pixel_difference =
        std::max(maximum_pixel_difference,
                 std::sqrt(pixel_x * pixel_x + pixel_y * pixel_y));
  }

  std::cout << "World=" << world_equal << " View=" << view_equal
            << " Projection=" << projection_equal << " WVP=" << wvp_equal
            << " Clip=" << clip_equal << " Frames1To100=" << sequence_equal
            << " MaxPixelDifference=" << maximum_pixel_difference << '\n';
  return world_equal && view_equal && projection_equal && wvp_equal &&
                 clip_equal && sequence_equal && maximum_pixel_difference <= 0.001f
             ? 0
             : 1;
}
