#pragma once
#include <stddef.h>

#if defined(_WIN32)
#define FLCAD_OCC_EXPORT __declspec(dllexport)
#else
#define FLCAD_OCC_EXPORT __attribute__((visibility("default")))
#endif

extern "C" {
FLCAD_OCC_EXPORT int flcad_occ_initialize(char* error, size_t error_size);
FLCAD_OCC_EXPORT void flcad_occ_shutdown();
FLCAD_OCC_EXPORT const char* flcad_occ_version();
FLCAD_OCC_EXPORT const char* flcad_occ_capabilities();
FLCAD_OCC_EXPORT const char* flcad_occ_diagnostics();
FLCAD_OCC_EXPORT int flcad_occ_create_vertex(double x,double y,double z,char* token,size_t token_size,char* fingerprint,size_t fingerprint_size,char* error,size_t error_size);
FLCAD_OCC_EXPORT int flcad_occ_create_edge(const char* start,const char* end,char* token,size_t token_size,char* fingerprint,size_t fingerprint_size,char* error,size_t error_size);
FLCAD_OCC_EXPORT int flcad_occ_create_wire(const char* edge_tokens,char* token,size_t token_size,char* fingerprint,size_t fingerprint_size,char* error,size_t error_size);
FLCAD_OCC_EXPORT int flcad_occ_create_face(const char* wire_token,char* token,size_t token_size,char* fingerprint,size_t fingerprint_size,char* error,size_t error_size);
FLCAD_OCC_EXPORT int flcad_occ_create_shell(const char* face_tokens,double tolerance,char* token,size_t token_size,char* fingerprint,size_t fingerprint_size,char* error,size_t error_size);
FLCAD_OCC_EXPORT int flcad_occ_create_solid(const char* shell_token,char* token,size_t token_size,char* fingerprint,size_t fingerprint_size,char* error,size_t error_size);
FLCAD_OCC_EXPORT int flcad_occ_create_plane(const double* origin,const double* normal,double lower,double upper,char* token,size_t token_size,char* fingerprint,size_t fingerprint_size,char* error,size_t error_size);
FLCAD_OCC_EXPORT int flcad_occ_create_cylinder(const double* origin,const double* direction,double radius,double lower,double upper,char* token,size_t token_size,char* fingerprint,size_t fingerprint_size,char* error,size_t error_size);
FLCAD_OCC_EXPORT int flcad_occ_create_cone(const double* apex,const double* direction,double angle,double lower,double upper,char* token,size_t token_size,char* fingerprint,size_t fingerprint_size,char* error,size_t error_size);
FLCAD_OCC_EXPORT int flcad_occ_create_sphere(const double* center,double radius,double lower,double upper,char* token,size_t token_size,char* fingerprint,size_t fingerprint_size,char* error,size_t error_size);
FLCAD_OCC_EXPORT int flcad_occ_import_shape(const char* path,const char* format,char* token,size_t token_size,char* fingerprint,size_t fingerprint_size,char* type,size_t type_size,char* error,size_t error_size);
FLCAD_OCC_EXPORT int flcad_occ_export_shape(const char* token,const char* path,const char* format,char* error,size_t error_size);
FLCAD_OCC_EXPORT int flcad_occ_validate(const char* token,char* diagnostics,size_t diagnostics_size,char* error,size_t error_size);
FLCAD_OCC_EXPORT int flcad_occ_healing_proposals(const char* token,char* proposals,size_t proposals_size,char* error,size_t error_size);
FLCAD_OCC_EXPORT int flcad_occ_mesh(const char* token,const char* path,double deflection,int* vertices,int* triangles,char* error,size_t error_size);
FLCAD_OCC_EXPORT size_t flcad_occ_shape_count();
}
