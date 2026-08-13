import 'package:flutter/material.dart';

import 'bootstrap/app_bootstrap.dart';
import '../features/home/home_screen.dart';
import '../features/professional_workspace/presentation/professional_workspace_screen.dart';
import '../features/engineering_studio/presentation/engineering_studio_screen.dart';
import 'package:flutter/foundation.dart';
import '../theme/flcad_theme.dart';

class FLCADApp extends StatefulWidget {
  const FLCADApp({super.key});

  @override
  State<FLCADApp> createState() => _FLCADAppState();
}

class _FLCADAppState extends State<FLCADApp> {
  late final _restore = _initialize();

  Future<dynamic> _initialize() async {
    return AppBootstrap.instance.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FLCAD Mobile',
      debugShowCheckedModeBanner: false,
      theme: FLCADTheme.dark(),
      home: FutureBuilder(
        future: _restore,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final project = snapshot.data;
          if (project == null) return const HomeScreen();
          final desktop =
              !kIsWeb &&
              const {
                TargetPlatform.windows,
                TargetPlatform.macOS,
                TargetPlatform.linux,
              }.contains(defaultTargetPlatform);
          return desktop
              ? EngineeringStudioScreen(project: project)
              : ProfessionalWorkspaceScreen(project: project);
        },
      ),
    );
  }
}
