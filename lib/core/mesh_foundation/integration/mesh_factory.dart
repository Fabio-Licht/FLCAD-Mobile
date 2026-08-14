import 'dart:io';
import '../../cad_kernel/api/geometry_kernel_api.dart';
import '../api/mesh_api.dart';
import '../engine/mesh_engine.dart';
import '../repository/mesh_repository.dart';
import 'mesh_integration.dart';

class MeshFactory {
  const MeshFactory();
  MeshApi create({
    required Directory projectDirectory,
    required GeometryKernelAPI kernel,
    MeshIntegration? integration,
  }) => MeshApi(
    MeshEngine(
      kernel: kernel,
      repository: MeshRepository(projectDirectory),
      integration: integration,
    ),
  );
}
