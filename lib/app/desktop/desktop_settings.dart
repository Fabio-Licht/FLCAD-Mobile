import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

enum DesktopThemePreference { dark, light }

class DesktopSettings {
  DesktopSettings({
    this.language = 'pt-BR',
    this.theme = DesktopThemePreference.dark,
    this.defaultDirectory = '',
    this.recentProjects = const [],
    this.engineeringTips = true,
    this.firstRunCompleted = false,
  });
  final String language, defaultDirectory;
  final DesktopThemePreference theme;
  final List<String> recentProjects;
  final bool engineeringTips, firstRunCompleted;

  DesktopSettings copyWith({
    String? language,
    DesktopThemePreference? theme,
    String? defaultDirectory,
    List<String>? recentProjects,
    bool? engineeringTips,
    bool? firstRunCompleted,
  }) => DesktopSettings(
    language: language ?? this.language,
    theme: theme ?? this.theme,
    defaultDirectory: defaultDirectory ?? this.defaultDirectory,
    recentProjects: List.unmodifiable(recentProjects ?? this.recentProjects),
    engineeringTips: engineeringTips ?? this.engineeringTips,
    firstRunCompleted: firstRunCompleted ?? this.firstRunCompleted,
  );

  Map<String, dynamic> toJson() => {
    'language': language,
    'theme': theme.name,
    'defaultDirectory': defaultDirectory,
    'recentProjects': recentProjects,
    'preferences': {'engineeringTips': engineeringTips},
    'firstRunCompleted': firstRunCompleted,
  };

  factory DesktopSettings.fromJson(Map<String, dynamic> json) {
    final rawProjects = json['recentProjects'];
    final preferences = json['preferences'];
    return DesktopSettings(
      language: json['language'] as String? ?? 'pt-BR',
      theme: DesktopThemePreference.values.byName(
        json['theme'] as String? ?? 'dark',
      ),
      defaultDirectory: json['defaultDirectory'] as String? ?? '',
      recentProjects: rawProjects is List
          ? rawProjects.whereType<String>().toList()
          : const [],
      engineeringTips: preferences is Map<String, dynamic>
          ? preferences['engineeringTips'] as bool? ?? true
          : true,
      firstRunCompleted: json['firstRunCompleted'] as bool? ?? false,
    );
  }
}

abstract interface class DesktopSettingsRepository {
  Future<DesktopSettings> load();
  Future<void> save(DesktopSettings settings);
}

class JsonDesktopSettingsRepository implements DesktopSettingsRepository {
  JsonDesktopSettingsRepository(Directory configDirectory)
    : file = File(
        '${configDirectory.path}${Platform.pathSeparator}settings.json',
      );
  final File file;

  @override
  Future<DesktopSettings> load() async {
    if (!await file.exists()) {
      return DesktopSettings();
    }
    final value = jsonDecode(await file.readAsString());
    if (value is! Map<String, dynamic>) {
      throw const FormatException('settings.json must contain an object');
    }
    return DesktopSettings.fromJson(value);
  }

  @override
  Future<void> save(DesktopSettings settings) async {
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(settings.toJson()),
    );
  }
}

class DesktopSettingsController extends ChangeNotifier {
  DesktopSettingsController(this.repository, this.settings);
  final DesktopSettingsRepository repository;
  DesktopSettings settings;
  Future<void> update(DesktopSettings value) async {
    settings = value;
    await repository.save(value);
    notifyListeners();
  }
}

class MemoryDesktopSettingsRepository implements DesktopSettingsRepository {
  MemoryDesktopSettingsRepository([DesktopSettings? initial])
    : value = initial ?? DesktopSettings();
  DesktopSettings value;
  @override
  Future<DesktopSettings> load() async => value;
  @override
  Future<void> save(DesktopSettings settings) async => value = settings;
}
