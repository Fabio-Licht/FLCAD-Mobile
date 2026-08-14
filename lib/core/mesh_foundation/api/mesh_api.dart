import '../../cad_kernel/io/kernel_io_models.dart';
import '../engine/mesh_engine.dart';
import '../models/mesh_models.dart';

class MeshApi {
  const MeshApi(this.engine);
  final MeshEngine engine;
  Future<MeshImportResult> importStl(
    String path, {
    required String projectId,
    String units = 'mm',
    KernelImportFormat format = KernelImportFormat.autoDetect,
  }) => engine.importStl(
    path,
    projectId: projectId,
    units: units,
    format: format,
  );
  Future<MeshImportResult> reload(String id) => engine.reload(id);
  Future<void> close(String id) => engine.close(id);
  Future<void> persist() => engine.persist();
}
