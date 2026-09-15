// Windows-only offscreen smoke of the actual renderer. No Flutter engine,
// source admission, managed assets or production capture API is introduced.
#include <DirectXMath.h>
#include <algorithm>
#include <atomic>
#include <chrono>
#include <climits>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <d3d11.h>
#include <d3dcompiler.h>
#include <flutter/standard_message_codec.h>
#include <flutter/standard_method_codec.h>
#include <flutter/texture_registrar.h>
#include <fstream>
#include <iostream>
#include <memory>
#include <mutex>
#include <string>
#include <unordered_map>
#include <vector>
#include <wrl/client.h>

// Include dependencies before granting this test access to renderer internals.
#define private public
#include "../windows/runner/native_viewport_host.h"
#undef private
#include "../windows/runner/native_viewport_host.cpp"

struct TestMessenger : flutter::BinaryMessenger {
  void Send(const std::string &, const uint8_t *, size_t,
            flutter::BinaryReply = nullptr) const override {}
  void SetMessageHandler(const std::string &,
                         flutter::BinaryMessageHandler) override {}
};

struct GatedRegistrar : flutter::TextureRegistrar {
  flutter::TextureVariant *texture = nullptr;
  std::function<void()> pending;
  int64_t RegisterTexture(flutter::TextureVariant *value) override {
    texture = value;
    return 1;
  }
  bool MarkTextureFrameAvailable(int64_t) override { return true; }
  bool UnregisterTexture(int64_t) override {
    throw std::runtime_error("Synchronous retirement used");
  }
  void UnregisterTexture(int64_t, std::function<void()> callback) override {
    pending = callback;
  }
};

void Require(bool value, const char *reason) {
  if (!value)
    throw std::runtime_error(reason);
}

std::vector<uint32_t> Pixels(NativeViewportHost &host) {
  D3D11_TEXTURE2D_DESC desc{};
  host.target_texture_->GetDesc(&desc);
  desc.BindFlags = desc.MiscFlags = 0;
  desc.Usage = D3D11_USAGE_STAGING;
  desc.CPUAccessFlags = D3D11_CPU_ACCESS_READ;
  ComPtr<ID3D11Texture2D> readback;
  Check(host.device_->CreateTexture2D(&desc, nullptr, &readback),
        "readback texture");
  host.context_->CopyResource(readback.Get(), host.target_texture_.Get());
  D3D11_MAPPED_SUBRESOURCE mapped{};
  Check(host.context_->Map(readback.Get(), 0, D3D11_MAP_READ, 0, &mapped),
        "readback map");
  std::vector<uint32_t> result(host.width_ * host.height_);
  for (uint32_t y = 0; y < host.height_; ++y)
    std::memcpy(result.data() + y * host.width_,
                static_cast<uint8_t *>(mapped.pData) + y * mapped.RowPitch,
                host.width_ * sizeof(uint32_t));
  host.context_->Unmap(readback.Get(), 0);
  return result;
}

int main(int argc, char **argv) {
  try {
    TestMessenger messenger;
    GatedRegistrar registrar;
    {
      auto retiring =
          std::make_unique<NativeViewportHost>(&messenger, &registrar);
      retiring->Initialize(32, 32);
      auto surface = retiring->surface_state_;
      bool completed = false;
      retiring->Shutdown([&] { completed = true; });
      Require(!completed && registrar.pending,
              "Shutdown did not wait for unregister completion");
      retiring.reset();
      Require(surface->Describe(32, 32) == nullptr,
              "Retired callback reached destroyed host/resources");
      Require(std::get_if<flutter::GpuSurfaceTexture>(registrar.texture) !=
                  nullptr,
              "Texture variant destroyed before unregister completion");
      registrar.pending();
      Require(completed, "Shutdown completion missing");
      registrar.pending = {};
    }
    NativeViewportHost host(&messenger, nullptr);
    host.CreateDevice();
    host.CreatePipeline();
    host.CreateTarget(256, 256);
    uint32_t reference = 0;
    for (int step = 0; step < 12; ++step) {
      const auto rotation = XMMatrixRotationY(step * XM_PI / 6) *
                            XMMatrixRotationX(step * XM_PI / 13);
      NativeViewportHost::SceneEntity entity;
      entity.id = "fixture";
      const XMFLOAT3 positions[] = {
          {-1, -1, 0}, {1, -1, 0}, {1, 1, 0}, {-1, 1, 0}};
      const auto normal =
          XMVector3TransformNormal(XMVectorSet(0, 0, 1, 0), rotation);
      XMFLOAT3 n{};
      XMStoreFloat3(&n, normal);
      for (const auto &position : positions) {
        XMFLOAT3 p{};
        XMStoreFloat3(
            &p, XMVector3TransformCoord(XMLoadFloat3(&position), rotation));
        entity.vertices.push_back({p.x, p.y, p.z, n.x, n.y, n.z});
      }
      entity.indices = {0, 1, 2, 0, 2, 3};
      for (const int i : {0, 1, 1, 2, 2, 3, 3, 0})
        entity.display_edges.push_back(entity.vertices[i]);
      host.Upload(entity);
      host.entities_.clear();
      host.entities_.emplace(entity.id, std::move(entity));
      XMFLOAT3 eye{}, up{};
      XMStoreFloat3(&eye,
                    XMVector3TransformCoord(XMVectorSet(0, 0, 5, 1), rotation));
      XMStoreFloat3(
          &up, XMVector3TransformNormal(XMVectorSet(0, 1, 0, 0), rotation));
      const float target[] = {0, 0, 0};
      host.camera_.SetPose(&eye.x, target, &up.x);
      host.camera_.SetLens(XM_PI / 4, .1f, 100);
      host.render_style_ = 0;
      host.Render();
      const auto shaded = Pixels(host);
      const auto center = shaded[128 * 256 + 128];
      if (step == 0)
        reference = center;
      for (int shift : {0, 8, 16})
        Require(std::abs(int((center >> shift) & 255) -
                         int((reference >> shift) & 255)) <= 1,
                "camera-linked lighting changes under rigid rotation");
      Require(((center >> 16) & 255) > 50 && (center & 255) > 100,
              "blue material is too dark");
      host.render_style_ = 1;
      host.Render();
      const auto edged = Pixels(host);
      Require(edged[128 * 256 + 128] == center,
              "CAD edge pass changed interior shaded color");
      size_t changed = 0;
      size_t black_edges = 0;
      for (size_t i = 0; i < shaded.size(); ++i) {
        if (edged[i] == shaded[i])
          continue;
        ++changed;
        const auto blue = edged[i] & 255;
        if (blue < (shaded[i] & 255) * .75)
          ++black_edges;
      }
      double effective_row_width = 0;
      for (size_t x = 0; x < 256; ++x) {
        const size_t i = 128 * 256 + x;
        const double before = shaded[i] & 255;
        const double after = edged[i] & 255;
        if (before > 5)
          effective_row_width +=
              std::clamp((before - after) / (before - 5), 0.0, 1.0);
      }
      if (step == 0)
        std::cout << "CAD two-contour effective width=" << effective_row_width
                  << '\n';
      Require(
          effective_row_width > .8 && effective_row_width <= 2.5,
          "CAD contour exceeds 1.25 screen pixels including alpha coverage");
      Require(changed > 150 && changed < 4000,
              "edge pass missing or covering shaded surface");
      Require(black_edges > 50,
              "CAD contours do not darken the bright material");
      // An opaque operational selection must leave the CAD contours readable.
      const uint32_t selected_indices[] = {0, 1, 2};
      D3D11_BUFFER_DESC selection_desc{};
      selection_desc.ByteWidth = sizeof(selected_indices);
      selection_desc.Usage = D3D11_USAGE_IMMUTABLE;
      selection_desc.BindFlags = D3D11_BIND_INDEX_BUFFER;
      D3D11_SUBRESOURCE_DATA selection_source{selected_indices};
      Check(
          host.device_->CreateBuffer(&selection_desc, &selection_source,
                                     &host.operational_selection_index_buffer_),
          "selection index buffer");
      host.operational_selection_index_count_ = 3;
      host.operational_selection_entity_id_ = "fixture";
      host.render_style_ = 0;
      host.Render();
      const auto selected_fill = Pixels(host);
      host.render_style_ = 1;
      host.Render();
      const auto selected = Pixels(host);
      size_t selected_black_edges = 0;
      for (size_t i = 0; i < edged.size(); ++i) {
        if (selected[i] != selected_fill[i] &&
            (selected[i] & 255) < (selected_fill[i] & 255) * .75)
          ++selected_black_edges;
      }
      Require(selected_black_edges > 50, "selection obscured normal CAD edges");
      host.operational_selection_index_buffer_.Reset();
      host.operational_selection_index_count_ = 0;
      host.operational_selection_entity_id_.clear();
      host.render_style_ = 2;
      host.Render();
      const auto wire = Pixels(host);
      Require(wire[128 * 256 + 128] == wire[0],
              "wireframe published a filled surface");
      Require(std::count_if(wire.begin(), wire.end(),
                            [&](uint32_t p) { return p != wire[0]; }) > 50,
              "wireframe edges are absent");
      host.operational_selection_entity_id_ = host.entities_.begin()->first;
      host.operational_selection_index_buffer_ =
          host.entities_.begin()->second.index_buffer;
      host.operational_selection_index_count_ =
          host.entities_.begin()->second.indices.size();
      host.Render();
      const auto selected_wire = Pixels(host);
      Require(selected_wire[128 * 256 + 128] == selected_wire[0],
              "wireframe selection published a filled surface");
      Require(selected_wire != wire, "wireframe selection lost its contour");
      host.operational_selection_index_buffer_.Reset();
      host.operational_selection_index_count_ = 0;
      host.operational_selection_entity_id_.clear();
      // A back-oriented surface retains ambient; no normal flipping allowed.
      auto &resident = host.entities_.begin()->second;
      for (auto &vertex : resident.vertices) {
        vertex.nx = -vertex.nx;
        vertex.ny = -vertex.ny;
        vertex.nz = -vertex.nz;
      }
      for (size_t triangle = 0; triangle < resident.indices.size();
           triangle += 3)
        std::swap(resident.indices[triangle], resident.indices[triangle + 1]);
      host.Upload(resident);
      host.render_style_ = 0;
      host.Render();
      const auto ambient_pixels = Pixels(host);
      const auto ambient = ambient_pixels[128 * 256 + 128];
      Require(((ambient >> 16) & 255) >= 30 && (ambient & 255) >= 70,
              "oriented back surface lost bounded ambient light");
      Require(ambient != center, "normal orientation was silently inverted");
      resident.selected = true;
      host.Render();
      const auto selected_pixels = Pixels(host);
      Require(selected_pixels != ambient_pixels,
              "Entity selection is absent on native backend");
      host.render_style_ = 3;
      host.Render();
      Require(Pixels(host) != selected_pixels,
              "Selected entity lost transparency");
      resident.selected = false;
    }
    if (argc > 1) {
      // A bounded presentation snapshot produced by the real CAF runtime test;
      // this is display data, never a source file or durable mesh asset.
      std::ifstream input(argv[1], std::ios::binary | std::ios::ate);
      const auto size = input.tellg();
      Require(input.good() && size > 0 && size <= 32 * 1024 * 1024,
              "Invalid LOD snapshot size");
      std::vector<uint8_t> bytes(static_cast<size_t>(size));
      input.seekg(0);
      input.read(reinterpret_cast<char *>(bytes.data()), size);
      const auto decoded =
          flutter::StandardMessageCodec::GetInstance().DecodeMessage(
              bytes.data(), bytes.size());
      Require(decoded != nullptr, "LOD snapshot decode failed");
      const auto *map = std::get_if<flutter::EncodableMap>(decoded.get());
      Require(map != nullptr, "Invalid LOD snapshot");
      host.render_style_ = 0;
      host.ApplySnapshot(*map, true);
      host.Fit();
      host.Render();
      Require(host.entities_.size() == 1, "LOD entity duplicated");
      const auto &resident = host.entities_.begin()->second;
      Require(resident.vertices.size() <= 125000 &&
                  resident.indices.size() <= 250000 * 3,
              "GPU LOD budget exceeded");
      const auto image = Pixels(host);
      Require(std::count_if(image.begin(), image.end(),
                            [&](uint32_t p) { return p != image[0]; }) > 100,
              "LOD solid is not visible");
      if (argc > 2) {
        // Safe visual evidence outside the repository, no source identity.
        std::ofstream bitmap(argv[2], std::ios::binary);
        uint8_t header[54]{};
        header[0] = 'B';
        header[1] = 'M';
        auto put = [&](int offset, uint32_t value) {
          for (int i = 0; i < 4; i++)
            header[offset + i] = uint8_t(value >> (i * 8));
        };
        put(2, 54 + uint32_t(image.size() * 4));
        put(10, 54);
        put(14, 40);
        put(18, 256);
        put(22, uint32_t(-256));
        header[26] = 1;
        header[28] = 32;
        bitmap.write(reinterpret_cast<char *>(header), sizeof(header));
        bitmap.write(reinterpret_cast<const char *>(image.data()),
                     image.size() * 4);
      }
      std::cout << "D3D11 dense STL codec/upload/render: vertices="
                << resident.vertices.size()
                << " triangles=" << resident.indices.size() / 3 << " passed\n";
    }
    host.render_style_ = 3;
    NativeViewportHost::SceneEntity cad_fixture;
    cad_fixture.id = "step-fixture";
    cad_fixture.vertices = {
        {-1, -1, 0, 0, 0, 1}, {1, -1, 0, 0, 0, 1}, {0, 1, 0, 0, 0, 1}};
    cad_fixture.indices = {0, 1, 2};
    host.Upload(cad_fixture);
    host.entities_[cad_fixture.id] = std::move(cad_fixture);
    Require(host.entities_.size() == 2, "Mixed scene lost a native entity");
    for (auto &[id, entity] : host.entities_) {
      const auto vertex_buffer = entity.vertex_buffer.Get();
      const auto index_buffer = entity.index_buffer.Get();
      for (const bool visible : {false, true}) {
        const auto revision = host.scene_revision_ + 1;
        host.ApplySnapshot({{flutter::EncodableValue("revision"),
                             flutter::EncodableValue(revision)},
                            {flutter::EncodableValue("entities"),
                             flutter::EncodableValue(flutter::EncodableList{
                                 flutter::EncodableValue(flutter::EncodableMap{
                                     {flutter::EncodableValue("id"),
                                      flutter::EncodableValue(id)},
                                     {flutter::EncodableValue("visible"),
                                      flutter::EncodableValue(visible)}})})}},
                           false);
        Require(entity.visible == visible &&
                    entity.vertex_buffer.Get() == vertex_buffer &&
                    entity.index_buffer.Get() == index_buffer,
                "Hide/Show recreated native geometry buffers");
      }
      const auto renders = host.render_calls_;
      host.ApplySnapshot({{flutter::EncodableValue("revision"),
                           flutter::EncodableValue(host.scene_revision_ - 1)},
                          {flutter::EncodableValue("entities"),
                           flutter::EncodableValue(flutter::EncodableList{
                               flutter::EncodableValue(flutter::EncodableMap{
                                   {flutter::EncodableValue("id"),
                                    flutter::EncodableValue(id)},
                                   {flutter::EncodableValue("visible"),
                                    flutter::EncodableValue(false)}})})}},
                         false);
      Require(entity.visible && host.render_calls_ == renders,
              "Late visibility revision changed/rendered the scene");
    }
    host.Render();
    const auto translucent = Pixels(host);
    host.render_style_ = 0;
    host.Render();
    Require(translucent != Pixels(host),
            "Native transparency did not change composition");
    for (int cycle = 0; cycle < 3; ++cycle) {
      host.Shutdown();
      Require(host.entities_.empty() && !host.device_ && !host.context_ &&
                  !host.pick_texture_ && !host.pick_readback_ &&
                  !host.pick_target_ && !host.constants_ &&
                  !host.vertex_shader_ &&
                  !host.operational_selection_index_buffer_ &&
                  !host.operational_hover_index_buffer_,
              "Inactive native backend retains visual resources");
      host.CreateDevice();
      host.CreatePipeline();
      host.CreateTarget(256, 256);
      Require(host.entities_.empty() && host.device_ && host.target_view_,
              "Native backend could not restart cleanly");
    }
    std::cout << "D3D11: transparency and three complete shutdown/reinitialize "
                 "cycles passed\n";
    std::cout << "D3D11: 12 rigid orientations, shaded/edges/wireframe, "
                 "ambient passed\n";
    return 0;
  } catch (const std::exception &error) {
    std::cerr << error.what() << '\n';
    return 1;
  }
}
