#ifndef RUNNER_NATIVE_VIEWPORT_HOST_H_
#define RUNNER_NATIVE_VIEWPORT_HOST_H_

#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <flutter/texture_registrar.h>

#include <d3d11.h>
#include <wrl/client.h>

#include <chrono>
#include <atomic>
#include <cstdint>
#include <memory>
#include <mutex>
#include <string>
#include <unordered_map>
#include <vector>

#include "cad_camera_system.h"

class NativeViewportHost {
 public:
  NativeViewportHost(flutter::BinaryMessenger* messenger,
                     flutter::TextureRegistrar* registrar);
  ~NativeViewportHost();

  NativeViewportHost(const NativeViewportHost&) = delete;
  NativeViewportHost& operator=(const NativeViewportHost&) = delete;

 private:
  struct Vertex { float x, y, z, nx, ny, nz; };
  struct SceneEntity {
    std::string id;
    std::vector<Vertex> vertices;
    std::vector<uint32_t> indices;
    Microsoft::WRL::ComPtr<ID3D11Buffer> vertex_buffer;
    Microsoft::WRL::ComPtr<ID3D11Buffer> index_buffer;
    bool visible = true;
  };
  struct Constants { float matrix[16]; float color[4]; };

  void HandleMethod(const flutter::MethodCall<flutter::EncodableValue>& call,
                    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void Initialize(uint32_t width, uint32_t height);
  void Resize(uint32_t width, uint32_t height);
  void Shutdown();
  void ApplySnapshot(const flutter::EncodableMap& snapshot, bool replace);
  void RemoveEntity(const std::string& id);
  void Render();
  void Fit();
  void Orbit(double dx, double dy);
  void Pan(double dx, double dy);
  void Zoom(double factor);
  void SetCamera(const flutter::EncodableMap& arguments);
  void RenderTextureProbe();
  flutter::EncodableMap Stats() const;
  void CreateDevice();
  void CreatePipeline();
  void CreateTarget(uint32_t width, uint32_t height);
  void Upload(SceneEntity& entity);
  const FlutterDesktopGpuSurfaceDescriptor* SurfaceDescriptor(size_t width,
                                                               size_t height);

  flutter::TextureRegistrar* registrar_ = nullptr;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  std::unique_ptr<flutter::TextureVariant> flutter_texture_;
  int64_t texture_id_ = -1;
  mutable std::mutex mutex_;
  Microsoft::WRL::ComPtr<ID3D11Device> device_;
  Microsoft::WRL::ComPtr<ID3D11DeviceContext> context_;
  Microsoft::WRL::ComPtr<ID3D11Texture2D> target_texture_;
  HANDLE shared_texture_handle_ = nullptr;
  Microsoft::WRL::ComPtr<ID3D11RenderTargetView> target_view_;
  Microsoft::WRL::ComPtr<ID3D11Texture2D> depth_texture_;
  Microsoft::WRL::ComPtr<ID3D11DepthStencilView> depth_view_;
  Microsoft::WRL::ComPtr<ID3D11VertexShader> vertex_shader_;
  Microsoft::WRL::ComPtr<ID3D11PixelShader> pixel_shader_;
  Microsoft::WRL::ComPtr<ID3D11InputLayout> input_layout_;
  Microsoft::WRL::ComPtr<ID3D11Buffer> constants_;
  Microsoft::WRL::ComPtr<ID3D11RasterizerState> rasterizer_;
  Microsoft::WRL::ComPtr<ID3D11DepthStencilState> depth_state_;
  std::unordered_map<std::string, SceneEntity> entities_;
  FlutterDesktopGpuSurfaceDescriptor surface_descriptor_{};
  uint32_t width_ = 1, height_ = 1;
  flcad::render::CadCameraSystem camera_;
  double fps_ = 0, upload_ms_ = 0, render_ms_ = 0, picking_ms_ = 0;
  uint64_t frames_ = 0, triangles_ = 0;
  uint64_t set_camera_calls_ = 0;
  uint64_t render_calls_ = 0;
  uint64_t constant_buffer_updates_ = 0;
  uint64_t draw_indexed_calls_ = 0;
  uint64_t fit_calls_ = 0;
  std::atomic<uint64_t> texture_callbacks_{0};
  uint64_t callback_window_count_ = 0;
  double texture_callback_hz_ = 0;
  std::chrono::steady_clock::time_point callback_metric_start_{};
  std::atomic<uint64_t> frame_marks_{0};
  std::atomic<uint64_t> successful_frame_marks_{0};
  size_t last_requested_width_ = 0;
  size_t last_requested_height_ = 0;
  bool texture_registered_ = false;
  uint32_t sampled_bgra_ = 0;
  uint32_t sampled_clear_bgra_ = 0;
  std::wstring adapter_name_;
  std::chrono::steady_clock::time_point metric_start_{};
};

#endif
