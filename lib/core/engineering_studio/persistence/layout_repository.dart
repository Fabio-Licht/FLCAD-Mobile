import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../../storage/local_storage_service.dart';
import '../models/studio_models.dart';

class StudioLayoutRepository {
  StudioLayoutRepository({LocalStorageService? storage})
    : _storage = storage ?? LocalStorageService();
  final LocalStorageService _storage;
  Future<File> save(String projectId, StudioLayout layout) async {
    final jobs = await _storage.getJobsDirectory(),
        dir = Directory(path.join(jobs.path, projectId, 'Workspace'));
    await dir.create(recursive: true);
    final file = File(path.join(dir.path, 'engineering-studio.json')),
        tmp = File('${file.path}.tmp');
    await tmp.writeAsString(
      const JsonEncoder.withIndent(' ').convert({
        'schema': 'flcad.studio-layout',
        'version': 1,
        'id': layout.id,
        'viewportLayout': layout.viewportLayout.name,
        'theme': layout.theme.name,
        'profile': layout.profile.name,
        'viewports': layout.viewports
            .map(
              (v) => {
                'id': v.id,
                'camera': v.camera.toJson(),
                'grid': v.grid,
                'orientation': v.orientation,
                'near': v.clippingNear,
                'far': v.clippingFar,
              },
            )
            .toList(),
        'panels': layout.panels
            .map(
              (p) => {
                'type': p.type.name,
                'position': p.position.name,
                'visible': p.visible,
                'detached': p.detached,
                'size': p.size,
                'order': p.order,
              },
            )
            .toList(),
      }),
      flush: true,
    );
    if (await file.exists()) await file.delete();
    return tmp.rename(file.path);
  }

  Future<StudioLayout?> load(String projectId) async {
    final jobs = await _storage.getJobsDirectory(),
        file = File(
          path.join(
            jobs.path,
            projectId,
            'Workspace',
            'engineering-studio.json',
          ),
        );
    if (!await file.exists()) return null;
    final j = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return StudioLayout(
      id: j['id'] as String,
      viewportLayout: ViewportLayout.values.byName(
        j['viewportLayout'] as String,
      ),
      theme: StudioTheme.values.byName(j['theme'] as String),
      profile: StudioProfile.values.byName(j['profile'] as String),
      viewports: (j['viewports'] as List).map((raw) {
        final v = (raw as Map).cast<String, dynamic>();
        return StudioViewport(
          id: v['id'] as String,
          camera: StudioCameraState.fromJson((v['camera'] as Map).cast()),
          grid: v['grid'] as bool,
          orientation: v['orientation'] as String,
          clippingNear: (v['near'] as num).toDouble(),
          clippingFar: (v['far'] as num).toDouble(),
        );
      }).toList(),
      panels: (j['panels'] as List).map((raw) {
        final p = (raw as Map).cast<String, dynamic>();
        return DockPanelState(
          StudioPanelType.values.byName(p['type'] as String),
          DockPosition.values.byName(p['position'] as String),
          visible: p['visible'] as bool,
          detached: p['detached'] as bool,
          size: (p['size'] as num).toDouble(),
          order: p['order'] as int,
        );
      }).toList(),
    );
  }
}
