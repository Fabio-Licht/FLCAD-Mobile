cmake_minimum_required(VERSION 3.20)
project(flcad_render_lab LANGUAGES CXX)

if(NOT WIN32)
  message(FATAL_ERROR "FLCAD Render Lab R2-002 is a Windows/D3D11 prototype")
endif()

add_executable(flcad_render_lab WIN32 src/main.cpp)
set_target_properties(flcad_render_lab PROPERTIES
  OUTPUT_NAME "FLCAD Render Lab"
  CXX_STANDARD 20
  CXX_STANDARD_REQUIRED ON)
target_compile_definitions(flcad_render_lab PRIVATE UNICODE _UNICODE NOMINMAX WIN32_LEAN_AND_MEAN)
target_compile_options(flcad_render_lab PRIVATE /W4 /permissive- /EHsc)
target_include_directories(flcad_render_lab PRIVATE ../render_engine)
target_link_libraries(flcad_render_lab PRIVATE d3d11 dxgi d3dcompiler comdlg32 shell32)

add_executable(flcad_camera_contract_test
  ../render_engine/tests/camera_contract_test.cpp)
set_target_properties(flcad_camera_contract_test PROPERTIES
  CXX_STANDARD 20
  CXX_STANDARD_REQUIRED ON)
target_compile_definitions(flcad_camera_contract_test PRIVATE NOMINMAX WIN32_LEAN_AND_MEAN)
target_compile_options(flcad_camera_contract_test PRIVATE /W4 /permissive- /EHsc)
target_include_directories(flcad_camera_contract_test PRIVATE ../render_engine)
