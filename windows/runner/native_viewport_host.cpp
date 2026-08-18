#include "native_viewport_host.h"

#include <d3dcompiler.h>
#include <DirectXMath.h>
#include <flutter/standard_method_codec.h>

#include <algorithm>
#include <cmath>
#include <cstring>
#include <stdexcept>

using Microsoft::WRL::ComPtr;
using namespace DirectX;

namespace {
const char* kShader = R"(
cbuffer Scene : register(b0) { row_major float4x4 mvp; float4 color; };
struct In { float3 p:POSITION; float3 n:NORMAL; };
struct Out { float4 p:SV_POSITION; float3 n:NORMAL; };
Out VSMain(In i) { Out o; o.p=mul(float4(i.p,1),mvp); o.n=i.n; return o; }
float4 PSMain(Out i):SV_TARGET {
 float3 n=normalize(i.n); if(n.z<0)n=-n;
 float d=.18+.58*saturate(dot(n,normalize(float3(-.35,.55,.75))))+
         .18*saturate(dot(n,normalize(float3(.65,.18,.55))));
 return float4(color.rgb*d,1);
})";

void Check(HRESULT value, const char* operation) {
  if (FAILED(value)) throw std::runtime_error(operation);
}

const flutter::EncodableValue* Find(const flutter::EncodableMap& map,
                                    const char* key) {
  const auto found = map.find(flutter::EncodableValue(key));
  return found == map.end() ? nullptr : &found->second;
}

double Number(const flutter::EncodableValue& value) {
  if (const auto* v = std::get_if<double>(&value)) return *v;
  if (const auto* v = std::get_if<int64_t>(&value)) return static_cast<double>(*v);
  if (const auto* v = std::get_if<int32_t>(&value)) return static_cast<double>(*v);
  return 0;
}

void ReleaseFlutterTexture(void* context) {
  if (context) static_cast<ID3D11Texture2D*>(context)->Release();
}

}  // namespace

NativeViewportHost::NativeViewportHost(flutter::BinaryMessenger* messenger,
                                       flutter::TextureRegistrar* registrar)
    : registrar_(registrar) {
  channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "flcad/native_viewport",
      &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) { HandleMethod(call, std::move(result)); });
}

NativeViewportHost::~NativeViewportHost() { Shutdown(); }

void NativeViewportHost::HandleMethod(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  try {
    const auto* arguments = std::get_if<flutter::EncodableMap>(call.arguments());
    if (call.method_name() == "initialize") {
      const uint32_t width = arguments && Find(*arguments, "width")
          ? static_cast<uint32_t>(Number(*Find(*arguments, "width"))) : 1;
      const uint32_t height = arguments && Find(*arguments, "height")
          ? static_cast<uint32_t>(Number(*Find(*arguments, "height"))) : 1;
      Initialize(width, height);
      result->Success(flutter::EncodableValue(texture_id_));
    } else if (call.method_name() == "resize" && arguments) {
      Resize(static_cast<uint32_t>(Number(*Find(*arguments, "width"))),
             static_cast<uint32_t>(Number(*Find(*arguments, "height"))));
      result->Success();
    } else if ((call.method_name() == "snapshot" || call.method_name() == "delta") && arguments) {
      ApplySnapshot(*arguments, call.method_name() == "snapshot");
      result->Success();
    } else if (call.method_name() == "remove" && arguments) {
      if (const auto* id = std::get_if<std::string>(Find(*arguments, "id"))) RemoveEntity(*id);
      result->Success();
    } else if (call.method_name() == "orbit" && arguments) {
      Orbit(Number(*Find(*arguments, "dx")), Number(*Find(*arguments, "dy"))); result->Success();
    } else if (call.method_name() == "pan" && arguments) {
      Pan(Number(*Find(*arguments, "dx")), Number(*Find(*arguments, "dy"))); result->Success();
    } else if (call.method_name() == "zoom" && arguments) {
      Zoom(Number(*Find(*arguments, "factor"))); result->Success();
    } else if (call.method_name() == "fit") {
      Fit(); Render(); result->Success();
    } else if (call.method_name() == "setCamera" && arguments) {
      SetCamera(*arguments); result->Success();
    } else if (call.method_name() == "textureProbe") {
      RenderTextureProbe(); result->Success();
    } else if (call.method_name() == "stats") {
      result->Success(flutter::EncodableValue(Stats()));
    } else if (call.method_name() == "shutdown") {
      Shutdown(); result->Success();
    } else {
      result->NotImplemented();
    }
  } catch (const std::exception& error) {
    result->Error("native_viewport", error.what());
  }
}

void NativeViewportHost::Initialize(uint32_t width, uint32_t height) {
  std::scoped_lock lock(mutex_);
  if (!device_) { CreateDevice(); CreatePipeline(); }
  CreateTarget(std::max(width, 1u), std::max(height, 1u));
  if (texture_id_ < 0) {
    flutter_texture_ = std::make_unique<flutter::TextureVariant>(
        flutter::GpuSurfaceTexture(kFlutterDesktopGpuSurfaceTypeDxgiSharedHandle,
          [this](size_t width, size_t height) { return SurfaceDescriptor(width, height); }));
    texture_id_ = registrar_->RegisterTexture(flutter_texture_.get());
    texture_registered_ = texture_id_ >= 0;
  }
  metric_start_ = std::chrono::steady_clock::now();
  callback_metric_start_ = metric_start_;
  Render();
}

void NativeViewportHost::CreateDevice() {
  UINT flags = 0;
#ifndef NDEBUG
  flags |= D3D11_CREATE_DEVICE_DEBUG;
#endif
  D3D_FEATURE_LEVEL level{};
  Check(D3D11CreateDevice(nullptr, D3D_DRIVER_TYPE_HARDWARE, nullptr, flags,
      nullptr, 0, D3D11_SDK_VERSION, &device_, &level, &context_), "D3D11 device");
  ComPtr<IDXGIDevice> dxgi; ComPtr<IDXGIAdapter> adapter; DXGI_ADAPTER_DESC desc{};
  if (SUCCEEDED(device_.As(&dxgi)) && SUCCEEDED(dxgi->GetAdapter(&adapter)) &&
      SUCCEEDED(adapter->GetDesc(&desc))) adapter_name_ = desc.Description;
}

void NativeViewportHost::CreatePipeline() {
  ComPtr<ID3DBlob> vs, ps, errors;
  Check(D3DCompile(kShader, std::strlen(kShader), nullptr, nullptr, nullptr,
      "VSMain", "vs_5_0", D3DCOMPILE_ENABLE_STRICTNESS, 0, &vs, &errors), "vertex shader");
  Check(D3DCompile(kShader, std::strlen(kShader), nullptr, nullptr, nullptr,
      "PSMain", "ps_5_0", D3DCOMPILE_ENABLE_STRICTNESS, 0, &ps, &errors), "pixel shader");
  Check(device_->CreateVertexShader(vs->GetBufferPointer(), vs->GetBufferSize(), nullptr,
      &vertex_shader_), "create VS");
  Check(device_->CreatePixelShader(ps->GetBufferPointer(), ps->GetBufferSize(), nullptr,
      &pixel_shader_), "create PS");
  const D3D11_INPUT_ELEMENT_DESC elements[] = {
    {"POSITION",0,DXGI_FORMAT_R32G32B32_FLOAT,0,0,D3D11_INPUT_PER_VERTEX_DATA,0},
    {"NORMAL",0,DXGI_FORMAT_R32G32B32_FLOAT,0,12,D3D11_INPUT_PER_VERTEX_DATA,0}};
  Check(device_->CreateInputLayout(elements, 2, vs->GetBufferPointer(), vs->GetBufferSize(),
      &input_layout_), "input layout");
  D3D11_BUFFER_DESC cb{}; cb.ByteWidth=sizeof(Constants); cb.Usage=D3D11_USAGE_DEFAULT;
  cb.BindFlags=D3D11_BIND_CONSTANT_BUFFER;
  Check(device_->CreateBuffer(&cb,nullptr,&constants_),"constants");
  D3D11_RASTERIZER_DESC raster{}; raster.FillMode=D3D11_FILL_SOLID;
  raster.CullMode=D3D11_CULL_NONE; raster.DepthClipEnable=TRUE;
  Check(device_->CreateRasterizerState(&raster,&rasterizer_),"rasterizer");
  D3D11_DEPTH_STENCIL_DESC depth{}; depth.DepthEnable=TRUE;
  depth.DepthWriteMask=D3D11_DEPTH_WRITE_MASK_ALL; depth.DepthFunc=D3D11_COMPARISON_LESS;
  Check(device_->CreateDepthStencilState(&depth,&depth_state_),"depth state");
}

void NativeViewportHost::CreateTarget(uint32_t width, uint32_t height) {
  width_=width; height_=height; target_view_.Reset(); target_texture_.Reset();
  shared_texture_handle_ = nullptr;
  depth_view_.Reset(); depth_texture_.Reset();
  D3D11_TEXTURE2D_DESC texture{}; texture.Width=width; texture.Height=height;
  texture.MipLevels=1; texture.ArraySize=1; texture.Format=DXGI_FORMAT_B8G8R8A8_UNORM;
  texture.SampleDesc.Count=1; texture.Usage=D3D11_USAGE_DEFAULT;
  texture.BindFlags=D3D11_BIND_RENDER_TARGET|D3D11_BIND_SHADER_RESOURCE;
  texture.MiscFlags=D3D11_RESOURCE_MISC_SHARED;
  Check(device_->CreateTexture2D(&texture,nullptr,&target_texture_),"external texture");
  ComPtr<IDXGIResource> shared_resource;
  Check(target_texture_.As(&shared_resource), "external texture DXGI resource");
  Check(shared_resource->GetSharedHandle(&shared_texture_handle_),
        "external texture shared handle");
  Check(device_->CreateRenderTargetView(target_texture_.Get(),nullptr,&target_view_),"external RTV");
  texture.Format=DXGI_FORMAT_D32_FLOAT; texture.BindFlags=D3D11_BIND_DEPTH_STENCIL;
  texture.MiscFlags=0;
  Check(device_->CreateTexture2D(&texture,nullptr,&depth_texture_),"depth texture");
  Check(device_->CreateDepthStencilView(depth_texture_.Get(),nullptr,&depth_view_),"depth view");
  surface_descriptor_ = {sizeof(surface_descriptor_), target_texture_.Get(), width_, height_,
      width_, height_, kFlutterDesktopPixelFormatBGRA8888,
      ReleaseFlutterTexture, target_texture_.Get()};
}

void NativeViewportHost::Resize(uint32_t width, uint32_t height) {
  std::scoped_lock lock(mutex_);
  if (!device_ || (width_==width && height_==height)) return;
  CreateTarget(std::max(width,1u),std::max(height,1u)); Render();
}

void NativeViewportHost::ApplySnapshot(const flutter::EncodableMap& snapshot, bool replace) {
  const auto start=std::chrono::steady_clock::now(); std::scoped_lock lock(mutex_);
  if (replace) entities_.clear();
  const auto* raw=Find(snapshot,"entities");
  const auto* list=raw ? std::get_if<flutter::EncodableList>(raw) : nullptr;
  if (!list) return;
  for (const auto& value:*list) {
    const auto* map=std::get_if<flutter::EncodableMap>(&value); if(!map) continue;
    const auto* id=std::get_if<std::string>(Find(*map,"id"));
    if (!id) continue;
    if (const auto* removed = Find(*map, "removed");
        removed && std::holds_alternative<bool>(*removed) && std::get<bool>(*removed)) {
      entities_.erase(*id); continue;
    }
    const auto* nodes=std::get_if<flutter::EncodableList>(Find(*map,"nodes"));
    const auto* indices=std::get_if<flutter::EncodableList>(Find(*map,"triangles"));
    if (!nodes || !indices) {
      const auto existing = entities_.find(*id);
      if (existing != entities_.end() && Find(*map, "visible"))
        existing->second.visible = std::get<bool>(*Find(*map, "visible"));
      continue;
    }
    if(nodes->size()<3) continue;
    SceneEntity entity; entity.id=*id;
    entity.visible = Find(*map,"visible") ? std::get<bool>(*Find(*map,"visible")) : true;
    std::vector<XMFLOAT3> positions; positions.reserve(nodes->size()/3);
    for(size_t i=0;i+2<nodes->size();i+=3) positions.push_back({
      static_cast<float>(Number((*nodes)[i])),static_cast<float>(Number((*nodes)[i+1])),
      static_cast<float>(Number((*nodes)[i+2]))});
    entity.vertices.resize(positions.size());
    for(size_t i=0;i<positions.size();++i) entity.vertices[i]={positions[i].x,positions[i].y,positions[i].z,0,0,0};
    entity.indices.reserve(indices->size());
    for(const auto& index:*indices) entity.indices.push_back(static_cast<uint32_t>(Number(index)));
    for(size_t i=0;i+2<entity.indices.size();i+=3){
      const auto ia=entity.indices[i],ib=entity.indices[i+1],ic=entity.indices[i+2];
      if(ia>=positions.size()||ib>=positions.size()||ic>=positions.size())continue;
      XMVECTOR a=XMLoadFloat3(&positions[ia]),b=XMLoadFloat3(&positions[ib]),c=XMLoadFloat3(&positions[ic]);
      XMFLOAT3 n;XMStoreFloat3(&n,XMVector3Normalize(XMVector3Cross(b-a,c-a)));
      for(uint32_t v:{ia,ib,ic}){entity.vertices[v].nx+=n.x;entity.vertices[v].ny+=n.y;entity.vertices[v].nz+=n.z;}
    }
    for(auto& v:entity.vertices){XMFLOAT3 n{v.nx,v.ny,v.nz};XMStoreFloat3(&n,XMVector3Normalize(XMLoadFloat3(&n)));v.nx=n.x;v.ny=n.y;v.nz=n.z;}
    Upload(entity); entities_[*id]=std::move(entity);
  }
  Fit(); upload_ms_=std::chrono::duration<double,std::milli>(std::chrono::steady_clock::now()-start).count();
  Render();
}

void NativeViewportHost::Upload(SceneEntity& entity) {
  if(entity.vertices.empty()||entity.indices.empty())return;
  D3D11_BUFFER_DESC vb{};vb.ByteWidth=static_cast<UINT>(entity.vertices.size()*sizeof(Vertex));
  vb.Usage=D3D11_USAGE_IMMUTABLE;vb.BindFlags=D3D11_BIND_VERTEX_BUFFER;
  D3D11_SUBRESOURCE_DATA vd{entity.vertices.data()};Check(device_->CreateBuffer(&vb,&vd,&entity.vertex_buffer),"mesh VB");
  D3D11_BUFFER_DESC ib{};ib.ByteWidth=static_cast<UINT>(entity.indices.size()*sizeof(uint32_t));
  ib.Usage=D3D11_USAGE_IMMUTABLE;ib.BindFlags=D3D11_BIND_INDEX_BUFFER;
  D3D11_SUBRESOURCE_DATA data{entity.indices.data()};Check(device_->CreateBuffer(&ib,&data,&entity.index_buffer),"mesh IB");
}

void NativeViewportHost::Render() {
  if(!target_view_)return;++render_calls_;const auto start=std::chrono::steady_clock::now();
  const float background[]{.075f,.095f,.115f,1};context_->ClearRenderTargetView(target_view_.Get(),background);
  context_->ClearDepthStencilView(depth_view_.Get(),D3D11_CLEAR_DEPTH,1,0);
  context_->OMSetRenderTargets(1,target_view_.GetAddressOf(),depth_view_.Get());
  D3D11_VIEWPORT vp{0,0,static_cast<float>(width_),static_cast<float>(height_),0,1};context_->RSSetViewports(1,&vp);
  const auto frame = camera_.BuildFrame(static_cast<float>(width_) / height_);
  Constants constants{};
  XMStoreFloat4x4(reinterpret_cast<XMFLOAT4X4*>(constants.matrix),
                  frame.world_view_projection);
  constants.color[0]=.30f;constants.color[1]=.50f;constants.color[2]=.68f;constants.color[3]=1;
  context_->UpdateSubresource(constants_.Get(),0,nullptr,&constants,0,0);++constant_buffer_updates_;UINT stride=sizeof(Vertex),offset=0;
  context_->IASetInputLayout(input_layout_.Get());context_->IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
  context_->VSSetShader(vertex_shader_.Get(),nullptr,0);context_->VSSetConstantBuffers(0,1,constants_.GetAddressOf());context_->PSSetShader(pixel_shader_.Get(),nullptr,0);context_->PSSetConstantBuffers(0,1,constants_.GetAddressOf());
  context_->RSSetState(rasterizer_.Get());context_->OMSetDepthStencilState(depth_state_.Get(),0);triangles_=0;
  for(auto& [id,e]:entities_){if(!e.visible||!e.vertex_buffer||!e.index_buffer)continue;context_->IASetVertexBuffers(0,1,e.vertex_buffer.GetAddressOf(),&stride,&offset);context_->IASetIndexBuffer(e.index_buffer.Get(),DXGI_FORMAT_R32_UINT,0);context_->DrawIndexed(static_cast<UINT>(e.indices.size()),0,0);++draw_indexed_calls_;triangles_+=e.indices.size()/3;}
  context_->Flush();++frames_;const auto now=std::chrono::steady_clock::now();const double elapsed=std::chrono::duration<double>(now-metric_start_).count();if(elapsed>=1){fps_=frames_/elapsed;frames_=0;metric_start_=now;}
  render_ms_=std::chrono::duration<double,std::milli>(now-start).count();
  if(texture_id_>=0){++frame_marks_;if(registrar_->MarkTextureFrameAvailable(texture_id_))++successful_frame_marks_;}
}

void NativeViewportHost::RenderTextureProbe() {
  std::scoped_lock lock(mutex_);
  if (!target_view_) return;
  const Vertex vertices[] = {
      {-0.72f, -0.62f, 0.5f, 0, 0, 1},
      { 0.00f,  0.72f, 0.5f, 0, 0, 1},
      { 0.72f, -0.62f, 0.5f, 0, 0, 1},
  };
  D3D11_BUFFER_DESC description{};
  description.ByteWidth = sizeof(vertices);
  description.Usage = D3D11_USAGE_IMMUTABLE;
  description.BindFlags = D3D11_BIND_VERTEX_BUFFER;
  D3D11_SUBRESOURCE_DATA source{vertices};
  ComPtr<ID3D11Buffer> buffer;
  Check(device_->CreateBuffer(&description, &source, &buffer), "probe VB");
  const float background[]{0.02f, 0.12f, 0.80f, 1};
  context_->ClearRenderTargetView(target_view_.Get(), background);
  context_->ClearDepthStencilView(depth_view_.Get(), D3D11_CLEAR_DEPTH, 1, 0);
  {
    D3D11_TEXTURE2D_DESC clear_description{};
    target_texture_->GetDesc(&clear_description);
    clear_description.Width = 1;
    clear_description.Height = 1;
    clear_description.BindFlags = 0;
    clear_description.MiscFlags = 0;
    clear_description.Usage = D3D11_USAGE_STAGING;
    clear_description.CPUAccessFlags = D3D11_CPU_ACCESS_READ;
    ComPtr<ID3D11Texture2D> clear_sample;
    Check(device_->CreateTexture2D(&clear_description, nullptr, &clear_sample),
          "probe clear sample");
    D3D11_BOX clear_box{width_ / 2, height_ / 2, 0, width_ / 2 + 1,
                        height_ / 2 + 1, 1};
    context_->CopySubresourceRegion(clear_sample.Get(), 0, 0, 0, 0,
                                    target_texture_.Get(), 0, &clear_box);
    D3D11_MAPPED_SUBRESOURCE clear_mapped{};
    Check(context_->Map(clear_sample.Get(), 0, D3D11_MAP_READ, 0,
                        &clear_mapped), "probe clear map");
    sampled_clear_bgra_ =
        *static_cast<const uint32_t*>(clear_mapped.pData);
    context_->Unmap(clear_sample.Get(), 0);
  }
  context_->OMSetRenderTargets(1, target_view_.GetAddressOf(), depth_view_.Get());
  D3D11_VIEWPORT viewport{0, 0, static_cast<float>(width_),
                         static_cast<float>(height_), 0, 1};
  context_->RSSetViewports(1, &viewport);
  constexpr char probe_shader[] = R"(
    struct In { float3 p : POSITION; };
    struct Out { float4 p : SV_POSITION; };
    Out VSProbe(In input) { Out output; output.p=float4(input.p,1); return output; }
    float4 PSProbe(Out input) : SV_TARGET { return float4(1,0,0,1); }
  )";
  ComPtr<ID3DBlob> probe_vs_blob, probe_ps_blob, probe_errors;
  Check(D3DCompile(probe_shader, sizeof(probe_shader), nullptr, nullptr,
                   nullptr, "VSProbe", "vs_5_0", D3DCOMPILE_ENABLE_STRICTNESS,
                   0, &probe_vs_blob, &probe_errors), "probe VS compile");
  Check(D3DCompile(probe_shader, sizeof(probe_shader), nullptr, nullptr,
                   nullptr, "PSProbe", "ps_5_0", D3DCOMPILE_ENABLE_STRICTNESS,
                   0, &probe_ps_blob, &probe_errors), "probe PS compile");
  ComPtr<ID3D11VertexShader> probe_vs;
  ComPtr<ID3D11PixelShader> probe_ps;
  ComPtr<ID3D11InputLayout> probe_layout;
  Check(device_->CreateVertexShader(probe_vs_blob->GetBufferPointer(),
                                    probe_vs_blob->GetBufferSize(), nullptr,
                                    &probe_vs), "probe VS");
  Check(device_->CreatePixelShader(probe_ps_blob->GetBufferPointer(),
                                   probe_ps_blob->GetBufferSize(), nullptr,
                                   &probe_ps), "probe PS");
  const D3D11_INPUT_ELEMENT_DESC probe_element{
      "POSITION", 0, DXGI_FORMAT_R32G32B32_FLOAT, 0, 0,
      D3D11_INPUT_PER_VERTEX_DATA, 0};
  Check(device_->CreateInputLayout(&probe_element, 1,
                                   probe_vs_blob->GetBufferPointer(),
                                   probe_vs_blob->GetBufferSize(),
                                   &probe_layout), "probe input layout");
  UINT stride = sizeof(Vertex), offset = 0;
  context_->IASetInputLayout(probe_layout.Get());
  context_->IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
  context_->IASetVertexBuffers(0, 1, buffer.GetAddressOf(), &stride, &offset);
  context_->VSSetShader(probe_vs.Get(), nullptr, 0);
  context_->PSSetShader(probe_ps.Get(), nullptr, 0);
  context_->RSSetState(rasterizer_.Get());
  context_->OMSetDepthStencilState(depth_state_.Get(), 0);
  context_->Draw(3, 0);
  context_->Flush();

  D3D11_TEXTURE2D_DESC sample_description{};
  target_texture_->GetDesc(&sample_description);
  sample_description.Width = 1;
  sample_description.Height = 1;
  sample_description.BindFlags = 0;
  sample_description.MiscFlags = 0;
  sample_description.Usage = D3D11_USAGE_STAGING;
  sample_description.CPUAccessFlags = D3D11_CPU_ACCESS_READ;
  ComPtr<ID3D11Texture2D> sample;
  Check(device_->CreateTexture2D(&sample_description, nullptr, &sample),
        "probe sample");
  D3D11_BOX box{width_ / 2, height_ / 2, 0, width_ / 2 + 1,
                height_ / 2 + 1, 1};
  context_->CopySubresourceRegion(sample.Get(), 0, 0, 0, 0,
                                  target_texture_.Get(), 0, &box);
  D3D11_MAPPED_SUBRESOURCE mapped{};
  Check(context_->Map(sample.Get(), 0, D3D11_MAP_READ, 0, &mapped),
        "probe map");
  sampled_bgra_ = *static_cast<const uint32_t*>(mapped.pData);
  context_->Unmap(sample.Get(), 0);
  triangles_ = 1;
  if (texture_id_ >= 0) {
    ++frame_marks_;
    if (registrar_->MarkTextureFrameAvailable(texture_id_))
      ++successful_frame_marks_;
  }
}

void NativeViewportHost::Fit(){float mn[3]{INFINITY,INFINITY,INFINITY},mx[3]{-INFINITY,-INFINITY,-INFINITY};for(const auto&[id,e]:entities_)for(const auto&v:e.vertices){mn[0]=std::min(mn[0],v.x);mn[1]=std::min(mn[1],v.y);mn[2]=std::min(mn[2],v.z);mx[0]=std::max(mx[0],v.x);mx[1]=std::max(mx[1],v.y);mx[2]=std::max(mx[2],v.z);}if(!std::isfinite(mn[0]))return;camera_.Fit(mn,mx);++fit_calls_;}
void NativeViewportHost::Orbit(double dx,double dy){std::scoped_lock lock(mutex_);camera_.OrbitRadians(static_cast<float>(dx),static_cast<float>(dy));Render();}
void NativeViewportHost::Pan(double dx,double dy){std::scoped_lock lock(mutex_);camera_.PanPixels(static_cast<float>(dx),static_cast<float>(dy));Render();}
void NativeViewportHost::Zoom(double factor){std::scoped_lock lock(mutex_);camera_.ZoomFactor(static_cast<float>(factor));Render();}
void NativeViewportHost::SetCamera(const flutter::EncodableMap& arguments) {
  std::scoped_lock lock(mutex_);
  ++set_camera_calls_;
  const auto read_vector = [&arguments](const char* key, float output[3]) {
    const auto* raw = Find(arguments, key);
    const auto* values = raw ? std::get_if<flutter::EncodableList>(raw) : nullptr;
    if (!values || values->size() != 3) return false;
    for (size_t i = 0; i < 3; ++i)
      output[i] = static_cast<float>(Number((*values)[i]));
    return true;
  };
  float eye[3], target[3], up[3];
  const auto* fov = Find(arguments, "fov");
  const auto* near_plane = Find(arguments, "near");
  const auto* far_plane = Find(arguments, "far");
  if (!read_vector("eye", eye) || !read_vector("target", target) ||
      !read_vector("up", up) || !fov || !near_plane || !far_plane) return;
  const float fov_value = static_cast<float>(Number(*fov));
  const float near_value = static_cast<float>(Number(*near_plane));
  const float far_value = static_cast<float>(Number(*far_plane));
  if (!std::isfinite(fov_value) || !std::isfinite(near_value) ||
      !std::isfinite(far_value) || fov_value <= 0 ||
      fov_value >= XM_PI || near_value <= 0 || far_value <= near_value) return;
  camera_.SetPose(eye, target, up);
  camera_.SetLens(fov_value, near_value, far_value);
  Render();
}
void NativeViewportHost::RemoveEntity(const std::string&id){std::scoped_lock lock(mutex_);entities_.erase(id);Render();}
flutter::EncodableMap NativeViewportHost::Stats()const{std::string gpu;gpu.reserve(adapter_name_.size());for(const wchar_t character:adapter_name_)gpu.push_back(character<=0x7f?static_cast<char>(character):'?');return{{flutter::EncodableValue("fps"),flutter::EncodableValue(fps_)},{flutter::EncodableValue("drawCalls"),flutter::EncodableValue(static_cast<int64_t>(entities_.size()))},{flutter::EncodableValue("triangles"),flutter::EncodableValue(static_cast<int64_t>(triangles_))},{flutter::EncodableValue("uploadMs"),flutter::EncodableValue(upload_ms_)},{flutter::EncodableValue("renderMs"),flutter::EncodableValue(render_ms_)},{flutter::EncodableValue("pickingMs"),flutter::EncodableValue(picking_ms_)},{flutter::EncodableValue("gpu"),flutter::EncodableValue(gpu)},{flutter::EncodableValue("setCameraCalls"),flutter::EncodableValue(static_cast<int64_t>(set_camera_calls_))},{flutter::EncodableValue("renderCalls"),flutter::EncodableValue(static_cast<int64_t>(render_calls_))},{flutter::EncodableValue("constantBufferUpdates"),flutter::EncodableValue(static_cast<int64_t>(constant_buffer_updates_))},{flutter::EncodableValue("drawIndexedCalls"),flutter::EncodableValue(static_cast<int64_t>(draw_indexed_calls_))},{flutter::EncodableValue("fitCalls"),flutter::EncodableValue(static_cast<int64_t>(fit_calls_))},{flutter::EncodableValue("cameraDistance"),flutter::EncodableValue(static_cast<double>(camera_.Distance()))},{flutter::EncodableValue("cameraRadius"),flutter::EncodableValue(static_cast<double>(camera_.Radius()))},{flutter::EncodableValue("cameraNear"),flutter::EncodableValue(static_cast<double>(camera_.NearPlane()))},{flutter::EncodableValue("cameraFar"),flutter::EncodableValue(static_cast<double>(camera_.FarPlane()))},{flutter::EncodableValue("textureId"),flutter::EncodableValue(texture_id_)},{flutter::EncodableValue("textureRegistered"),flutter::EncodableValue(texture_registered_)},{flutter::EncodableValue("textureCallbacks"),flutter::EncodableValue(static_cast<int64_t>(texture_callbacks_.load()))},{flutter::EncodableValue("textureCallbackHz"),flutter::EncodableValue(texture_callback_hz_)},{flutter::EncodableValue("frameMarks"),flutter::EncodableValue(static_cast<int64_t>(frame_marks_.load()))},{flutter::EncodableValue("successfulFrameMarks"),flutter::EncodableValue(static_cast<int64_t>(successful_frame_marks_.load()))},{flutter::EncodableValue("requestedWidth"),flutter::EncodableValue(static_cast<int64_t>(last_requested_width_))},{flutter::EncodableValue("requestedHeight"),flutter::EncodableValue(static_cast<int64_t>(last_requested_height_))},{flutter::EncodableValue("sampledBgra"),flutter::EncodableValue(static_cast<int64_t>(sampled_bgra_))},{flutter::EncodableValue("sampledClearBgra"),flutter::EncodableValue(static_cast<int64_t>(sampled_clear_bgra_))}};}
const FlutterDesktopGpuSurfaceDescriptor* NativeViewportHost::SurfaceDescriptor(size_t width,size_t height){std::scoped_lock lock(mutex_);++texture_callbacks_;++callback_window_count_;const auto now=std::chrono::steady_clock::now();const double elapsed=std::chrono::duration<double>(now-callback_metric_start_).count();if(elapsed>=1){texture_callback_hz_=callback_window_count_/elapsed;callback_window_count_=0;callback_metric_start_=now;}last_requested_width_=width;last_requested_height_=height;surface_descriptor_.handle=shared_texture_handle_;surface_descriptor_.release_context=target_texture_.Get();if(target_texture_)target_texture_->AddRef();return &surface_descriptor_;}
void NativeViewportHost::Shutdown(){std::scoped_lock lock(mutex_);if(texture_id_>=0&&registrar_){registrar_->UnregisterTexture(texture_id_);texture_id_=-1;}flutter_texture_.reset();entities_.clear();target_view_.Reset();target_texture_.Reset();shared_texture_handle_=nullptr;depth_view_.Reset();depth_texture_.Reset();}
