import 'dart:convert';
import 'dart:io';
import '../analytics/profile_analytics.dart';
import '../history/profile_history.dart';
import '../models/profile_models.dart';
import '../topology/profile_graphs.dart';

class ProfileRepository {
  ProfileRepository(this.projectDirectory);
  final Directory projectDirectory;
  static const paths = [
    'CAD/Profiles',
    'CAD/ProfileLoops',
    'CAD/ProfileRegions',
    'CAD/ProfileTopology',
    'CAD/ProfileHistory',
    'CAD/ProfileAnalytics',
  ];
  Directory _dir(String p) => Directory(
    '${projectDirectory.path}${Platform.pathSeparator}${p.replaceAll('/', Platform.pathSeparator)}',
  );
  String _safe(String id) => id.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  Future<void> save({
    required Iterable<RecognizedProfile> profiles,
    required Iterable<ProfileLoop> loops,
    required Iterable<SketchRegion> regions,
    required ProfileGraphSet graphs,
    required ProfileHistory history,
    required ProfileAnalytics analytics,
  }) async {
    for (final p in paths) {
      await _dir(p).create(recursive: true);
    }
    for (final p in profiles) {
      await File(
        '${_dir(paths[0]).path}${Platform.pathSeparator}${_safe(p.id)}.json',
      ).writeAsString(jsonEncode(p.toJson()));
    }
    for (final l in loops) {
      await File(
        '${_dir(paths[1]).path}${Platform.pathSeparator}${_safe(l.id)}.json',
      ).writeAsString(jsonEncode(l.toJson()));
    }
    for (final r in regions) {
      await File(
        '${_dir(paths[2]).path}${Platform.pathSeparator}${_safe(r.id)}.json',
      ).writeAsString(jsonEncode(r.toJson()));
    }
    await File(
      '${_dir(paths[3]).path}${Platform.pathSeparator}topology.json',
    ).writeAsString(jsonEncode(graphs.toJson()));
    await File(
      '${_dir(paths[4]).path}${Platform.pathSeparator}history.json',
    ).writeAsString(
      jsonEncode(history.entries.map((e) => e.toJson()).toList()),
    );
    await File(
      '${_dir(paths[5]).path}${Platform.pathSeparator}analytics.json',
    ).writeAsString(jsonEncode(analytics.toJson()));
  }
}

class ProfileRepositoryFactory {
  const ProfileRepositoryFactory();
  ProfileRepository create(Directory project) => ProfileRepository(project);
}
