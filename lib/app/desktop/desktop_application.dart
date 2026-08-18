import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/cad_kernel/manager/kernel_manager.dart';
import '../../core/cad_document/cad_document.dart';
import '../../core/geometric_kernel/geometry/vectors.dart';
import '../../core/professional_recognition/api/professional_recognition_api.dart';
import '../../core/professional_surface/models/professional_surface_models.dart';
import '../../core/reference_engine/models/reference_geometry.dart';
import '../../core/sketch_editor/models/editor_models.dart';
import '../../features/projects/domain/project_manager.dart';
import '../../features/projects/models/project.dart';
import '../bootstrap/app_bootstrap.dart';
import '../bootstrap/engineering_bootstrap.dart';
import '../cad_viewport/camera/cad_camera_controller.dart';
import '../cad_viewport/native/integrated_native_viewport_widget.dart';
import '../cad_viewport/scene/cad_scene_graph.dart';
import '../commands/desktop_command_coordinator.dart';
import '../engineering_bridge/operational_reverse_engineering_controller.dart';
import '../engineering_bridge/selection/geometry_selection_manager.dart';
import '../engineering_bridge/widgets/recognition_workspace_panel.dart';
import '../engineering_bridge/widgets/sketch_surface_workspace_panel.dart';
import '../modeling/modeling.dart';
import 'desktop_asset_manager.dart';
import 'desktop_cad_controller.dart';
import 'desktop_settings.dart';
import 'desktop_theme.dart';

class FLCADDesktopApplication extends StatefulWidget {
  const FLCADDesktopApplication({
    super.key,
    this.settingsRepository,
    this.splashStep = const Duration(milliseconds: 250),
  });
  final DesktopSettingsRepository? settingsRepository;
  final Duration splashStep;
  @override
  State<FLCADDesktopApplication> createState() =>
      _FLCADDesktopApplicationState();
}

class _FLCADDesktopApplicationState extends State<FLCADDesktopApplication> {
  DesktopSettingsController? controller;
  Object? startupError;
  final ChangeNotifier emptyController = ChangeNotifier();
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final repository =
          widget.settingsRepository ??
          JsonDesktopSettingsRepository(await getApplicationSupportDirectory());
      await DesktopAssetManager(rootBundle).validate();
      await AppBootstrap.instance.initialize();
      final value = DesktopSettingsController(
        repository,
        await repository.load(),
      );
      if (mounted) setState(() => controller = value);
    } catch (error) {
      if (mounted) setState(() => startupError = error);
    }
  }

  @override
  void dispose() {
    emptyController.dispose();
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = controller;
    return AnimatedBuilder(
      animation: value ?? emptyController,
      builder: (context, _) => MaterialApp(
        title: 'FLCAD Reverse AI',
        debugShowCheckedModeBanner: false,
        theme: DesktopThemeManager.light(),
        darkTheme: DesktopThemeManager.dark(),
        themeMode: value?.settings.theme == DesktopThemePreference.light
            ? ThemeMode.light
            : ThemeMode.dark,
        home: startupError != null
            ? _StartupFailure(error: startupError!)
            : value == null
            ? const _StartupLoading()
            : DesktopStartupSequence(
                controller: value,
                stepDuration: widget.splashStep,
              ),
      ),
    );
  }
}

class _StartupLoading extends StatelessWidget {
  const _StartupLoading();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _StartupFailure extends StatelessWidget {
  const _StartupFailure({required this.error});
  final Object error;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Semantics(
        label: 'Desktop startup failed',
        child: Text(
          'Unable to start FLCAD Reverse AI\n$error',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}

class DesktopStartupSequence extends StatefulWidget {
  const DesktopStartupSequence({
    super.key,
    required this.controller,
    required this.stepDuration,
  });
  final DesktopSettingsController controller;
  final Duration stepDuration;
  @override
  State<DesktopStartupSequence> createState() => _DesktopStartupSequenceState();
}

class _DesktopStartupSequenceState extends State<DesktopStartupSequence> {
  static const messages = [
    'Initializing Project System...',
    'Loading Geometry Kernel...',
    'Loading AI Engineering...',
    'Loading Recognition Engine...',
    'Loading Workspaces...',
    'Loading User Interface...',
    'Ready.',
  ];
  int index = 0;
  bool complete = false;
  @override
  void initState() {
    super.initState();
    _advance();
  }

  Future<void> _advance() async {
    for (var next = 0; next < messages.length; next++) {
      await Future<void>.delayed(widget.stepDuration);
      if (!mounted) return;
      setState(() => index = next);
    }
    if (mounted) setState(() => complete = true);
  }

  @override
  Widget build(BuildContext context) {
    if (complete) {
      return widget.controller.settings.firstRunCompleted
          ? DesktopShell(controller: widget.controller)
          : FirstRunWizard(controller: widget.controller);
    }
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 560,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                duration: widget.stepDuration * 2,
                tween: Tween(begin: .85, end: 1),
                builder: (context, value, child) =>
                    Transform.scale(scale: value, child: child),
                child: Image.asset(
                  DesktopAssets.splashTransformation,
                  width: 176,
                  height: 176,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'FLCAD Reverse AI',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Engineering Intelligence Platform',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: scheme.primary),
              ),
              const SizedBox(height: 32),
              LinearProgressIndicator(value: (index + 1) / messages.length),
              const SizedBox(height: 12),
              Text(messages[index], key: const Key('splash-status')),
            ],
          ),
        ),
      ),
    );
  }
}

class FirstRunWizard extends StatefulWidget {
  const FirstRunWizard({super.key, required this.controller});
  final DesktopSettingsController controller;
  @override
  State<FirstRunWizard> createState() => _FirstRunWizardState();
}

class _FirstRunWizardState extends State<FirstRunWizard> {
  int step = 0;
  late String language = widget.controller.settings.language;
  late DesktopThemePreference theme = widget.controller.settings.theme;
  late final directory = TextEditingController(
    text: widget.controller.settings.defaultDirectory,
  );
  @override
  void dispose() {
    directory.dispose();
    super.dispose();
  }

  Future<void> _finish() => widget.controller.update(
    widget.controller.settings.copyWith(
      language: language,
      theme: theme,
      defaultDirectory: directory.text.trim(),
      firstRunCompleted: true,
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Welcome to FLCAD Reverse AI')),
    body: Center(
      child: SizedBox(
        width: 720,
        child: Stepper(
          currentStep: step,
          onStepContinue: () async {
            if (step < 2) {
              setState(() => step++);
            } else {
              await _finish();
            }
          },
          onStepCancel: step == 0 ? null : () => setState(() => step--),
          controlsBuilder: (context, details) => Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              children: [
                FilledButton(
                  key: ValueKey('wizard-continue-${details.stepIndex}'),
                  onPressed: details.onStepContinue,
                  child: Text(step == 2 ? 'Finish' : 'Continue'),
                ),
                if (details.onStepCancel != null) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back'),
                  ),
                ],
              ],
            ),
          ),
          steps: [
            Step(
              title: const Text('Language'),
              content: DropdownButtonFormField<String>(
                initialValue: language,
                items: const [
                  DropdownMenuItem(
                    value: 'pt-BR',
                    child: Text('Português (Brasil)'),
                  ),
                  DropdownMenuItem(value: 'en-US', child: Text('English')),
                ],
                onChanged: (value) => setState(() => language = value!),
              ),
            ),
            Step(
              title: const Text('Theme'),
              content: SegmentedButton<DesktopThemePreference>(
                segments: const [
                  ButtonSegment(
                    value: DesktopThemePreference.dark,
                    label: Text('Dark'),
                    icon: Icon(Icons.dark_mode),
                  ),
                  ButtonSegment(
                    value: DesktopThemePreference.light,
                    label: Text('Light'),
                    icon: Icon(Icons.light_mode),
                  ),
                ],
                selected: {theme},
                onSelectionChanged: (value) =>
                    setState(() => theme = value.single),
              ),
            ),
            Step(
              title: const Text('Default directory'),
              content: TextField(
                controller: directory,
                decoration: const InputDecoration(
                  labelText: 'Project directory',
                  hintText: 'Choose a project directory in Settings',
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key, required this.controller});
  final DesktopSettingsController controller;
  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  int destination = 0;
  late final DesktopCadController cad;
  late final DesktopCommandCoordinator commands;
  @override
  void initState() {
    super.initState();
    EngineeringBootstrap.instance.initialize();
    cad = DesktopCadController(
      kernels: EngineeringBootstrap.instance.services.get<KernelManager>(),
      projects: ProjectManager.instance,
    );
    commands = DesktopCommandCoordinator(
      cad: cad,
      projects: ProjectManager.instance,
    );
    unawaited(
      commands.initialize().then((_) {
        if (mounted) setState(() {});
      }),
    );
  }

  @override
  void dispose() {
    cad.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DesktopHomeDashboard(
        onWorkspace: () => setState(() => destination = 1),
        controller: widget.controller,
        commands: commands,
      ),
      OfficialEngineeringWorkspace(cad: cad, commands: commands),
      DesktopSettingsScreen(controller: widget.controller),
    ];
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Image.asset(DesktopAssets.logo, width: 34, height: 34),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FLCAD Reverse AI',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Engineering Intelligence Platform',
                  style: TextStyle(fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Arquivo',
            onSelected: (value) async {
              final parts = value.split(':');
              await commands.dispatch('${parts.first}.${parts.last}');
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'project:save',
                child: Text('Salvar Projeto'),
              ),
              PopupMenuItem(
                value: 'project:close',
                child: Text('Fechar Projeto'),
              ),
              PopupMenuDivider(),
              PopupMenuItem(enabled: false, child: Text('Importar')),
              PopupMenuItem(value: 'import:stl', child: Text('STL')),
              PopupMenuItem(value: 'import:step', child: Text('STEP')),
              PopupMenuItem(value: 'import:iges', child: Text('IGES')),
              PopupMenuDivider(),
              PopupMenuItem(enabled: false, child: Text('Exportar')),
              PopupMenuItem(value: 'export:step', child: Text('STEP')),
              PopupMenuItem(value: 'export:iges', child: Text('IGES')),
              PopupMenuItem(value: 'export:stl', child: Text('STL')),
            ],
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(Icons.folder_outlined),
                  SizedBox(width: 6),
                  Text('Arquivo'),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Undo',
            onPressed: commands.undo,
            icon: const Icon(Icons.undo),
          ),
          IconButton(
            tooltip: 'Redo',
            onPressed: commands.redo,
            icon: const Icon(Icons.redo),
          ),
          IconButton(
            tooltip: 'About',
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const AboutFLCADDialog(),
            ),
            icon: const Icon(Icons.info_outline),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: destination,
            onDestinationSelected: (value) =>
                setState(() => destination = value),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: Text('Home'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.view_quilt_outlined),
                selectedIcon: Icon(Icons.view_quilt),
                label: Text('Workspace'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
          ),
          const VerticalDivider(),
          Expanded(child: screens[destination]),
        ],
      ),
    );
  }
}

class DesktopHomeDashboard extends StatefulWidget {
  const DesktopHomeDashboard({
    super.key,
    required this.onWorkspace,
    required this.controller,
    required this.commands,
  });
  final VoidCallback onWorkspace;
  final DesktopSettingsController controller;
  final DesktopCommandCoordinator commands;

  @override
  State<DesktopHomeDashboard> createState() => _DesktopHomeDashboardState();
}

class _DesktopHomeDashboardState extends State<DesktopHomeDashboard> {
  bool creatingProject = false;
  Completer<void>? projectDialogCompletion;
  DesktopSettingsController get controller => widget.controller;
  DesktopCommandCoordinator get commands => widget.commands;
  VoidCallback get onWorkspace => widget.onWorkspace;

  Future<void> _newProject(BuildContext context) async {
    if (!creatingProject) {
      projectDialogCompletion = Completer<void>();
      setState(() => creatingProject = true);
    }
    await projectDialogCompletion?.future;
  }

  void _cancelProject() {
    setState(() => creatingProject = false);
    projectDialogCompletion?.complete();
    projectDialogCompletion = null;
  }

  Future<void> _createProject(String name, String client) async {
    await commands.createProject(name, client);
    if (!mounted) return;
    setState(() => creatingProject = false);
    projectDialogCompletion?.complete();
    projectDialogCompletion = null;
    onWorkspace();
  }

  Future<void> _openProject(BuildContext context) async {
    await commands.projects.initialize(restoreCurrent: false);
    if (!context.mounted) return;
    final project = await showDialog<Project>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Open Project'),
        children: [
          for (final project in commands.projects.visibleProjects)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, project),
              child: ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text(project.name),
                subtitle: Text(project.client),
              ),
            ),
          if (commands.projects.visibleProjects.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No projects available.'),
            ),
        ],
      ),
    );
    if (project != null) {
      await commands.openProject(project);
      onWorkspace();
    }
  }

  Future<bool> _ensureProject(BuildContext context) async {
    if (commands.projects.current != null) return true;
    await _newProject(context);
    return commands.projects.current != null;
  }

  @override
  Widget build(BuildContext context) {
    final settings = controller.settings;
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(32),
          children: [
            Text(
              'Home Dashboard',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'FLCAD Reverse AI 0.9.1 Alpha · FLCAD MODEL',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _DashboardAction(
                  icon: Icons.add_box_outlined,
                  label: 'Novo Projeto',
                  onTap: () => _newProject(context),
                ),
                _DashboardAction(
                  icon: Icons.folder_open,
                  label: 'Abrir Projeto',
                  onTap: () => _openProject(context),
                ),
                _DashboardAction(
                  icon: Icons.grid_on,
                  label: 'Importar STL',
                  onTap: () async {
                    if (!await _ensureProject(context)) return;
                    onWorkspace();
                    await commands.refreshContext();
                    await commands.dispatch('import.stl');
                  },
                ),
                _DashboardAction(
                  icon: Icons.view_in_ar,
                  label: 'Importar STEP',
                  onTap: () async {
                    if (!await _ensureProject(context)) return;
                    onWorkspace();
                    await commands.refreshContext();
                    await commands.dispatch('import.step');
                  },
                ),
                _DashboardAction(
                  icon: Icons.tune,
                  label: 'Configurações',
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Use Settings in the navigation rail.'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              'Projetos Recentes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            if (commands.projects.visibleProjects.isEmpty)
              const _EmptyState(
                icon: Icons.history,
                message:
                    'No recent projects. Open or create a project to begin.',
              )
            else
              for (final project in commands.projects.visibleProjects.take(8))
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(project.name),
                  subtitle: Text(project.client),
                  onTap: () async {
                    await commands.openProject(project);
                    onWorkspace();
                  },
                ),
            if (settings.engineeringTips) ...[
              const SizedBox(height: 24),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.lightbulb_outline),
                  title: const Text('Engineering tip'),
                  subtitle: const Text(
                    'Validate the project coordinate system before reconstruction.',
                  ),
                  trailing: IconButton(
                    tooltip: 'Disable tips',
                    onPressed: () => controller.update(
                      settings.copyWith(engineeringTips: false),
                    ),
                    icon: const Icon(Icons.close),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onWorkspace,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Open Engineering Workspace'),
            ),
          ],
        ),
        if (creatingProject)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black54,
              child: Center(
                child: _InlineNewProjectPanel(
                  onCancel: _cancelProject,
                  onCreate: _createProject,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _InlineNewProjectPanel extends StatefulWidget {
  const _InlineNewProjectPanel({
    required this.onCancel,
    required this.onCreate,
  });
  final VoidCallback onCancel;
  final Future<void> Function(String name, String client) onCreate;

  @override
  State<_InlineNewProjectPanel> createState() => _InlineNewProjectPanelState();
}

class _InlineNewProjectPanelState extends State<_InlineNewProjectPanel> {
  final name = TextEditingController();
  final client = TextEditingController();
  bool busy = false;

  @override
  void dispose() {
    name.dispose();
    client.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final projectName = name.text.trim();
    if (projectName.isEmpty || busy) return;
    setState(() => busy = true);
    try {
      await widget.onCreate(projectName, client.text.trim());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    elevation: 12,
    child: SizedBox(
      width: 460,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('New Project', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            TextField(
              controller: name,
              autofocus: true,
              onSubmitted: (_) => _create(),
              decoration: const InputDecoration(labelText: 'Project name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: client,
              onSubmitted: (_) => _create(),
              decoration: const InputDecoration(labelText: 'Client'),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: busy ? null : widget.onCancel,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: busy ? null : _create,
                  child: busy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _DashboardAction extends StatelessWidget {
  const _DashboardAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 180,
    height: 104,
    child: Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon),
              const Spacer(),
              Text(label, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        ),
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});
  final IconData icon;
  final String message;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}

class OfficialEngineeringWorkspace extends StatefulWidget {
  const OfficialEngineeringWorkspace({
    super.key,
    required this.cad,
    required this.commands,
  });
  final DesktopCadController cad;
  final DesktopCommandCoordinator commands;
  @override
  State<OfficialEngineeringWorkspace> createState() =>
      _OfficialEngineeringWorkspaceState();
}

class _OfficialEngineeringWorkspaceState
    extends State<OfficialEngineeringWorkspace> {
  String module = 'AI Engineering';
  final modelingViewport = ModelingViewportController();
  CadSceneGraph get scene => widget.cad.runtime.scene;
  final camera = CadCameraController();
  GeometrySelectionManager get geometrySelection =>
      widget.cad.runtime.geometrySelection;
  late final OperationalReverseEngineeringController operational;
  String? fittedDocumentId;
  final transformX = TextEditingController(text: '10');
  final transformY = TextEditingController(text: '0');
  final transformZ = TextEditingController(text: '0');
  final transformAngle = TextEditingController(text: '15');
  final transformScaleX = TextEditingController(text: '1.1');
  final transformScaleY = TextEditingController(text: '1.1');
  final transformScaleZ = TextEditingController(text: '1.1');
  double rememberedSplineTolerance = 0.05;
  bool rememberSplineConfiguration = false;
  bool automaticSplinePreview = true;
  static const modules = [
    'AI Engineering',
    'Recognition',
    'Sketch & Surface',
    'Sections',
    'Transform',
  ];
  ModelingSelection? get documentSelection {
    final document = widget.cad.document;
    if (document == null) return null;
    return ModelingSelection(
      id: document.id,
      name: document.sourcePath.split(RegExp(r'[/\\]')).last,
      type: document.isMesh
          ? ModelingSelectionType.meshRegion
          : ModelingSelectionType.feature,
      sourceIds: [document.registeredPath],
      evidence: document.isMesh
          ? ['${document.mesh!.triangleCount} kernel triangles']
          : ['Validated ${document.shape!.type.name} kernel shape'],
    );
  }

  @override
  void initState() {
    super.initState();
    operational = OperationalReverseEngineeringController(
      recognition: EngineeringBootstrap.instance.services
          .get<ProfessionalRecognitionApi>(),
      commands: widget.commands,
      runtime: widget.cad.runtime,
    );
    widget.cad.addListener(_synchronizeScene);
    _synchronizeScene();
  }

  @override
  void dispose() {
    transformX.dispose();
    transformY.dispose();
    transformZ.dispose();
    transformAngle.dispose();
    transformScaleX.dispose();
    transformScaleY.dispose();
    transformScaleZ.dispose();
    widget.cad.removeListener(_synchronizeScene);
    operational.dispose();
    camera.dispose();
    modelingViewport.dispose();
    super.dispose();
  }

  void _synchronizeScene() {
    final runtimeDocument = widget.cad.runtime.document;
    if (runtimeDocument == null) {
      operational.detachProject();
      fittedDocumentId = null;
      return;
    }
    unawaited(
      widget.commands.repository
          .directoryFor(runtimeDocument.projectId)
          .then(
            (directory) => operational.configureProject(
              projectId: runtimeDocument.projectId,
              projectDirectory: directory,
            ),
          ),
    );
    final document = widget.cad.document;
    if (document == null) return;
    if (fittedDocumentId != document.id) {
      final bounds = document.mesh?.bounds;
      if (bounds != null) {
        camera.fit(
          Vector3(bounds.minX, bounds.minY, bounds.minZ),
          Vector3(bounds.maxX, bounds.maxY, bounds.maxZ),
        );
      }
      fittedDocumentId = document.id;
    }
  }

  void selectDocument() {
    final selection = documentSelection;
    if (selection == null) return;
    modelingViewport.select(selection);
    widget.cad.runtime.select({widget.cad.document!.id});
    widget.commands.dispatch('selection.set', {
      'ids': [selection.id],
    });
  }

  Future<void> _openSketch() async {
    await operational.openSketch();
    final geometry = operational.activeSketchPlane;
    if (geometry is! PlaneGeometry) return;
    Vector3 vector(List<double> value) => Vector3(value[0], value[1], value[2]);
    final normal = vector(geometry.normal.toJson()).normalized;
    final xDirection = geometry.xDirection == null
        ? normal
              .cross(
                normal.z.abs() < .9
                    ? const Vector3(0, 0, 1)
                    : const Vector3(0, 1, 0),
              )
              .normalized
        : vector(geometry.xDirection!.toJson()).normalized;
    camera.enterSketch(
      origin: vector(geometry.origin.toJson()),
      normal: normal,
      xDirection: xDirection,
    );
  }

  Future<void> _finishSketch() async {
    await operational.finishSketch();
    camera.exitSketch();
  }

  Future<void> _applyAlignment() async {
    await operational.applyAlignment();
    final bounds = widget.cad.runtime.activeImport?.mesh?.bounds;
    if (bounds != null) {
      camera.fit(
        Vector3(bounds.minX, bounds.minY, bounds.minZ),
        Vector3(bounds.maxX, bounds.maxY, bounds.maxZ),
      );
    }
  }

  Future<void> _sectionAction(Future<void> Function() action) async {
    try {
      await action();
      widget.cad.setStatus('Section operation completed.');
    } catch (error) {
      widget.cad.setStatus(error.toString());
    }
  }

  Future<void> _bestFitSpline() async {
    var selected = rememberedSplineTolerance;
    var remember = rememberSplineConfiguration;
    var automaticPreview = automaticSplinePreview;
    if (automaticPreview) operational.previewBestFitSpline(selected);
    final sectionData =
        operational.selectedOrActiveSketchSourceSection?.data['section'];
    final section = sectionData is Map ? sectionData : const {};
    final segmentCount = (section['segments'] as List?)?.length ?? 0;
    final pointCount = segmentCount * 2;
    final tolerance = await showDialog<double>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Best Fit Spline'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tolerance'),
              RadioGroup<double>(
                groupValue: selected,
                onChanged: (value) {
                  if (value == null) return;
                  setDialogState(() => selected = value);
                  if (automaticPreview) {
                    operational.previewBestFitSpline(value);
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final value in const [0.01, 0.02, 0.05, 0.10])
                      RadioListTile<double>(
                        title: Text('${value.toStringAsFixed(2)} mm'),
                        value: value,
                      ),
                  ],
                ),
              ),
              Text('Points: $pointCount  ·  Segments: $segmentCount'),
              Text(
                'Estimated time: ${(pointCount / 5000).clamp(.1, 30).toStringAsFixed(1)} s',
              ),
              Text('Maximum error target: ${selected.toStringAsFixed(3)} mm'),
              Text(
                'Mean error target: ${(selected * .5).toStringAsFixed(3)} mm',
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Remember this configuration'),
                value: remember,
                onChanged: (value) =>
                    setDialogState(() => remember = value ?? false),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Automatic preview'),
                value: automaticPreview,
                onChanged: (value) {
                  setDialogState(() => automaticPreview = value ?? false);
                  if (automaticPreview) {
                    operational.previewBestFitSpline(selected);
                  } else {
                    operational.clearBestFitSplinePreview();
                  }
                },
              ),
              const Text(
                'Assistant: use the largest tolerance that preserves the engineering profile.',
              ),
              const Text('Orange: Spline preview'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, selected),
              child: const Text('Create Spline'),
            ),
          ],
        ),
      ),
    );
    operational.clearBestFitSplinePreview();
    if (tolerance == null) return;
    setState(() {
      rememberSplineConfiguration = remember;
      automaticSplinePreview = automaticPreview;
      if (remember) rememberedSplineTolerance = tolerance;
    });
    await _sectionAction(
      () => operational.createSketchFromSelectedSection(
        convertToSpline: true,
        tolerance: tolerance,
      ),
    );
  }

  Widget _sectionTools() => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      FilledButton.icon(
        icon: const Icon(Icons.polyline),
        label: const Text('Create Section'),
        onPressed: () => _sectionAction(operational.createSection),
      ),
      OutlinedButton.icon(
        icon: const Icon(Icons.draw),
        label: const Text('Sketch from Section'),
        onPressed: () =>
            _sectionAction(operational.createSketchFromSelectedSection),
      ),
      OutlinedButton.icon(
        icon: const Icon(Icons.gesture),
        label: const Text('Best Fit Spline'),
        onPressed: _bestFitSpline,
      ),
      OutlinedButton.icon(
        icon: const Icon(Icons.layers_outlined),
        label: const Text('Toggle Section'),
        onPressed: () =>
            _sectionAction(operational.toggleSourceSectionVisibility),
      ),
      OutlinedButton.icon(
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Toggle Sketch'),
        onPressed: () =>
            _sectionAction(operational.toggleActiveSketchVisibility),
      ),
      if (operational.activeSketch?.metadata['associationState'] == 'outdated')
        FilledButton.tonalIcon(
          icon: const Icon(Icons.sync_problem),
          label: const Text('Update Sketch'),
          onPressed: () =>
              _sectionAction(operational.updateActiveSketchFromSourceSection),
        ),
      OutlinedButton.icon(
        icon: const Icon(Icons.swap_vert),
        label: const Text('Dynamic -1'),
        onPressed: () =>
            _sectionAction(() => operational.moveSelectedSection(-1)),
      ),
      OutlinedButton.icon(
        icon: const Icon(Icons.swap_vert),
        label: const Text('Dynamic +1'),
        onPressed: () =>
            _sectionAction(() => operational.moveSelectedSection(1)),
      ),
      OutlinedButton.icon(
        icon: const Icon(Icons.view_stream),
        label: const Text('Multiple (5 × 5 mm)'),
        onPressed: () => _sectionAction(operational.createMultipleSections),
      ),
      OutlinedButton.icon(
        icon: const Icon(Icons.straighten),
        label: const Text('Section by Axis'),
        onPressed: () =>
            _sectionAction(operational.createSectionsBySelectedAxis),
      ),
    ],
  );

  Widget _g106bCertificationPanel() {
    final results = operational.g106bCertificationResults;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('G-106B Certification'),
            const SizedBox(height: 6),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.science_outlined),
              label: const Text('Run Core Smoke Test'),
              onPressed: () async {
                try {
                  await operational.runG106BCertification();
                  widget.cad.setStatus('G-106B core smoke test completed.');
                } catch (error) {
                  widget.cad.setStatus('G-106B certification failed: $error');
                }
              },
            ),
            if (results.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                '${results.length}/14 checks passed',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  double _number(TextEditingController controller, String label) {
    final value = double.tryParse(controller.text.replaceAll(',', '.'));
    if (value == null || !value.isFinite) {
      throw FormatException('$label must be a finite number.');
    }
    return value;
  }

  Future<void> _transformAction(FutureOr<void> Function() action) async {
    try {
      await action();
      widget.cad.setStatus('Transform preview updated.');
    } catch (error) {
      widget.cad.setStatus('Transform: $error');
    }
  }

  Widget _transformTools() {
    Widget numberField(String label, TextEditingController controller) =>
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(
            signed: true,
            decimal: true,
          ),
          decoration: InputDecoration(labelText: label, isDense: true),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Transform', style: TextStyle(fontWeight: FontWeight.bold)),
        const Text('Select an entity, configure values, preview, then apply.'),
        RadioGroup<TransformDisposition>(
          groupValue: operational.transformDisposition,
          onChanged: operational.chooseTransformDisposition,
          child: const Column(
            children: [
              RadioListTile<TransformDisposition>(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: TransformDisposition.original,
                title: Text('Transform Original'),
              ),
              RadioListTile<TransformDisposition>(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: TransformDisposition.workingCopy,
                title: Text('Create Working Copy'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: numberField('X', transformX)),
            const SizedBox(width: 4),
            Expanded(child: numberField('Y', transformY)),
            const SizedBox(width: 4),
            Expanded(child: numberField('Z', transformZ)),
          ],
        ),
        FilledButton.tonalIcon(
          icon: const Icon(Icons.open_with),
          label: const Text('Move Preview'),
          onPressed: () => _transformAction(
            () => operational.previewMove(
              Vector3(
                _number(transformX, 'X'),
                _number(transformY, 'Y'),
                _number(transformZ, 'Z'),
              ),
            ),
          ),
        ),
        const Divider(),
        numberField('Angle (degrees)', transformAngle),
        Wrap(
          spacing: 4,
          children: [
            for (final axis in const [
              ('X', Vector3(1, 0, 0)),
              ('Y', Vector3(0, 1, 0)),
              ('Z', Vector3(0, 0, 1)),
            ])
              OutlinedButton(
                onPressed: () => _transformAction(
                  () => operational.previewRotate(
                    axis.$2,
                    _number(transformAngle, 'Angle'),
                  ),
                ),
                child: Text('Rotate ${axis.$1}'),
              ),
          ],
        ),
        const Divider(),
        Row(
          children: [
            Expanded(child: numberField('Scale X', transformScaleX)),
            const SizedBox(width: 4),
            Expanded(child: numberField('Y', transformScaleY)),
            const SizedBox(width: 4),
            Expanded(child: numberField('Z', transformScaleZ)),
          ],
        ),
        FilledButton.tonalIcon(
          icon: const Icon(Icons.aspect_ratio),
          label: const Text('Scale Preview'),
          onPressed: () => _transformAction(
            () => operational.previewScale(
              Vector3(
                _number(transformScaleX, 'Scale X'),
                _number(transformScaleY, 'Scale Y'),
                _number(transformScaleZ, 'Scale Z'),
              ),
            ),
          ),
        ),
        const Divider(),
        const Text('Transform by Reference'),
        Wrap(
          spacing: 4,
          children: [
            for (final target in const [
              'Origin',
              'XY',
              'XZ',
              'YZ',
              'X',
              'Y',
              'Z',
            ])
              OutlinedButton(
                onPressed: () => _transformAction(
                  () => operational.previewTransformByReference(target),
                ),
                child: Text(target),
              ),
          ],
        ),
        const Divider(),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Apply'),
                onPressed: operational.manualTransformPreview == null
                    ? null
                    : () => _transformAction(operational.applyManualTransform),
              ),
            ),
            IconButton(
              tooltip: 'Cancel preview',
              onPressed: operational.manualTransformPreview == null
                  ? null
                  : operational.cancelManualTransform,
              icon: const Icon(Icons.close),
            ),
            IconButton(
              tooltip: 'Reset transform',
              onPressed: () =>
                  _transformAction(operational.resetSelectedTransform),
              icon: const Icon(Icons.restart_alt),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.undo),
                label: const Text('Undo'),
                onPressed: widget.cad.runtime.canUndo
                    ? () => _transformAction(operational.undoManualTransform)
                    : null,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.redo),
                label: const Text('Redo'),
                onPressed: widget.cad.runtime.canRedo
                    ? () => _transformAction(operational.redoManualTransform)
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmDelete(CadDocumentEntity entity) async {
    final impacted = operational.deletionImpact(entity.id);
    operational.previewDeletion(
      entity.id,
      includeDependencies: impacted.isNotEmpty,
    );
    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final counts = <String, int>{};
        for (final item in impacted) {
          counts.update(
            item.kind.name,
            (value) => value + 1,
            ifAbsent: () => 1,
          );
        }
        return AlertDialog(
          title: const Text('Dependency Analysis'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${entity.data['name'] ?? entity.id} affects:'),
              if (counts.isEmpty) const Text('No dependent entities.'),
              for (final entry in counts.entries)
                Text('${entry.value} ${entry.key}'),
              const SizedBox(height: 12),
              const Text(
                'Deleted entities are moved to the Project Recycle Bin.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'cancel'),
              child: const Text('Cancel'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pop(context, 'only'),
              child: const Text('Delete only this entity'),
            ),
            if (impacted.isNotEmpty)
              FilledButton(
                onPressed: () => Navigator.pop(context, 'all'),
                child: const Text('Delete all affected'),
              ),
          ],
        );
      },
    );
    operational.clearDeletionPreview();
    if (choice == 'only' || choice == 'all') {
      await operational.deleteToRecycleBin(
        entity.id,
        includeDependencies: choice == 'all',
      );
    }
  }

  Widget _documentExplorer(BuildContext context) {
    final entities =
        widget.cad.runtime.document?.entities.values.toList() ?? [];
    final world = entities
        .where((entity) => entity.data['group'] == 'World Coordinate System')
        .toList();
    final groups = <String, List<CadDocumentEntity>>{
      'Collections': entities
          .where(
            (entity) =>
                entity.kind == CadDocumentEntityKind.collection &&
                entity.data['deleted'] != true,
          )
          .toList(),
      'Meshes': entities
          .where(
            (entity) =>
                entity.kind == CadDocumentEntityKind.import &&
                entity.data['deleted'] != true,
          )
          .toList(),
      'References': entities
          .where(
            (entity) =>
                entity.kind == CadDocumentEntityKind.reference &&
                entity.data['deleted'] != true &&
                entity.data['group'] != 'World Coordinate System' &&
                entity.data['sceneKind'] != 'coordinateSystem',
          )
          .toList(),
      'Coordinate Systems': entities
          .where(
            (entity) =>
                entity.kind == CadDocumentEntityKind.reference &&
                entity.data['deleted'] != true &&
                entity.data['group'] != 'World Coordinate System' &&
                entity.data['sceneKind'] == 'coordinateSystem',
          )
          .toList(),
      'Curves': entities
          .where(
            (entity) =>
                entity.kind == CadDocumentEntityKind.curve &&
                entity.data['deleted'] != true,
          )
          .toList(),
      'Vertices': entities
          .where(
            (entity) =>
                entity.kind == CadDocumentEntityKind.vertex &&
                entity.data['deleted'] != true,
          )
          .toList(),
      'Edges': entities
          .where(
            (entity) =>
                entity.kind == CadDocumentEntityKind.edge &&
                entity.data['deleted'] != true,
          )
          .toList(),
      'Wires': entities
          .where(
            (entity) =>
                entity.kind == CadDocumentEntityKind.wire &&
                entity.data['deleted'] != true,
          )
          .toList(),
      'Faces': entities
          .where(
            (entity) =>
                entity.kind == CadDocumentEntityKind.face &&
                entity.data['deleted'] != true,
          )
          .toList(),
      'Sketches': entities
          .where(
            (entity) =>
                entity.kind == CadDocumentEntityKind.sketch &&
                entity.data['deleted'] != true &&
                entity.data['sketch'] is Map,
          )
          .toList(),
      'Sections': entities
          .where(
            (entity) =>
                entity.kind == CadDocumentEntityKind.section &&
                entity.data['deleted'] != true,
          )
          .toList(),
      'Surfaces': entities
          .where(
            (entity) =>
                entity.kind == CadDocumentEntityKind.surface &&
                entity.data['deleted'] != true,
          )
          .toList(),
      'Bodies': entities
          .where(
            (entity) =>
                (entity.kind == CadDocumentEntityKind.import ||
                    entity.kind == CadDocumentEntityKind.solid) &&
                entity.data['deleted'] != true &&
                entity.shape != null,
          )
          .toList(),
      'Shells': entities
          .where(
            (entity) =>
                entity.kind == CadDocumentEntityKind.shell &&
                entity.data['deleted'] != true,
          )
          .toList(),
      'Recycle Bin': entities
          .where((entity) => entity.data['deleted'] == true)
          .toList(),
    };
    Widget row(CadDocumentEntity entity) {
      final collection = entity.kind == CadDocumentEntityKind.collection;
      final deleted = entity.data['deleted'] == true;
      final visible = entity.data['sceneVisible'] as bool? ?? true;
      final name = entity.data['name'] as String? ?? entity.id;
      return ListTile(
        dense: true,
        selected: scene.find(entity.id)?.selected ?? false,
        leading: Icon(
          collection
              ? entity.id == 'collection:recycle-bin'
                    ? Icons.delete_outline
                    : Icons.folder_copy_outlined
              : switch (entity.data['sceneKind']) {
                  'plane' => Icons.crop_16_9,
                  'axis' => Icons.straighten,
                  'point' => Icons.adjust,
                  'coordinateSystem' => Icons.threed_rotation,
                  'sketch' => Icons.gesture,
                  'surface' => Icons.layers,
                  'curve' when entity.kind == CadDocumentEntityKind.section =>
                    Icons.polyline,
                  'curve' => Icons.gesture,
                  'mesh' => Icons.grid_on,
                  _ => Icons.category_outlined,
                },
        ),
        trailing: collection
            ? PopupMenuButton<String>(
                onSelected: (action) async {
                  switch (action) {
                    case 'visibility':
                      await widget.cad.runtime.updateCollection(
                        entity.id,
                        visible: !(entity.data['visible'] as bool? ?? true),
                      );
                    case 'lock':
                      await widget.cad.runtime.updateCollection(
                        entity.id,
                        locked: !(entity.data['locked'] as bool? ?? false),
                      );
                    case 'active':
                      await widget.cad.runtime.updateCollection(
                        entity.id,
                        active: true,
                      );
                    case 'duplicate':
                      await widget.cad.runtime.duplicateCollection(entity.id);
                    case 'delete':
                      await _confirmDelete(entity);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'visibility',
                    child: Text('Show/Hide'),
                  ),
                  const PopupMenuItem(
                    value: 'lock',
                    child: Text('Lock/Unlock'),
                  ),
                  const PopupMenuItem(
                    value: 'active',
                    child: Text('Make Active'),
                  ),
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Text('Duplicate'),
                  ),
                  if (entity.data['systemCollection'] != true)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Move to Recycle Bin'),
                    ),
                ],
              )
            : deleted
            ? PopupMenuButton<String>(
                onSelected: (action) async {
                  if (action == 'restore') {
                    await operational.restoreDeleted(entity.id);
                  } else if (action == 'purge') {
                    await operational.permanentlyDelete(entity.id);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'restore', child: Text('Restore')),
                  PopupMenuItem(
                    value: 'purge',
                    child: Text('Delete Permanently'),
                  ),
                ],
              )
            : PopupMenuButton<String>(
                onSelected: (action) async {
                  if (action == 'visibility') {
                    if (entity.kind == CadDocumentEntityKind.sketch &&
                        entity.data['sketch'] is Map) {
                      operational.selectSketch(entity.id);
                      await operational.toggleActiveSketchVisibility();
                    } else {
                      await widget.cad.runtime.setEntityVisibility(
                        entity.id,
                        !visible,
                      );
                    }
                  } else if (action == 'delete') {
                    await _confirmDelete(entity);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'visibility',
                    child: Text(visible ? 'Hide' : 'Show'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Move to Recycle Bin'),
                  ),
                ],
              ),
        title: Text(name),
        onLongPress: entity.kind != CadDocumentEntityKind.section && !collection
            ? null
            : () async {
                final controller = TextEditingController(text: name);
                final replacement = await showDialog<String>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Rename Section'),
                    content: TextField(controller: controller, autofocus: true),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () =>
                            Navigator.pop(context, controller.text),
                        child: const Text('Rename'),
                      ),
                    ],
                  ),
                );
                controller.dispose();
                if (replacement != null && replacement.trim().isNotEmpty) {
                  if (collection) {
                    await widget.cad.runtime.updateCollection(
                      entity.id,
                      name: replacement,
                    );
                  } else {
                    await operational.sections.rename(entity.id, replacement);
                  }
                }
              },
        onTap: collection
            ? null
            : () {
                geometrySelection.select(entity.id);
                if (entity.data['sceneKind'] == 'plane') {
                  operational.selectDocumentPlane(entity.id);
                } else if (entity.kind == CadDocumentEntityKind.sketch &&
                    entity.data['sketch'] is Map) {
                  operational.selectSketch(entity.id);
                }
              },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExpansionTile(
          initiallyExpanded: true,
          leading: const Icon(Icons.public),
          title: const Text('World Coordinate System'),
          children: world.map(row).toList(),
        ),
        for (final entry in groups.entries)
          ExpansionTile(
            title: Text(entry.key),
            children: entry.value.isEmpty
                ? [const ListTile(dense: true, title: Text('Empty'))]
                : entry.value.map(row).toList(),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.escape): () {
        operational.previewPoints = const [];
        operational.cancelProfessionalSurface();
        widget.cad.setStatus('Sketch command cancelled.');
      },
      const SingleActivator(LogicalKeyboardKey.enter): () {
        if (operational.professionalSurfacePreview != null &&
            !operational.busy) {
          operational.confirmProfessionalSurface();
        } else {
          widget.cad.setStatus('Sketch command confirmed.');
        }
      },
      const SingleActivator(LogicalKeyboardKey.delete): () {
        final ids = operational.selectedSketchEntityIds;
        if (ids.isNotEmpty) {
          operational.editorApi?.edit(SketchToolType.delete, ids);
          operational.selectedSketchEntityIds.clear();
          widget.cad.setStatus('Sketch selection removed.');
        }
      },
      const SingleActivator(LogicalKeyboardKey.keyZ, control: true):
          operational.undo,
      const SingleActivator(LogicalKeyboardKey.keyY, control: true):
          operational.redo,
      const SingleActivator(LogicalKeyboardKey.space): () {
        operational.selectSketchTool(operational.activeTool);
        widget.cad.setStatus(
          'Repeated ${operational.activeTool.name} command.',
        );
      },
    },
    child: Focus(
      autofocus: true,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          widget.cad,
          modelingViewport,
          operational,
          geometrySelection,
        ]),
        builder: (context, _) => Column(
          children: [
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final item in modules)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: ChoiceChip(
                        label: Text(item),
                        selected: module == item,
                        onSelected: (_) async {
                          await widget.commands.dispatch(
                            'workspace.${item.toLowerCase().replaceAll(' ', '_')}',
                          );
                          if (mounted) setState(() => module = item);
                        },
                      ),
                    ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: Row(
                children: [
                  SizedBox(
                    width: 240,
                    child: _WorkspacePanel(
                      title: 'Explorer',
                      icon: Icons.account_tree,
                      child: module == 'Recognition'
                          ? RecognitionWorkspacePanel(
                              controller: operational,
                              onApplyAlignment: _applyAlignment,
                            )
                          : module == 'Sketch & Surface'
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SketchSurfaceWorkspacePanel(
                                  controller: operational,
                                  onOpenSketch: _openSketch,
                                  onFinishSketch: _finishSketch,
                                ),
                                _g106bCertificationPanel(),
                                const Divider(),
                                _documentExplorer(context),
                              ],
                            )
                          : module == 'Sections'
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _sectionTools(),
                                const Divider(),
                                _documentExplorer(context),
                              ],
                            )
                          : module == 'Transform'
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _transformTools(),
                                const Divider(),
                                _documentExplorer(context),
                              ],
                            )
                          : widget.cad.runtime.document == null
                          ? const _EmptyState(
                              icon: Icons.folder_outlined,
                              message:
                                  'Open a project to populate the engineering tree.',
                            )
                          : _documentExplorer(context),
                    ),
                  ),
                  const VerticalDivider(),
                  Expanded(
                    child: IntegratedCadViewportWidget(
                      scene: scene,
                      camera: camera,
                      showSketchGrid:
                          module == 'Sketch & Surface' &&
                          operational.stage == SketchSurfaceStage.sketchActive,
                      onSketchTap:
                          module == 'Sketch & Surface' &&
                              operational.stage ==
                                  SketchSurfaceStage.sketchActive
                          ? (position) =>
                                operational.captureSketchTap(position, camera)
                          : null,
                      onPick: widget.cad.document == null
                          ? null
                          : (pick) async {
                              geometrySelection.select(
                                pick.entityId,
                                toggle:
                                    HardwareKeyboard.instance.isControlPressed,
                                range: HardwareKeyboard.instance.isShiftPressed,
                              );
                              selectDocument();
                              final picked = widget
                                  .cad
                                  .runtime
                                  .document
                                  ?.entities[pick.entityId];
                              if (picked?.mesh != null) {
                                await operational.recognizePick(pick: pick);
                              } else {
                                operational.activePick = pick;
                              }
                            },
                    ),
                  ),
                  const VerticalDivider(),
                  SizedBox(
                    width: 280,
                    child: _WorkspacePanel(
                      title: 'Property Inspector',
                      icon: Icons.tune,
                      child: module == 'Sketch & Surface'
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('State: ${operational.stage.name}'),
                                Text(
                                  'Sketch entities: ${operational.sketchEntities.length}',
                                ),
                                Text(
                                  'Constraints: ${operational.constraints.length}',
                                ),
                                if (operational.surfacePlan != null)
                                  Text(
                                    'Surface quality: ${(operational.surfacePlan!.candidates.first.quality * 100).toStringAsFixed(1)}%',
                                  ),
                                if (operational.activeSurface != null) ...[
                                  Text(
                                    'Continuity: ${operational.activeSurface!.continuity.name}',
                                  ),
                                  Text(
                                    'Confidence: ${(operational.activeSurface!.confidence * 100).toStringAsFixed(1)}%',
                                  ),
                                  Text(
                                    'Kernel shape: ${operational.activeSurface!.handle.persistentId}',
                                  ),
                                ],
                                if (operational.professionalSurfacePreview !=
                                    null) ...[
                                  const Divider(),
                                  const Text(
                                    'Surface Edit Preview',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Operation: ${operational.professionalSurfacePreview!.definition.tool.name}',
                                  ),
                                  Text(
                                    'Status: ${operational.professionalSurfacePreview!.definition.status.name}',
                                  ),
                                  Text(
                                    'Inputs: ${operational.professionalSurfacePreview!.definition.references.length}',
                                  ),
                                  Text(
                                    'Transient ShapeHandle: ${operational.professionalSurfacePreview!.definition.handle?.persistentId ?? '-'}',
                                  ),
                                  const Text(
                                    'Document impact: none until Apply',
                                  ),
                                  const Text(
                                    'Cancel discards the complete preview.',
                                  ),
                                  for (final parameter
                                      in operational
                                          .professionalSurfacePreview!
                                          .definition
                                          .parameters
                                          .entries
                                          .where(
                                            (entry) =>
                                                entry.key != 'shapeHandles' &&
                                                entry.key != 'sourceEntityIds',
                                          ))
                                    Text(
                                      '${parameter.key}: ${parameter.value}',
                                    ),
                                ],
                                if (operational
                                    .professionalSurfaceValidationCompleted) ...[
                                  const Divider(),
                                  const Text(
                                    'BRep Validation',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (operational
                                      .professionalSurfaceValidation
                                      .isEmpty)
                                    const Text(
                                      'Valid: BRepCheck reported no errors.',
                                    )
                                  else
                                    for (final diagnostic
                                        in operational
                                            .professionalSurfaceValidation)
                                      Text(diagnostic),
                                ],
                                if (operational
                                        .professionalSurfaceOperationReport
                                    case final report?) ...[
                                  const Divider(),
                                  const Text(
                                    'Operation Result',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text('State: ${report['state']}'),
                                  Text(
                                    'Affected entities: ${report['affectedEntities']}',
                                  ),
                                  Text(
                                    'Boundaries/loops: ${report['boundaries']}/${report['loops']}',
                                  ),
                                  Text('Tolerance: ${report['tolerance']}'),
                                  for (final entry in report.entries.where(
                                    (entry) => !const {
                                      'operation',
                                      'state',
                                      'affectedEntities',
                                      'boundaries',
                                      'loops',
                                      'tolerance',
                                      'diagnostics',
                                      'result',
                                    }.contains(entry.key),
                                  ))
                                    Text('${entry.key}: ${entry.value}'),
                                  Text('Final diagnostic: ${report['result']}'),
                                ],
                              ],
                            )
                          : module == 'Transform'
                          ? Builder(
                              builder: (context) {
                                final selected = geometrySelection.selectedIds;
                                if (selected.isEmpty) {
                                  return const Text(
                                    'Select an entity to transform.',
                                  );
                                }
                                final entity = widget
                                    .cad
                                    .runtime
                                    .document
                                    ?.entities[selected.first];
                                final matrix = entity?.data['transformMatrix'];
                                final collectionId =
                                    entity?.data['collectionId'] as String?;
                                final collection = collectionId == null
                                    ? null
                                    : widget
                                          .cad
                                          .runtime
                                          .document
                                          ?.entities[collectionId];
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entity?.data['name'] as String? ??
                                          entity?.id ??
                                          '-',
                                    ),
                                    Text('Type: ${entity?.kind.name ?? '-'}'),
                                    Text('Selected: ${selected.length}'),
                                    Text(
                                      'Collection: ${collection?.data['name'] ?? '-'}',
                                    ),
                                    Text(
                                      'Position/rotation/scale: ${matrix is List ? 'transformed' : 'identity'}',
                                    ),
                                    Text(
                                      'Active system: ${operational.manualTransformMode?.name ?? 'World'}',
                                    ),
                                    if (entity?.shape != null)
                                      const Text('Native BRep transform: OCCT'),
                                  ],
                                );
                              },
                            )
                          : module == 'Sections'
                          ? Builder(
                              builder: (context) {
                                final entity = operational.selectedSection;
                                final section = entity?.data['section'];
                                if (section is! Map) {
                                  final sketch = operational.activeSketch;
                                  if (sketch == null) {
                                    return const Text(
                                      'Select a Section or associated Sketch.',
                                    );
                                  }
                                  final metadata = sketch.metadata;
                                  String metric(String key) =>
                                      ((metadata[key] as num?) ?? 0)
                                          .toDouble()
                                          .toStringAsFixed(6);
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(sketch.name),
                                      Text(
                                        'Entities: ${sketch.entityIds.length}',
                                      ),
                                      Text(
                                        'Points: ${metadata['pointCount'] ?? 0}',
                                      ),
                                      Text(
                                        'Segments: ${metadata['segmentCount'] ?? 0}',
                                      ),
                                      Text(
                                        'Maximum error: ${metric('maximumError')} mm',
                                      ),
                                      Text(
                                        'Mean error: ${metric('meanError')} mm',
                                      ),
                                      Text(
                                        'Tolerance: ${metric('tolerance')} mm',
                                      ),
                                      Text(
                                        'Association: ${metadata['associationState'] ?? 'detached'}',
                                      ),
                                      Text(
                                        'Updated: ${metadata['lastUpdatedAt'] ?? '-'}',
                                      ),
                                    ],
                                  );
                                }
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(entity!.data['name'] as String),
                                    Text(
                                      'Segments: ${section['segmentCount']}',
                                    ),
                                    Text('Loops: ${section['loopCount']}'),
                                    Text(
                                      'Length: ${(section['length'] as num).toStringAsFixed(3)} mm',
                                    ),
                                    Text('Closed: ${section['closed']}'),
                                    Text(
                                      'Projected area: ${(section['projectedArea'] as num).toStringAsFixed(3)} mm²',
                                    ),
                                    Text(
                                      'Tolerance: ${section['toleranceUsed']}',
                                    ),
                                    const SizedBox(height: 8),
                                    FilledButton.tonalIcon(
                                      icon: const Icon(Icons.delete_outline),
                                      label: const Text('Delete Section'),
                                      onPressed: () => _sectionAction(
                                        () => operational.sections.remove(
                                          entity.id,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            )
                          : module == 'Recognition'
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Alignment guidance'),
                                if (operational.activeReference == null)
                                  const Text(
                                    'Accept a planar hypothesis and create its official reference.',
                                  )
                                else ...[
                                  const Text(
                                    'Deseja criar um Sistema de Coordenadas utilizando essas referências?',
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Deseja alinhar a peça utilizando este sistema?',
                                  ),
                                  if (operational.alignmentTransform != null)
                                    Text(
                                      'Preview ativo: plano → ${operational.alignmentTarget}. Confirme somente após revisar a posição final.',
                                    ),
                                ],
                              ],
                            )
                          : modelingViewport.selection.isEmpty
                          ? const _EmptyState(
                              icon: Icons.touch_app_outlined,
                              message:
                                  'Select an engineering object to inspect its properties.',
                            )
                          : ModelingPropertyInspector(
                              context: InteractionContext(
                                stage: InteractionStage.selected,
                                selection: modelingViewport.selection,
                                message: 'Selection synchronized',
                              ),
                              onParameterChanged: (key, value) =>
                                  widget.cad.setStatus(
                                    'Parameter $key updated to $value.',
                                  ),
                            ),
                    ),
                  ),
                  const VerticalDivider(),
                  SizedBox(
                    width: 300,
                    child: _WorkspacePanel(
                      title: 'Engineering Assistant',
                      icon: Icons.psychology_outlined,
                      child: module == 'Sketch & Surface'
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Certified operational guidance'),
                                Text(switch (operational.stage) {
                                  SketchSurfaceStage.idle =>
                                    'Accept a planar Recognition hypothesis before creating a reference.',
                                  SketchSurfaceStage.referenceReady =>
                                    'The approved reference is ready for a Sketch session.',
                                  SketchSurfaceStage.sketchActive =>
                                    'Capture the profile points and review constraints before finishing.',
                                  SketchSurfaceStage.sketchFinished =>
                                    'The profile is persisted and ready for surface planning.',
                                  SketchSurfaceStage.surfacePreview =>
                                    'Review quality and continuity evidence before confirmation.',
                                  SketchSurfaceStage.surfaceGenerated =>
                                    'The CAD kernel generated and validated the surface.',
                                }),
                                if (operational.stage ==
                                    SketchSurfaceStage.sketchActive) ...[
                                  const SizedBox(height: 8),
                                  for (final recommendation
                                      in operational
                                              .editorApi
                                              ?.recommendations ??
                                          const [])
                                    ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      leading: const Icon(
                                        Icons.lightbulb_outline,
                                        size: 17,
                                      ),
                                      title: Text(recommendation.title),
                                      subtitle: Text(recommendation.reason),
                                    ),
                                  const Text('Suggestions'),
                                  const Text('• Simplify the fitted spline'),
                                  const Text('• Complete useful constraints'),
                                  if (operational
                                          .activeSketch
                                          ?.metadata['associationState'] ==
                                      'outdated')
                                    const Text(
                                      '• Update the associated Sketch',
                                    ),
                                  const Text(
                                    '• Prepare profile for Loft or Sweep',
                                  ),
                                ],
                                if (operational.surfacePlan != null)
                                  for (final evidence
                                      in operational
                                          .surfacePlan!
                                          .candidates
                                          .first
                                          .evidence)
                                    Text('• ${evidence.description}'),
                                if (operational.professionalSurfacePreview !=
                                    null) ...[
                                  const Divider(),
                                  const Text(
                                    'Surface editing guidance',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Preview ${operational.professionalSurfacePreview!.definition.tool.name} is transient. Inspect the viewport before Apply.',
                                  ),
                                  Text(switch (operational
                                      .professionalSurfacePreview!
                                      .definition
                                      .tool) {
                                    ProfessionalSurfaceTool.offset =>
                                      'Check offset direction, self-intersections and boundary changes.',
                                    ProfessionalSurfaceTool.offsetWalls =>
                                      'Review Offset mode, Inside/Outside/Bilateral direction, every Wall/Open boundary choice and the real topological result before Apply.',
                                    ProfessionalSurfaceTool.extend =>
                                      'Check the extended side, length and continuity.',
                                    ProfessionalSurfaceTool.boundaryExtend =>
                                      'Review the selected boundary, side, extension length or target, and continuity before Apply.',
                                    ProfessionalSurfaceTool.trim ||
                                    ProfessionalSurfaceTool.split =>
                                      'Confirm which region will remain after the cut.',
                                    ProfessionalSurfaceTool.boundaryTrim =>
                                      'Confirm the region identified by the yellow Keep Point; ambiguous or open regions must not be applied.',
                                    ProfessionalSurfaceTool.match =>
                                      'Compare requested G0/G1/G2 tolerances with the kernel validation before Apply.',
                                    ProfessionalSurfaceTool.blend =>
                                      'Review radius, support faces, consumed regions and continuity before Apply.',
                                    ProfessionalSurfaceTool.heal =>
                                      'Review every topology correction proposed by ShapeFix.',
                                    ProfessionalSurfaceTool.healLocal =>
                                      'Review the local ShapeFix proposal, before/after gaps and every directly affected adjacent entity.',
                                    ProfessionalSurfaceTool.replaceFace =>
                                      'Create a Working Copy when appropriate and inspect every replacement-boundary mismatch.',
                                    ProfessionalSurfaceTool.deleteFace =>
                                      'Review dependencies and the open Shell that will remain. Delete Face never fills implicitly.',
                                    ProfessionalSurfaceTool.unsewFace ||
                                    ProfessionalSurfaceTool.unsewSelected ||
                                    ProfessionalSurfaceTool.unsewAll =>
                                      'Review every new open boundary and resulting independent Face group before Apply.',
                                    ProfessionalSurfaceTool.mergeFaces =>
                                      'Confirm only same-domain faces are consolidated.',
                                    ProfessionalSurfaceTool.join =>
                                      'Review sewing tolerance and remaining open boundaries.',
                                    _ =>
                                      'Review geometry and topology before committing.',
                                  }),
                                  const Text(
                                    'Apply persists the result. Cancel preserves the current document.',
                                  ),
                                ],
                                if (operational
                                        .professionalSurfaceOperationReport
                                    case final report?) ...[
                                  const Divider(),
                                  Text(switch (report['result']) {
                                    'Critical' =>
                                      'Critical: do not apply before correcting the reported topology errors.',
                                    'Attention' =>
                                      'Attention: review boundaries and tolerances before Apply.',
                                    _ =>
                                      'OK: OCCT validation found no critical result problem.',
                                  }),
                                  Text(
                                    '${report['affectedEntities']} input entity/entities affected · tolerance ${report['tolerance']}.',
                                  ),
                                ],
                              ],
                            )
                          : module == 'Transform'
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Manual transform guidance'),
                                Text(
                                  operational.transformDisposition == null
                                      ? 'Transform Original or Create Working Copy?'
                                      : operational.manualTransformPreview ==
                                            null
                                      ? 'Select geometry and create a preview. The document is unchanged until Apply.'
                                      : 'Deseja aplicar esta transformação permanentemente?',
                                ),
                                if (operational.transformDisposition ==
                                    TransformDisposition.original)
                                  const Text(
                                    'The Original will move to the Modified Collection.',
                                  ),
                                if (operational.transformDisposition ==
                                    TransformDisposition.workingCopy)
                                  const Text(
                                    'The Original remains intact and a new Working Copy Collection will be created.',
                                  ),
                                if (operational.manualTransformMode ==
                                    ManualTransformMode.align)
                                  const Text(
                                    'Deseja criar um novo Sistema de Coordenadas baseado nesta posição?',
                                  ),
                              ],
                            )
                          : module == 'Sections'
                          ? Builder(
                              builder: (context) {
                                final data = operational
                                    .selectedSection
                                    ?.data['section'];
                                if (data is! Map) {
                                  final sketch = operational.activeSketch;
                                  if (sketch == null) {
                                    return const Text(
                                      'Select a plane and create a Section, then convert it to a Sketch.',
                                    );
                                  }
                                  final metadata = sketch.metadata;
                                  final outdated =
                                      metadata['associationState'] ==
                                      'outdated';
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Section converted successfully.',
                                      ),
                                      Text(
                                        'Maximum error: ${((metadata['maximumError'] as num?) ?? 0).toStringAsFixed(6)} mm',
                                      ),
                                      Text(
                                        'Mean error: ${((metadata['meanError'] as num?) ?? 0).toStringAsFixed(6)} mm',
                                      ),
                                      Text(
                                        'Entities: ${metadata['entityCount'] ?? sketch.entityIds.length}',
                                      ),
                                      Text(
                                        outdated
                                            ? 'The source Section changed. Do you want to update this Sketch?'
                                            : 'Association with Section is active.',
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Do you want to start editing the Sketch?',
                                      ),
                                    ],
                                  );
                                }
                                final quality =
                                    (data['degenerations'] as int) == 0 &&
                                        (data['nonManifoldEdges'] as int) == 0
                                    ? 'Good'
                                    : 'Review';
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Segments: ${data['segmentCount']}'),
                                    Text('Loops: ${data['loopCount']}'),
                                    Text(
                                      'Length: ${(data['length'] as num).toStringAsFixed(3)} mm',
                                    ),
                                    Text('Quality: $quality'),
                                    Text(
                                      'Candidates: ${data['candidateTriangles']} triangles',
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Deseja converter esta Section em Sketch?',
                                    ),
                                    const Text(
                                      'Choose Polyline or Best Fit Spline.',
                                    ),
                                  ],
                                );
                              },
                            )
                          : modelingViewport.selection.isEmpty
                          ? const _EmptyState(
                              icon: Icons.chat_bubble_outline,
                              message:
                                  'Assistant guidance appears when project evidence is available.',
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Selected evidence'),
                                for (final evidence
                                    in modelingViewport
                                        .selection
                                        .first
                                        .evidence)
                                  Text('• $evidence'),
                                const SizedBox(height: 8),
                                const Text(
                                  'No operation will execute until a preview is reviewed and explicitly accepted.',
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.cad.busy)
              LinearProgressIndicator(value: widget.cad.progress),
            if (widget.cad.message != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(widget.cad.message!),
                ),
              ),
            Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 16),
                  SizedBox(width: 6),
                  Text('Ready'),
                  Spacer(),
                  Text('OpenCascade · Project First · Consultative AI'),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _WorkspacePanel extends StatelessWidget {
  const _WorkspacePanel({
    required this.title,
    required this.icon,
    required this.child,
  });
  final String title;
  final IconData icon;
  final Widget child;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ],
        ),
      ),
      const Divider(),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(10),
          child: child,
        ),
      ),
    ],
  );
}

class DesktopSettingsScreen extends StatefulWidget {
  const DesktopSettingsScreen({super.key, required this.controller});
  final DesktopSettingsController controller;
  @override
  State<DesktopSettingsScreen> createState() => _DesktopSettingsScreenState();
}

class _DesktopSettingsScreenState extends State<DesktopSettingsScreen> {
  late final directory = TextEditingController(
    text: widget.controller.settings.defaultDirectory,
  );
  @override
  void dispose() {
    directory.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.settings;
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 24),
        DropdownButtonFormField<String>(
          initialValue: value.language,
          decoration: const InputDecoration(labelText: 'Language'),
          items: const [
            DropdownMenuItem(value: 'pt-BR', child: Text('Português (Brasil)')),
            DropdownMenuItem(value: 'en-US', child: Text('English')),
          ],
          onChanged: (item) {
            if (item != null) {
              widget.controller.update(value.copyWith(language: item));
            }
          },
        ),
        const SizedBox(height: 16),
        SegmentedButton<DesktopThemePreference>(
          segments: const [
            ButtonSegment(
              value: DesktopThemePreference.dark,
              label: Text('Dark'),
              icon: Icon(Icons.dark_mode),
            ),
            ButtonSegment(
              value: DesktopThemePreference.light,
              label: Text('Light'),
              icon: Icon(Icons.light_mode),
            ),
          ],
          selected: {value.theme},
          onSelectionChanged: (selection) =>
              widget.controller.update(value.copyWith(theme: selection.single)),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: directory,
          decoration: const InputDecoration(
            labelText: 'Default project directory',
          ),
        ),
        const SizedBox(height: 10),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Engineering tips'),
          value: value.engineeringTips,
          onChanged: (enabled) => widget.controller.update(
            value.copyWith(engineeringTips: enabled),
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: () => widget.controller.update(
              value.copyWith(defaultDirectory: directory.text.trim()),
            ),
            icon: const Icon(Icons.save),
            label: const Text('Save settings'),
          ),
        ),
      ],
    );
  }
}

class AboutFLCADDialog extends StatelessWidget {
  const AboutFLCADDialog({super.key});
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Row(
      children: [
        Image.asset(DesktopAssets.logo, width: 48, height: 48),
        const SizedBox(width: 12),
        const Text('FLCAD Reverse AI'),
      ],
    ),
    content: const SizedBox(
      width: 440,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Engineering Intelligence Platform'),
          SizedBox(height: 16),
          _AboutRow('Version', '0.9.1 Alpha'),
          _AboutRow('Company', 'FLCAD MODEL'),
          _AboutRow('GitHub', 'github.com/FLCAD-MODEL'),
          _AboutRow('License', 'Project license'),
          _AboutRow('Geometry Kernel', 'OpenCascade'),
          _AboutRow('UI Framework', 'Flutter'),
          SizedBox(height: 12),
          Text('Copyright © 2026 FLCAD MODEL. All rights reserved.'),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Close'),
      ),
    ],
  );
}

class _AboutRow extends StatelessWidget {
  const _AboutRow(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(label, style: Theme.of(context).textTheme.labelMedium),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}
