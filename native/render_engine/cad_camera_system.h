#ifndef FLCAD_RENDER_ENGINE_CAD_CAMERA_SYSTEM_H_
#define FLCAD_RENDER_ENGINE_CAD_CAMERA_SYSTEM_H_

#include <DirectXMath.h>

#include <algorithm>
#include <cmath>

namespace flcad::render {

class CadCameraSystem {
 public:
  struct Frame {
    DirectX::XMMATRIX world;
    DirectX::XMMATRIX view;
    DirectX::XMMATRIX projection;
    DirectX::XMMATRIX world_view_projection;
  };

  void Fit(const float minimum[3], const float maximum[3]) {
    const DirectX::XMVECTOR previous_direction = DirectX::XMVector3Normalize(
        DirectX::XMVectorSubtract(Eye(), Target()));
    for (int axis = 0; axis < 3; ++axis)
      target_[axis] = (minimum[axis] + maximum[axis]) * 0.5f;
    const float dx = maximum[0] - minimum[0];
    const float dy = maximum[1] - minimum[1];
    const float dz = maximum[2] - minimum[2];
    radius_ = std::max(std::sqrt(dx * dx + dy * dy + dz * dz) * 0.5f,
                       0.001f);
    distance_ = radius_ * 2.7f;
    DirectX::XMFLOAT3 fitted_eye;
    DirectX::XMStoreFloat3(
        &fitted_eye,
        DirectX::XMVectorAdd(
            Target(), DirectX::XMVectorScale(previous_direction, distance_)));
    eye_[0] = fitted_eye.x;
    eye_[1] = fitted_eye.y;
    eye_[2] = fitted_eye.z;
    near_plane_ = std::max(radius_ * 0.001f, 0.001f);
    far_plane_ = std::max(radius_ * 100.0f, 1000.0f);
  }

  void SetPose(const float eye[3], const float target[3], const float up[3]) {
    std::copy(eye, eye + 3, eye_);
    std::copy(target, target + 3, target_);
    DirectX::XMFLOAT3 normalized_up;
    DirectX::XMStoreFloat3(
        &normalized_up,
        DirectX::XMVector3Normalize(
            DirectX::XMVectorSet(up[0], up[1], up[2], 0)));
    up_[0] = normalized_up.x;
    up_[1] = normalized_up.y;
    up_[2] = normalized_up.z;
    distance_ = std::max(
        DirectX::XMVectorGetX(DirectX::XMVector3Length(
            DirectX::XMVectorSubtract(Eye(), Target()))),
        0.0001f);
  }

  void SetLens(float fov_radians, float near_plane, float far_plane) {
    if (std::isfinite(fov_radians) && fov_radians > 0 &&
        fov_radians < DirectX::XM_PI)
      fov_radians_ = fov_radians;
    if (std::isfinite(near_plane) && std::isfinite(far_plane) &&
        near_plane > 0 && far_plane > near_plane) {
      near_plane_ = near_plane;
      far_plane_ = far_plane;
    }
  }

  void OrbitPixels(float dx, float dy) {
    OrbitRadians(dx / 180.0f, dy / 180.0f);
  }

  void OrbitRadians(float yaw, float pitch) {
    const DirectX::XMVECTOR focus = Target();
    const DirectX::XMVECTOR safe_up = DirectX::XMVector3Normalize(Up());
    DirectX::XMVECTOR eye_offset =
        DirectX::XMVectorSubtract(Eye(), focus);
    eye_offset = Rotate(eye_offset, safe_up, -yaw);
    const DirectX::XMVECTOR yaw_eye =
        DirectX::XMVectorAdd(focus, eye_offset);
    const DirectX::XMVECTOR forward = DirectX::XMVector3Normalize(
        DirectX::XMVectorSubtract(focus, yaw_eye));
    const DirectX::XMVECTOR right = DirectX::XMVector3Normalize(
        DirectX::XMVector3Cross(forward, safe_up));
    eye_offset = Rotate(eye_offset, right,
                        std::clamp(pitch, -DirectX::XM_PIDIV2 + 0.01f,
                                   DirectX::XM_PIDIV2 - 0.01f));
    DirectX::XMFLOAT3 eye;
    DirectX::XMStoreFloat3(&eye, DirectX::XMVectorAdd(focus, eye_offset));
    eye_[0] = eye.x;
    eye_[1] = eye.y;
    eye_[2] = eye.z;
    const DirectX::XMVECTOR final_forward = DirectX::XMVector3Normalize(
        DirectX::XMVectorSubtract(Target(), Eye()));
    DirectX::XMFLOAT3 up;
    DirectX::XMStoreFloat3(
        &up, DirectX::XMVector3Normalize(
                 DirectX::XMVector3Cross(right, final_forward)));
    up_[0] = up.x;
    up_[1] = up.y;
    up_[2] = up.z;
  }

  void PanPixels(float dx, float dy) {
    const float scale = distance_ * 0.0015f;
    const DirectX::XMVECTOR eye = Eye();
    const DirectX::XMVECTOR target = Target();
    const DirectX::XMVECTOR forward =
        DirectX::XMVector3Normalize(DirectX::XMVectorSubtract(target, eye));
    const DirectX::XMVECTOR right = DirectX::XMVector3Normalize(
        DirectX::XMVector3Cross(forward, Up()));
    const DirectX::XMVECTOR up = DirectX::XMVector3Normalize(
        DirectX::XMVector3Cross(right, forward));
    DirectX::XMFLOAT3 delta;
    DirectX::XMStoreFloat3(
        &delta, DirectX::XMVectorAdd(
                    DirectX::XMVectorScale(right, -dx * scale),
                    DirectX::XMVectorScale(up, dy * scale)));
    target_[0] += delta.x;
    target_[1] += delta.y;
    target_[2] += delta.z;
    eye_[0] += delta.x;
    eye_[1] += delta.y;
    eye_[2] += delta.z;
  }

  void ZoomFactor(float factor) {
    distance_ = std::clamp(distance_ * factor, radius_ * 0.02f,
                           radius_ * 100.0f);
    const DirectX::XMVECTOR direction = DirectX::XMVector3Normalize(
        DirectX::XMVectorSubtract(Eye(), Target()));
    DirectX::XMFLOAT3 eye;
    DirectX::XMStoreFloat3(
        &eye, DirectX::XMVectorAdd(
                  Target(), DirectX::XMVectorScale(direction, distance_)));
    eye_[0] = eye.x;
    eye_[1] = eye.y;
    eye_[2] = eye.z;
  }

  void ZoomWheel(short wheel_delta, short wheel_unit = 120) {
    ZoomFactor(std::pow(0.88f,
                        static_cast<float>(wheel_delta) / wheel_unit));
  }

  DirectX::XMVECTOR Target() const {
    return DirectX::XMVectorSet(target_[0], target_[1], target_[2], 1);
  }

  DirectX::XMVECTOR Eye() const {
    return DirectX::XMVectorSet(eye_[0], eye_[1], eye_[2], 1);
  }

  DirectX::XMVECTOR Up() const {
    return DirectX::XMVectorSet(up_[0], up_[1], up_[2], 0);
  }

  Frame BuildFrame(float aspect) const {
    const DirectX::XMMATRIX world = DirectX::XMMatrixIdentity();
    const DirectX::XMMATRIX view = DirectX::XMMatrixLookAtLH(
        Eye(), Target(), Up());
    const DirectX::XMMATRIX projection = DirectX::XMMatrixPerspectiveFovLH(
        fov_radians_, aspect, near_plane_, far_plane_);
    return {world, view, projection, world * view * projection};
  }

  float Radius() const { return radius_; }
  float Distance() const { return distance_; }
  float NearPlane() const { return near_plane_; }
  float FarPlane() const { return far_plane_; }

 private:
  static DirectX::XMVECTOR Rotate(DirectX::FXMVECTOR vector,
                                  DirectX::FXMVECTOR axis, float angle) {
    const DirectX::XMVECTOR unit = DirectX::XMVector3Normalize(axis);
    const float cosine = std::cos(angle);
    const float sine = std::sin(angle);
    return DirectX::XMVectorAdd(
        DirectX::XMVectorAdd(
            DirectX::XMVectorScale(vector, cosine),
            DirectX::XMVectorScale(
                DirectX::XMVector3Cross(unit, vector), sine)),
        DirectX::XMVectorScale(
            unit, DirectX::XMVectorGetX(DirectX::XMVector3Dot(unit, vector)) *
                      (1.0f - cosine)));
  }

  float eye_[3]{1.45620346f, 1.11276138f, -2.37512803f};
  float target_[3]{};
  float up_[3]{0.0f, 1.0f, 0.0f};
  float radius_ = 1.0f;
  float distance_ = 3.0f;
  float fov_radians_ = DirectX::XMConvertToRadians(42.0f);
  float near_plane_ = 0.001f;
  float far_plane_ = 1000.0f;
};

}  // namespace flcad::render

#endif
