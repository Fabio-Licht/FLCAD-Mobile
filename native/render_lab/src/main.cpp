#include <windows.h>
#include <windowsx.h>
#include <commdlg.h>
#include <shellapi.h>
#include <d3d11.h>
#include <d3dcompiler.h>
#include <DirectXMath.h>
#include <wrl/client.h>

#include <algorithm>
#include <array>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <limits>
#include <sstream>
#include <stdexcept>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#include "cad_camera_system.h"

using Microsoft::WRL::ComPtr;
using namespace DirectX;

namespace {

constexpr wchar_t kWindowClass[] = L"FLCAD_RENDER_LAB_R2_004";
constexpr wchar_t kWindowTitle[] = L"FLCAD Render Lab - R2-004 GPU Picking";

enum class PickKind : uint32_t {
  none = 0, face = 1, edge = 2, vertex = 3, curve = 4,
  section = 5, sketch = 6, preview = 7,
};

struct PickResult {
  PickKind kind = PickKind::none;
  uint32_t id = 0;
  bool valid() const { return kind != PickKind::none; }
};

const wchar_t* pickKindName(PickKind kind) {
  switch (kind) {
    case PickKind::face: return L"Face";
    case PickKind::edge: return L"Edge";
    case PickKind::vertex: return L"Vertex";
    case PickKind::curve: return L"Curve";
    case PickKind::section: return L"Section";
    case PickKind::sketch: return L"Sketch";
    case PickKind::preview: return L"Preview";
    default: return L"None";
  }
}

struct Vec3 {
  float x = 0, y = 0, z = 0;
};

Vec3 operator+(Vec3 a, Vec3 b) { return {a.x + b.x, a.y + b.y, a.z + b.z}; }
Vec3 operator-(Vec3 a, Vec3 b) { return {a.x - b.x, a.y - b.y, a.z - b.z}; }
Vec3 operator*(Vec3 a, float value) { return {a.x * value, a.y * value, a.z * value}; }
Vec3 operator/(Vec3 a, float value) { return a * (1.0f / value); }
Vec3& operator+=(Vec3& a, Vec3 b) { a = a + b; return a; }
float dot(Vec3 a, Vec3 b) { return a.x * b.x + a.y * b.y + a.z * b.z; }
Vec3 cross(Vec3 a, Vec3 b) {
  return {a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x};
}
float length(Vec3 value) { return std::sqrt(dot(value, value)); }
Vec3 normalized(Vec3 value) {
  const float size = length(value);
  return size > 1e-20f ? value * (1.0f / size) : Vec3{0, 0, 1};
}

struct Vertex {
  Vec3 position;
  Vec3 normal;
};

struct PickVertex {
  Vec3 position;
  uint32_t id;
};

struct TriangleSoup {
  std::vector<Vec3> positions;
  std::vector<Vec3> faceNormals;
};

struct DisplayMesh {
  std::vector<Vertex> vertices;
  std::vector<uint32_t> indices;
  Vec3 minimum{};
  Vec3 maximum{};
  std::vector<PickVertex> edgeVertices;
  std::vector<PickVertex> pointVertices;
};

struct PositionKey {
  int64_t x, y, z;
  bool operator==(const PositionKey&) const = default;
};

struct PositionKeyHash {
  size_t operator()(const PositionKey& value) const noexcept {
    size_t result = std::hash<int64_t>{}(value.x);
    result ^= std::hash<int64_t>{}(value.y) + 0x9e3779b9 + (result << 6) + (result >> 2);
    result ^= std::hash<int64_t>{}(value.z) + 0x9e3779b9 + (result << 6) + (result >> 2);
    return result;
  }
};

uint32_t readU32(std::istream& input) {
  uint32_t value = 0;
  input.read(reinterpret_cast<char*>(&value), sizeof(value));
  return value;
}

float readF32(std::istream& input) {
  float value = 0;
  input.read(reinterpret_cast<char*>(&value), sizeof(value));
  return value;
}

TriangleSoup loadBinaryStl(const std::filesystem::path& path, uint32_t count) {
  std::ifstream input(path, std::ios::binary);
  if (!input) throw std::runtime_error("Cannot open STL");
  input.seekg(84);
  TriangleSoup result;
  result.positions.reserve(static_cast<size_t>(count) * 3);
  result.faceNormals.reserve(count);
  for (uint32_t triangle = 0; triangle < count; ++triangle) {
    result.faceNormals.push_back({readF32(input), readF32(input), readF32(input)});
    for (int corner = 0; corner < 3; ++corner) {
      result.positions.push_back({readF32(input), readF32(input), readF32(input)});
    }
    uint16_t attribute = 0;
    input.read(reinterpret_cast<char*>(&attribute), sizeof(attribute));
    if (!input) throw std::runtime_error("Truncated binary STL");
  }
  return result;
}

TriangleSoup loadAsciiStl(const std::filesystem::path& path) {
  std::ifstream input(path);
  if (!input) throw std::runtime_error("Cannot open STL");
  TriangleSoup result;
  std::string token;
  while (input >> token) {
    if (token == "facet") {
      std::string normalToken;
      Vec3 normal;
      if (!(input >> normalToken >> normal.x >> normal.y >> normal.z) || normalToken != "normal") {
        throw std::runtime_error("Invalid ASCII STL facet normal");
      }
      result.faceNormals.push_back(normal);
    } else if (token == "vertex") {
      Vec3 point;
      if (!(input >> point.x >> point.y >> point.z)) {
        throw std::runtime_error("Invalid ASCII STL vertex");
      }
      result.positions.push_back(point);
    }
  }
  if (result.positions.empty() || result.positions.size() % 3 != 0) {
    throw std::runtime_error("ASCII STL has no complete triangles");
  }
  if (result.faceNormals.size() != result.positions.size() / 3) {
    result.faceNormals.clear();
  }
  return result;
}

TriangleSoup loadStl(const std::filesystem::path& path) {
  const auto fileSize = std::filesystem::file_size(path);
  if (fileSize >= 84) {
    std::ifstream input(path, std::ios::binary);
    std::array<char, 80> header{};
    input.read(header.data(), static_cast<std::streamsize>(header.size()));
    const uint32_t count = readU32(input);
    const uint64_t expected = 84ull + static_cast<uint64_t>(count) * 50ull;
    if (expected == fileSize) return loadBinaryStl(path, count);
  }
  return loadAsciiStl(path);
}

DisplayMesh buildDisplayMesh(const TriangleSoup& soup, bool benchmarkOneMillion) {
  if (soup.positions.empty()) throw std::runtime_error("STL is empty");
  Vec3 minimum = soup.positions.front();
  Vec3 maximum = minimum;
  for (const Vec3 point : soup.positions) {
    minimum.x = std::min(minimum.x, point.x); minimum.y = std::min(minimum.y, point.y); minimum.z = std::min(minimum.z, point.z);
    maximum.x = std::max(maximum.x, point.x); maximum.y = std::max(maximum.y, point.y); maximum.z = std::max(maximum.z, point.z);
  }
  const float diagonal = std::max(length(maximum - minimum), 1e-6f);
  const double tolerance = std::max(static_cast<double>(diagonal) * 1e-7, 1e-9);
  std::unordered_map<PositionKey, uint32_t, PositionKeyHash> welded;
  std::vector<uint32_t> cornerGroups;
  std::vector<Vec3> groupPositions;
  cornerGroups.reserve(soup.positions.size());
  for (const Vec3 point : soup.positions) {
    const PositionKey key{
      static_cast<int64_t>(std::llround(point.x / tolerance)),
      static_cast<int64_t>(std::llround(point.y / tolerance)),
      static_cast<int64_t>(std::llround(point.z / tolerance))};
    auto [iterator, inserted] = welded.emplace(key, static_cast<uint32_t>(groupPositions.size()));
    if (inserted) groupPositions.push_back(point);
    cornerGroups.push_back(iterator->second);
  }

  struct FaceData {
    Vec3 normal;
    float doubleArea = 0;
    std::array<float, 3> cornerAngles{};
  };
  const size_t faceCount = soup.positions.size() / 3;
  std::vector<FaceData> faces(faceCount);
  std::vector<std::vector<uint32_t>> incident(groupPositions.size());
  const auto cornerAngle = [](Vec3 first, Vec3 second) {
    const float denominator = length(first) * length(second);
    if (denominator <= 1e-20f) return 0.0f;
    return std::acos(std::clamp(dot(first, second) / denominator, -1.0f, 1.0f));
  };
  for (size_t face = 0; face < faceCount; ++face) {
    const size_t offset = face * 3;
    const Vec3 a = soup.positions[offset];
    const Vec3 b = soup.positions[offset + 1];
    const Vec3 c = soup.positions[offset + 2];
    const Vec3 ab = b - a;
    const Vec3 ac = c - a;
    Vec3 faceVector = cross(ab, ac);
    if (face < soup.faceNormals.size() && dot(faceVector, soup.faceNormals[face]) < 0) {
      faceVector = faceVector * -1.0f;
    }
    faces[face].doubleArea = length(faceVector);
    faces[face].normal = normalized(faceVector);
    faces[face].cornerAngles = {
      cornerAngle(ab, ac),
      cornerAngle(a - b, c - b),
      cornerAngle(a - c, b - c)};
    for (size_t corner = 0; corner < 3; ++corner) {
      incident[cornerGroups[offset + corner]].push_back(static_cast<uint32_t>(face));
    }
  }

  // One normal per triangle corner is required: a welded vertex may be smooth
  // inside one continuous patch and discontinuous across a CAD crease.
  constexpr float creaseCosine = 0.6156614753f;
  DisplayMesh mesh;
  mesh.minimum = minimum;
  mesh.maximum = maximum;
  mesh.vertices.reserve(soup.positions.size());
  mesh.indices.reserve(soup.positions.size());
  for (size_t face = 0; face < faceCount; ++face) {
    const size_t offset = face * 3;
    const Vec3 reference = faces[face].normal;
    for (size_t corner = 0; corner < 3; ++corner) {
      const uint32_t group = cornerGroups[offset + corner];
      Vec3 accumulated{};
      float totalWeight = 0;
      for (const uint32_t neighbor : incident[group]) {
        const float alignment = dot(reference, faces[neighbor].normal);
        if (alignment < creaseCosine || faces[neighbor].doubleArea <= 1e-20f) continue;
        const size_t neighborOffset = static_cast<size_t>(neighbor) * 3;
        size_t neighborCorner = 0;
        if (cornerGroups[neighborOffset + 1] == group) neighborCorner = 1;
        else if (cornerGroups[neighborOffset + 2] == group) neighborCorner = 2;
        const float angularWeight = faces[neighbor].cornerAngles[neighborCorner];
        const float areaWeight = std::sqrt(faces[neighbor].doubleArea);
        const float continuity = std::clamp(
            (alignment - creaseCosine) / (1.0f - creaseCosine), 0.0f, 1.0f);
        // The robust continuity term suppresses isolated scan triangles while
        // avoiding a blur across a real change of curvature.
        const float weight = angularWeight * areaWeight * (0.30f + 0.70f * continuity * continuity);
        accumulated += faces[neighbor].normal * weight;
        totalWeight += weight;
      }
      const Vec3 normal = totalWeight > 1e-20f ? normalized(accumulated / totalWeight) : reference;
      mesh.vertices.push_back({soup.positions[offset + corner], normal});
      mesh.indices.push_back(static_cast<uint32_t>(mesh.indices.size()));
    }
  }
  mesh.pointVertices.reserve(groupPositions.size());
  for (size_t point = 0; point < groupPositions.size(); ++point) {
    mesh.pointVertices.push_back({groupPositions[point], static_cast<uint32_t>(point + 1)});
  }
  std::unordered_map<uint64_t, uint32_t> uniqueEdges;
  for (size_t face = 0; face < faceCount; ++face) {
    const size_t offset = face * 3;
    for (size_t edge = 0; edge < 3; ++edge) {
      uint32_t first = cornerGroups[offset + edge];
      uint32_t second = cornerGroups[offset + ((edge + 1) % 3)];
      if (first > second) std::swap(first, second);
      const uint64_t key = (static_cast<uint64_t>(first) << 32) | second;
      if (uniqueEdges.contains(key)) continue;
      const uint32_t id = static_cast<uint32_t>(uniqueEdges.size() + 1);
      uniqueEdges.emplace(key, id);
      mesh.edgeVertices.push_back({groupPositions[first], id});
      mesh.edgeVertices.push_back({groupPositions[second], id});
    }
  }
  if (benchmarkOneMillion && !mesh.indices.empty()) {
    const size_t target = 1'000'000ull * 3ull;
    const std::vector<uint32_t> original = mesh.indices;
    mesh.indices.reserve(target);
    while (mesh.indices.size() < target) {
      const size_t remaining = target - mesh.indices.size();
      mesh.indices.insert(mesh.indices.end(), original.begin(),
                          original.begin() + static_cast<ptrdiff_t>(std::min(remaining, original.size())));
    }
    mesh.indices.resize(target);
  }
  return mesh;
}

std::wstring openStlDialog(HWND owner) {
  std::array<wchar_t, 32768> buffer{};
  OPENFILENAMEW dialog{};
  dialog.lStructSize = sizeof(dialog);
  dialog.hwndOwner = owner;
  dialog.lpstrFilter = L"STL mesh (*.stl)\0*.stl\0All files (*.*)\0*.*\0";
  dialog.lpstrFile = buffer.data();
  dialog.nMaxFile = static_cast<DWORD>(buffer.size());
  dialog.Flags = OFN_FILEMUSTEXIST | OFN_PATHMUSTEXIST;
  return GetOpenFileNameW(&dialog) ? std::wstring(buffer.data()) : std::wstring{};
}

std::string messageFor(HRESULT result) {
  char* buffer = nullptr;
  FormatMessageA(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM |
                     FORMAT_MESSAGE_IGNORE_INSERTS,
                 nullptr, static_cast<DWORD>(result), 0,
                 reinterpret_cast<char*>(&buffer), 0, nullptr);
  std::string text = buffer ? buffer : "Unknown HRESULT";
  if (buffer) LocalFree(buffer);
  return text;
}

void check(HRESULT result, const char* operation) {
  if (FAILED(result)) {
    std::ostringstream text;
    text << operation << " failed (0x" << std::hex << static_cast<uint32_t>(result)
         << "): " << messageFor(result);
    throw std::runtime_error(text.str());
  }
}

const char* kShaderSource = R"(
cbuffer Scene : register(b0) {
  row_major float4x4 worldViewProjection;
  row_major float4x4 worldView;
  float4 materialColor;
  float4 materialControls;
  uint4 selectionIds;
};
struct VSInput { float3 position : POSITION; float3 normal : NORMAL; };
struct PSInput { float4 position : SV_POSITION; float3 viewPosition : TEXCOORD0; float3 viewNormal : TEXCOORD1; };
PSInput VSMain(VSInput input) {
  PSInput output;
  output.position = mul(float4(input.position, 1.0), worldViewProjection);
  output.viewPosition = mul(float4(input.position, 1.0), worldView).xyz;
  output.viewNormal = normalize(mul(input.normal, (float3x3)worldView));
  return output;
}
float3 linearToSrgb(float3 value) {
  value = max(value, 0.0);
  return lerp(value * 12.92, 1.055 * pow(value, 1.0 / 2.4) - 0.055,
              step(0.0031308, value));
}
float4 PSMain(PSInput input, uint primitiveId : SV_PrimitiveID) : SV_TARGET {
  float3 n = normalize(input.viewNormal);
  float3 v = normalize(-input.viewPosition);
  if (dot(n, v) < 0.0) n = -n;
  // Camera-relative studio lights keep the reading stable throughout Orbit,
  // Pan and Zoom. They explain inclination without creating a presentation
  // highlight or pretending to be a physical environment.
  const float3 key = normalize(float3(-0.38, 0.52, -0.76));
  const float3 fill = normalize(float3(0.62, 0.18, -0.58));
  const float3 top = normalize(float3(0.05, 0.92, -0.38));
  float keyDiffuse = smoothstep(-0.12, 0.92, dot(n, key));
  float fillDiffuse = smoothstep(-0.20, 0.95, dot(n, fill));
  float topDiffuse = smoothstep(-0.25, 0.95, dot(n, top));
  float facing = saturate(dot(n, v));
  float diffuse = 0.12 + keyDiffuse * 0.55 + fillDiffuse * 0.14 + topDiffuse * 0.06;
  diffuse *= lerp(0.85, 1.04, facing);

  // A broad, low-energy response follows cylinders and fillets. The upper
  // clamp prevents a highlight from erasing scan detail.
  float3 halfVector = normalize(key + v);
  float specularBand = pow(saturate(dot(n, halfVector)), materialControls.y);
  float specular = min(specularBand * materialControls.x, materialControls.z);
  float grazing = pow(1.0 - facing, 3.0) * 0.018;
  float3 linearColor = materialColor.rgb * diffuse + specular + grazing;
  float3 result = saturate(linearToSrgb(linearColor));
  uint faceId = primitiveId + 1;
  if (selectionIds.x == 1 && selectionIds.y == faceId)
    result = lerp(result, float3(1.0, 0.48, 0.04), 0.72);
  else if (selectionIds.z == 1 && selectionIds.w == faceId)
    result = lerp(result, float3(0.20, 0.92, 1.0), 0.48);
  return float4(result, 1.0);
})";

const char* kPickShaderSource = R"(
cbuffer Scene : register(b0) {
  row_major float4x4 worldViewProjection;
  row_major float4x4 worldView;
  float4 materialColor;
  float4 materialControls;
  uint4 selectionIds;
};
struct MeshInput { float3 position : POSITION; float3 normal : NORMAL; };
struct PickInput { float3 position : POSITION; uint id : PICKID; };
struct PickOutput { float4 position : SV_POSITION; nointerpolation uint id : PICKID; };
PickOutput VSFace(MeshInput input) {
  PickOutput output; output.position = mul(float4(input.position, 1), worldViewProjection);
  output.id = 0; return output;
}
PickOutput VSSubentity(PickInput input) {
  PickOutput output; output.position = mul(float4(input.position, 1), worldViewProjection);
  output.id = input.id; return output;
}
uint2 PSFace(PickOutput input, uint primitiveId : SV_PrimitiveID) : SV_TARGET {
  return uint2(1, primitiveId + 1);
}
uint2 PSEdge(PickOutput input) : SV_TARGET { return uint2(2, input.id); }
uint2 PSVertex(PickOutput input) : SV_TARGET { return uint2(3, input.id); }
)";

struct SceneConstants {
  XMFLOAT4X4 worldViewProjection;
  XMFLOAT4X4 worldView;
  XMFLOAT4 materialColor;
  XMFLOAT4 materialControls;
  XMUINT4 selectionIds;
};

class RenderLab {
 public:
  explicit RenderLab(HWND window) : window_(window) {}

  void initialize(const std::filesystem::path& stlPath, bool benchmarkOneMillion) {
    createDevice();
    createPipeline();
    loadMesh(stlPath, benchmarkOneMillion);
    resize();
    fit();
    lastMetric_ = std::chrono::steady_clock::now();
  }

  void resize() {
    RECT area{};
    GetClientRect(window_, &area);
    width_ = std::max<LONG>(area.right - area.left, 1);
    height_ = std::max<LONG>(area.bottom - area.top, 1);
    if (!swapChain_) return;
    context_->OMSetRenderTargets(0, nullptr, nullptr);
    renderTarget_.Reset(); depthView_.Reset(); depthTexture_.Reset();
    pickTarget_.Reset(); pickTexture_.Reset(); pickReadback_.Reset();
    check(swapChain_->ResizeBuffers(0, static_cast<UINT>(width_), static_cast<UINT>(height_),
                                    DXGI_FORMAT_UNKNOWN, 0), "ResizeBuffers");
    createTargets();
  }

  void render() {
    if (!renderTarget_ || !indexBuffer_) return;
    const float background[4] = {0.075f, 0.095f, 0.115f, 1.0f};
    context_->ClearRenderTargetView(renderTarget_.Get(), background);
    context_->ClearDepthStencilView(depthView_.Get(), D3D11_CLEAR_DEPTH, 1.0f, 0);
    context_->OMSetRenderTargets(1, renderTarget_.GetAddressOf(), depthView_.Get());
    D3D11_VIEWPORT viewport{0, 0, static_cast<float>(width_), static_cast<float>(height_), 0, 1};
    context_->RSSetViewports(1, &viewport);

    const auto frame = camera_.BuildFrame(
        static_cast<float>(width_) / static_cast<float>(height_));
    SceneConstants constants{};
    XMStoreFloat4x4(&constants.worldViewProjection,
                    frame.world_view_projection);
    XMStoreFloat4x4(&constants.worldView, frame.world * frame.view);
    constants.materialColor = {0.30f, 0.50f, 0.68f, 1.0f};
    constants.materialControls = {0.070f, 28.0f, 0.080f, 0.0f};
    constants.selectionIds = {
      selected_.kind == PickKind::face ? 1u : 0u, selected_.id,
      hover_.kind == PickKind::face ? 1u : 0u, hover_.id};
    context_->UpdateSubresource(constants_.Get(), 0, nullptr, &constants, 0, 0);

    const UINT stride = sizeof(Vertex), offsetBytes = 0;
    context_->IASetVertexBuffers(0, 1, vertexBuffer_.GetAddressOf(), &stride, &offsetBytes);
    context_->IASetIndexBuffer(indexBuffer_.Get(), DXGI_FORMAT_R32_UINT, 0);
    context_->IASetInputLayout(inputLayout_.Get());
    context_->IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
    context_->VSSetShader(vertexShader_.Get(), nullptr, 0);
    context_->VSSetConstantBuffers(0, 1, constants_.GetAddressOf());
    context_->PSSetShader(pixelShader_.Get(), nullptr, 0);
    context_->PSSetConstantBuffers(0, 1, constants_.GetAddressOf());
    context_->RSSetState(rasterizer_.Get());
    context_->OMSetDepthStencilState(depthState_.Get(), 0);
    context_->DrawIndexed(indexCount_, 0, 0);
    check(swapChain_->Present(0, 0), "Present");
    updateMetrics();
  }

  void beginDrag(int x, int y, bool pan) {
    dragging_ = true; panning_ = pan; dragMoved_ = false;
    previous_ = {x, y}; dragStart_ = previous_; SetCapture(window_);
  }
  void endDrag(int x, int y, bool selectionButton) {
    const bool click = selectionButton && !dragMoved_ &&
        std::abs(x - dragStart_.x) <= 3 && std::abs(y - dragStart_.y) <= 3;
    dragging_ = false; ReleaseCapture();
    if (click) selected_ = pick(x, y);
  }
  void drag(int x, int y) {
    if (!dragging_) return;
    const int dx = x - previous_.x, dy = y - previous_.y;
    if (std::abs(x - dragStart_.x) > 3 || std::abs(y - dragStart_.y) > 3) dragMoved_ = true;
    previous_ = {x, y};
    if (panning_) {
      camera_.PanPixels(static_cast<float>(dx), static_cast<float>(dy));
    } else {
      camera_.OrbitPixels(static_cast<float>(dx), static_cast<float>(dy));
    }
  }
  void zoom(short wheelDelta) {
    camera_.ZoomWheel(wheelDelta, WHEEL_DELTA);
  }
  void fit() {
    const float minimum[]{minimum_.x, minimum_.y, minimum_.z};
    const float maximum[]{maximum_.x, maximum_.y, maximum_.z};
    camera_.Fit(minimum, maximum);
  }
  uint64_t triangleCount() const { return indexCount_ / 3; }
  void hoverAt(int x, int y) { if (!dragging_) hover_ = pick(x, y); }
  void setPickMode(PickKind mode) { pickMode_ = mode; hover_ = {}; }

 private:
  SceneConstants sceneConstants() const {
    const auto frame = camera_.BuildFrame(
        static_cast<float>(width_) / static_cast<float>(height_));
    SceneConstants constants{};
    XMStoreFloat4x4(&constants.worldViewProjection,
                    frame.world_view_projection);
    XMStoreFloat4x4(&constants.worldView, frame.world * frame.view);
    return constants;
  }

  PickResult pick(int x, int y) {
    if (!pickTarget_ || x < 0 || y < 0 || x >= width_ || y >= height_) return {};
    const float clear[4]{};
    context_->ClearRenderTargetView(pickTarget_.Get(), clear);
    context_->ClearDepthStencilView(depthView_.Get(), D3D11_CLEAR_DEPTH, 1.0f, 0);
    context_->OMSetRenderTargets(1, pickTarget_.GetAddressOf(), depthView_.Get());
    D3D11_VIEWPORT viewport{0, 0, static_cast<float>(width_), static_cast<float>(height_), 0, 1};
    context_->RSSetViewports(1, &viewport);
    SceneConstants constants = sceneConstants();
    context_->UpdateSubresource(constants_.Get(), 0, nullptr, &constants, 0, 0);
    context_->VSSetConstantBuffers(0, 1, constants_.GetAddressOf());
    context_->RSSetState(rasterizer_.Get());
    context_->OMSetDepthStencilState(depthState_.Get(), 0);

    UINT stride = sizeof(Vertex), offset = 0;
    context_->IASetVertexBuffers(0, 1, vertexBuffer_.GetAddressOf(), &stride, &offset);
    context_->IASetIndexBuffer(indexBuffer_.Get(), DXGI_FORMAT_R32_UINT, 0);
    context_->IASetInputLayout(inputLayout_.Get());
    context_->IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
    context_->VSSetShader(pickFaceVertexShader_.Get(), nullptr, 0);
    context_->PSSetShader(pickFacePixelShader_.Get(), nullptr, 0);
    context_->DrawIndexed(indexCount_, 0, 0);

    context_->OMSetDepthStencilState(pickOverlayDepthState_.Get(), 0);
    context_->IASetIndexBuffer(nullptr, DXGI_FORMAT_UNKNOWN, 0);
    context_->IASetInputLayout(pickInputLayout_.Get());
    context_->VSSetShader(pickSubentityVertexShader_.Get(), nullptr, 0);
    stride = sizeof(PickVertex);
    if (edgeBuffer_) {
      context_->IASetVertexBuffers(0, 1, edgeBuffer_.GetAddressOf(), &stride, &offset);
      context_->IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_LINELIST);
      context_->PSSetShader(pickEdgePixelShader_.Get(), nullptr, 0);
      context_->Draw(edgeVertexCount_, 0);
    }
    if (pointBuffer_) {
      context_->IASetVertexBuffers(0, 1, pointBuffer_.GetAddressOf(), &stride, &offset);
      context_->IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_POINTLIST);
      context_->PSSetShader(pickVertexPixelShader_.Get(), nullptr, 0);
      context_->Draw(pointVertexCount_, 0);
    }

    context_->CopyResource(pickReadback_.Get(), pickTexture_.Get());
    D3D11_MAPPED_SUBRESOURCE mapped{};
    check(context_->Map(pickReadback_.Get(), 0, D3D11_MAP_READ, 0, &mapped), "Map ID buffer");
    PickResult best{};
    int bestPriority = -1;
    int bestDistance = std::numeric_limits<int>::max();
    constexpr int tolerance = 5;
    for (int dy = -tolerance; dy <= tolerance; ++dy) {
      const int sampleY = y + dy;
      if (sampleY < 0 || sampleY >= height_) continue;
      const auto* row = reinterpret_cast<const uint32_t*>(
          static_cast<const uint8_t*>(mapped.pData) + static_cast<size_t>(sampleY) * mapped.RowPitch);
      for (int dx = -tolerance; dx <= tolerance; ++dx) {
        const int sampleX = x + dx;
        if (sampleX < 0 || sampleX >= width_) continue;
        const uint32_t kind = row[sampleX * 2];
        const uint32_t id = row[sampleX * 2 + 1];
        if (kind == 0 || id == 0 || kind != static_cast<uint32_t>(pickMode_)) continue;
        const int priority = 1;
        const int distance = dx * dx + dy * dy;
        if (priority > bestPriority || (priority == bestPriority && distance < bestDistance)) {
          best = {static_cast<PickKind>(kind), id};
          bestPriority = priority; bestDistance = distance;
        }
      }
    }
    context_->Unmap(pickReadback_.Get(), 0);
    return best;
  }

  void createDevice() {
    RECT area{}; GetClientRect(window_, &area);
    DXGI_SWAP_CHAIN_DESC descriptor{};
    descriptor.BufferDesc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
    descriptor.SampleDesc.Count = 1;
    descriptor.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
    descriptor.BufferCount = 2;
    descriptor.OutputWindow = window_;
    descriptor.Windowed = TRUE;
    descriptor.SwapEffect = DXGI_SWAP_EFFECT_DISCARD;
    UINT flags = 0;
#ifdef _DEBUG
    flags |= D3D11_CREATE_DEVICE_DEBUG;
#endif
    D3D_FEATURE_LEVEL obtained{};
    check(D3D11CreateDeviceAndSwapChain(nullptr, D3D_DRIVER_TYPE_HARDWARE, nullptr, flags,
        nullptr, 0, D3D11_SDK_VERSION, &descriptor, &swapChain_, &device_, &obtained, &context_),
        "D3D11CreateDeviceAndSwapChain");
    if (obtained < D3D_FEATURE_LEVEL_11_0) throw std::runtime_error("D3D feature level 11_0 required");
    ComPtr<IDXGIDevice> dxgiDevice;
    ComPtr<IDXGIAdapter> adapter;
    DXGI_ADAPTER_DESC adapterDescription{};
    check(device_.As(&dxgiDevice), "Query IDXGIDevice");
    check(dxgiDevice->GetAdapter(&adapter), "Get D3D11 adapter");
    check(adapter->GetDesc(&adapterDescription), "Get adapter description");
    adapterName_ = adapterDescription.Description;
  }

  ComPtr<ID3DBlob> compile(const char* source, const char* entry, const char* profile) {
    ComPtr<ID3DBlob> code, errors;
    const HRESULT result = D3DCompile(source, std::strlen(source), "Render Lab embedded shader",
        nullptr, nullptr, entry, profile, D3DCOMPILE_ENABLE_STRICTNESS, 0, &code, &errors);
    if (FAILED(result)) {
      const std::string detail = errors ? std::string(static_cast<const char*>(errors->GetBufferPointer()), errors->GetBufferSize()) : messageFor(result);
      throw std::runtime_error("Shader compilation failed: " + detail);
    }
    return code;
  }

  void createPipeline() {
    const auto vs = compile(kShaderSource, "VSMain", "vs_5_0");
    const auto ps = compile(kShaderSource, "PSMain", "ps_5_0");
    check(device_->CreateVertexShader(vs->GetBufferPointer(), vs->GetBufferSize(), nullptr, &vertexShader_), "CreateVertexShader");
    check(device_->CreatePixelShader(ps->GetBufferPointer(), ps->GetBufferSize(), nullptr, &pixelShader_), "CreatePixelShader");
    const D3D11_INPUT_ELEMENT_DESC elements[] = {
      {"POSITION", 0, DXGI_FORMAT_R32G32B32_FLOAT, 0, offsetof(Vertex, position), D3D11_INPUT_PER_VERTEX_DATA, 0},
      {"NORMAL", 0, DXGI_FORMAT_R32G32B32_FLOAT, 0, offsetof(Vertex, normal), D3D11_INPUT_PER_VERTEX_DATA, 0}};
    check(device_->CreateInputLayout(elements, 2, vs->GetBufferPointer(), vs->GetBufferSize(), &inputLayout_), "CreateInputLayout");
    D3D11_BUFFER_DESC constantDesc{}; constantDesc.ByteWidth = sizeof(SceneConstants); constantDesc.Usage = D3D11_USAGE_DEFAULT; constantDesc.BindFlags = D3D11_BIND_CONSTANT_BUFFER;
    check(device_->CreateBuffer(&constantDesc, nullptr, &constants_), "Create constant buffer");
    D3D11_RASTERIZER_DESC raster{}; raster.FillMode = D3D11_FILL_SOLID; raster.CullMode = D3D11_CULL_NONE; raster.DepthClipEnable = TRUE;
    check(device_->CreateRasterizerState(&raster, &rasterizer_), "CreateRasterizerState");
    D3D11_DEPTH_STENCIL_DESC depth{}; depth.DepthEnable = TRUE; depth.DepthWriteMask = D3D11_DEPTH_WRITE_MASK_ALL; depth.DepthFunc = D3D11_COMPARISON_LESS;
    check(device_->CreateDepthStencilState(&depth, &depthState_), "CreateDepthStencilState");
    depth.DepthWriteMask = D3D11_DEPTH_WRITE_MASK_ZERO;
    depth.DepthFunc = D3D11_COMPARISON_LESS_EQUAL;
    check(device_->CreateDepthStencilState(&depth, &pickOverlayDepthState_), "Create pick overlay depth state");

    const auto pickFaceVs = compile(kPickShaderSource, "VSFace", "vs_5_0");
    const auto pickSubVs = compile(kPickShaderSource, "VSSubentity", "vs_5_0");
    const auto pickFacePs = compile(kPickShaderSource, "PSFace", "ps_5_0");
    const auto pickEdgePs = compile(kPickShaderSource, "PSEdge", "ps_5_0");
    const auto pickVertexPs = compile(kPickShaderSource, "PSVertex", "ps_5_0");
    check(device_->CreateVertexShader(pickFaceVs->GetBufferPointer(), pickFaceVs->GetBufferSize(), nullptr, &pickFaceVertexShader_), "Create face-pick VS");
    check(device_->CreateVertexShader(pickSubVs->GetBufferPointer(), pickSubVs->GetBufferSize(), nullptr, &pickSubentityVertexShader_), "Create subentity-pick VS");
    check(device_->CreatePixelShader(pickFacePs->GetBufferPointer(), pickFacePs->GetBufferSize(), nullptr, &pickFacePixelShader_), "Create face-pick PS");
    check(device_->CreatePixelShader(pickEdgePs->GetBufferPointer(), pickEdgePs->GetBufferSize(), nullptr, &pickEdgePixelShader_), "Create edge-pick PS");
    check(device_->CreatePixelShader(pickVertexPs->GetBufferPointer(), pickVertexPs->GetBufferSize(), nullptr, &pickVertexPixelShader_), "Create vertex-pick PS");
    const D3D11_INPUT_ELEMENT_DESC pickElements[] = {
      {"POSITION", 0, DXGI_FORMAT_R32G32B32_FLOAT, 0, offsetof(PickVertex, position), D3D11_INPUT_PER_VERTEX_DATA, 0},
      {"PICKID", 0, DXGI_FORMAT_R32_UINT, 0, offsetof(PickVertex, id), D3D11_INPUT_PER_VERTEX_DATA, 0}};
    check(device_->CreateInputLayout(pickElements, 2, pickSubVs->GetBufferPointer(), pickSubVs->GetBufferSize(), &pickInputLayout_), "Create pick input layout");
  }

  void createTargets() {
    ComPtr<ID3D11Texture2D> backBuffer;
    check(swapChain_->GetBuffer(0, IID_PPV_ARGS(&backBuffer)), "Get swap-chain buffer");
    check(device_->CreateRenderTargetView(backBuffer.Get(), nullptr, &renderTarget_), "CreateRenderTargetView");
    D3D11_TEXTURE2D_DESC depth{}; depth.Width = static_cast<UINT>(width_); depth.Height = static_cast<UINT>(height_); depth.MipLevels = 1; depth.ArraySize = 1; depth.Format = DXGI_FORMAT_D32_FLOAT; depth.SampleDesc.Count = 1; depth.BindFlags = D3D11_BIND_DEPTH_STENCIL;
    check(device_->CreateTexture2D(&depth, nullptr, &depthTexture_), "Create depth texture");
    check(device_->CreateDepthStencilView(depthTexture_.Get(), nullptr, &depthView_), "CreateDepthStencilView");
    D3D11_TEXTURE2D_DESC pick{};
    pick.Width = static_cast<UINT>(width_); pick.Height = static_cast<UINT>(height_);
    pick.MipLevels = 1; pick.ArraySize = 1; pick.Format = DXGI_FORMAT_R32G32_UINT;
    pick.SampleDesc.Count = 1; pick.BindFlags = D3D11_BIND_RENDER_TARGET;
    check(device_->CreateTexture2D(&pick, nullptr, &pickTexture_), "Create ID texture");
    check(device_->CreateRenderTargetView(pickTexture_.Get(), nullptr, &pickTarget_), "Create ID target");
    pick.BindFlags = 0; pick.Usage = D3D11_USAGE_STAGING; pick.CPUAccessFlags = D3D11_CPU_ACCESS_READ;
    check(device_->CreateTexture2D(&pick, nullptr, &pickReadback_), "Create ID readback");
  }

  void loadMesh(const std::filesystem::path& path, bool benchmarkOneMillion) {
    const DisplayMesh mesh = buildDisplayMesh(loadStl(path), benchmarkOneMillion);
    minimum_ = mesh.minimum; maximum_ = mesh.maximum;
    if (mesh.vertices.size() > std::numeric_limits<UINT>::max() / sizeof(Vertex) ||
        mesh.indices.size() > std::numeric_limits<UINT>::max() / sizeof(uint32_t)) {
      throw std::runtime_error("Mesh exceeds prototype buffer limit");
    }
    D3D11_BUFFER_DESC vertices{}; vertices.ByteWidth = static_cast<UINT>(mesh.vertices.size() * sizeof(Vertex)); vertices.Usage = D3D11_USAGE_IMMUTABLE; vertices.BindFlags = D3D11_BIND_VERTEX_BUFFER;
    D3D11_SUBRESOURCE_DATA vertexData{mesh.vertices.data()};
    check(device_->CreateBuffer(&vertices, &vertexData, &vertexBuffer_), "Create vertex buffer");
    D3D11_BUFFER_DESC indices{}; indices.ByteWidth = static_cast<UINT>(mesh.indices.size() * sizeof(uint32_t)); indices.Usage = D3D11_USAGE_IMMUTABLE; indices.BindFlags = D3D11_BIND_INDEX_BUFFER;
    D3D11_SUBRESOURCE_DATA indexData{mesh.indices.data()};
    check(device_->CreateBuffer(&indices, &indexData, &indexBuffer_), "Create index buffer");
    indexCount_ = static_cast<UINT>(mesh.indices.size());
    const auto createPickBuffer = [&](const std::vector<PickVertex>& data,
                                      ComPtr<ID3D11Buffer>& destination, UINT& count,
                                      const char* operation) {
      count = static_cast<UINT>(data.size());
      if (data.empty()) return;
      D3D11_BUFFER_DESC descriptor{};
      descriptor.ByteWidth = static_cast<UINT>(data.size() * sizeof(PickVertex));
      descriptor.Usage = D3D11_USAGE_IMMUTABLE;
      descriptor.BindFlags = D3D11_BIND_VERTEX_BUFFER;
      D3D11_SUBRESOURCE_DATA initial{data.data()};
      check(device_->CreateBuffer(&descriptor, &initial, &destination), operation);
    };
    createPickBuffer(mesh.edgeVertices, edgeBuffer_, edgeVertexCount_, "Create edge-pick buffer");
    createPickBuffer(mesh.pointVertices, pointBuffer_, pointVertexCount_, "Create vertex-pick buffer");
  }

  Vec3 eyePosition() const {
    XMFLOAT3 eye;
    XMStoreFloat3(&eye, camera_.Eye());
    return {eye.x, eye.y, eye.z};
  }

  void updateMetrics() {
    ++frames_;
    const auto now = std::chrono::steady_clock::now();
    const double elapsed = std::chrono::duration<double>(now - lastMetric_).count();
    if (elapsed < 1.0) return;
    fps_ = static_cast<double>(frames_) / elapsed;
    std::wostringstream title;
    title << kWindowTitle << L" | " << triangleCount() << L" triangles | "
          << std::fixed << std::setprecision(1) << fps_ << L" FPS | " << adapterName_
          << L" | Hover " << pickKindName(hover_.kind) << L" " << hover_.id
          << L" | Selected " << pickKindName(selected_.kind) << L" " << selected_.id
          << L" | Filter " << pickKindName(pickMode_)
          << L" [1 Face 2 Edge 3 Vertex] | Click Select / Drag Orbit  MMB Pan  Wheel Zoom  F Fit";
    SetWindowTextW(window_, title.str().c_str());
    frames_ = 0; lastMetric_ = now;
  }

  HWND window_{};
  LONG width_ = 1, height_ = 1;
  ComPtr<ID3D11Device> device_;
  ComPtr<ID3D11DeviceContext> context_;
  ComPtr<IDXGISwapChain> swapChain_;
  ComPtr<ID3D11RenderTargetView> renderTarget_;
  ComPtr<ID3D11Texture2D> pickTexture_, pickReadback_;
  ComPtr<ID3D11RenderTargetView> pickTarget_;
  ComPtr<ID3D11Texture2D> depthTexture_;
  ComPtr<ID3D11DepthStencilView> depthView_;
  ComPtr<ID3D11VertexShader> vertexShader_;
  ComPtr<ID3D11PixelShader> pixelShader_;
  ComPtr<ID3D11VertexShader> pickFaceVertexShader_, pickSubentityVertexShader_;
  ComPtr<ID3D11PixelShader> pickFacePixelShader_, pickEdgePixelShader_, pickVertexPixelShader_;
  ComPtr<ID3D11InputLayout> inputLayout_;
  ComPtr<ID3D11InputLayout> pickInputLayout_;
  ComPtr<ID3D11Buffer> vertexBuffer_, indexBuffer_, constants_, edgeBuffer_, pointBuffer_;
  ComPtr<ID3D11RasterizerState> rasterizer_;
  ComPtr<ID3D11DepthStencilState> depthState_;
  ComPtr<ID3D11DepthStencilState> pickOverlayDepthState_;
  UINT indexCount_ = 0;
  UINT edgeVertexCount_ = 0, pointVertexCount_ = 0;
  Vec3 minimum_{}, maximum_{};
  flcad::render::CadCameraSystem camera_;
  bool dragging_ = false, panning_ = false, dragMoved_ = false;
  POINT previous_{}, dragStart_{};
  PickResult hover_{}, selected_{};
  PickKind pickMode_ = PickKind::face;
  uint64_t frames_ = 0;
  double fps_ = 0;
  std::chrono::steady_clock::time_point lastMetric_{};
  std::wstring adapterName_;
};

RenderLab* labFrom(HWND window) {
  return reinterpret_cast<RenderLab*>(GetWindowLongPtrW(window, GWLP_USERDATA));
}

LRESULT CALLBACK windowProcedure(HWND window, UINT message, WPARAM wparam, LPARAM lparam) {
  RenderLab* lab = labFrom(window);
  try {
    switch (message) {
      case WM_SIZE: if (lab && wparam != SIZE_MINIMIZED) lab->resize(); return 0;
      case WM_LBUTTONDOWN: if (lab) lab->beginDrag(GET_X_LPARAM(lparam), GET_Y_LPARAM(lparam), false); return 0;
      case WM_MBUTTONDOWN: if (lab) lab->beginDrag(GET_X_LPARAM(lparam), GET_Y_LPARAM(lparam), true); return 0;
      case WM_LBUTTONUP: if (lab) lab->endDrag(GET_X_LPARAM(lparam), GET_Y_LPARAM(lparam), true); return 0;
      case WM_MBUTTONUP: if (lab) lab->endDrag(GET_X_LPARAM(lparam), GET_Y_LPARAM(lparam), false); return 0;
      case WM_MOUSEMOVE:
        if (lab) {
          lab->drag(GET_X_LPARAM(lparam), GET_Y_LPARAM(lparam));
          lab->hoverAt(GET_X_LPARAM(lparam), GET_Y_LPARAM(lparam));
        }
        return 0;
      case WM_MOUSEWHEEL: if (lab) lab->zoom(GET_WHEEL_DELTA_WPARAM(wparam)); return 0;
      case WM_KEYDOWN:
        if (lab && (wparam == 'F' || wparam == VK_HOME)) lab->fit();
        if (lab && wparam == '1') lab->setPickMode(PickKind::face);
        if (lab && wparam == '2') lab->setPickMode(PickKind::edge);
        if (lab && wparam == '3') lab->setPickMode(PickKind::vertex);
        return 0;
      case WM_ERASEBKGND: return 1;
      case WM_DESTROY: PostQuitMessage(0); return 0;
      default: return DefWindowProcW(window, message, wparam, lparam);
    }
  } catch (const std::exception& error) {
    MessageBoxA(window, error.what(), "FLCAD Render Lab failure", MB_ICONERROR);
    PostQuitMessage(1);
    return 0;
  }
}

}  // namespace

int WINAPI wWinMain(HINSTANCE instance, HINSTANCE, PWSTR commandLine, int showCommand) {
  try {
    (void)commandLine;
    int argumentCount = 0;
    wchar_t** arguments = CommandLineToArgvW(GetCommandLineW(), &argumentCount);
    std::filesystem::path stlPath;
    bool benchmarkOneMillion = false;
    for (int index = 1; index < argumentCount; ++index) {
      if (std::wstring_view(arguments[index]) == L"--benchmark-1m") benchmarkOneMillion = true;
      else stlPath = arguments[index];
    }
    LocalFree(arguments);

    WNDCLASSEXW windowClass{sizeof(windowClass)};
    windowClass.style = CS_HREDRAW | CS_VREDRAW | CS_OWNDC;
    windowClass.lpfnWndProc = windowProcedure;
    windowClass.hInstance = instance;
    windowClass.hCursor = LoadCursor(nullptr, IDC_ARROW);
    windowClass.lpszClassName = kWindowClass;
    if (!RegisterClassExW(&windowClass)) throw std::runtime_error("RegisterClassEx failed");
    HWND window = CreateWindowExW(0, kWindowClass, kWindowTitle, WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT, CW_USEDEFAULT, 1280, 820, nullptr, nullptr, instance, nullptr);
    if (!window) throw std::runtime_error("CreateWindowEx failed");
    if (stlPath.empty()) {
      const std::wstring selected = openStlDialog(window);
      if (selected.empty()) return 0;
      stlPath = selected;
    }
    RenderLab lab(window);
    SetWindowLongPtrW(window, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(&lab));
    lab.initialize(stlPath, benchmarkOneMillion);
    ShowWindow(window, showCommand);
    UpdateWindow(window);

    MSG message{};
    while (message.message != WM_QUIT) {
      while (PeekMessageW(&message, nullptr, 0, 0, PM_REMOVE)) {
        TranslateMessage(&message);
        DispatchMessageW(&message);
      }
      if (message.message == WM_QUIT) break;
      if (!IsIconic(window)) lab.render();
      else WaitMessage();
    }
    SetWindowLongPtrW(window, GWLP_USERDATA, 0);
    DestroyWindow(window);
    return static_cast<int>(message.wParam);
  } catch (const std::exception& error) {
    MessageBoxA(nullptr, error.what(), "FLCAD Render Lab startup failure", MB_ICONERROR);
    return 1;
  }
}
