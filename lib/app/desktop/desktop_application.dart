import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/cad_kernel/manager/kernel_manager.dart';
import '../../core/geometric_kernel/geometry/vectors.dart';
import '../../core/professional_recognition/api/professional_recognition_api.dart';
import '../../features/projects/domain/project_manager.dart';
import '../../features/projects/models/project.dart';
import '../bootstrap/app_bootstrap.dart';
import '../bootstrap/engineering_bootstrap.dart';
import '../cad_viewport/camera/cad_camera_controller.dart';
import '../cad_viewport/professional_cad_viewport_widget.dart';
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
    commands.initialize();
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

class DesktopHomeDashboard extends StatelessWidget {
  const DesktopHomeDashboard({
    super.key,
    required this.onWorkspace,
    required this.controller,
    required this.commands,
  });
  final VoidCallback onWorkspace;
  final DesktopSettingsController controller;
  final DesktopCommandCoordinator commands;

  Future<void> _newProject(BuildContext context) async {
    final name = TextEditingController();
    final client = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Project'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Project name'),
            ),
            TextField(
              controller: client,
              decoration: const InputDecoration(labelText: 'Client'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (accepted == true && name.text.trim().isNotEmpty) {
      await commands.createProject(name.text.trim(), client.text.trim());
      onWorkspace();
    }
    name.dispose();
    client.dispose();
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
    return ListView(
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
            message: 'No recent projects. Open or create a project to begin.',
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
    );
  }
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
  static const modules = ['AI Engineering', 'Recognition', 'Sketch & Surface'];
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

  void _synchronizeScene() {
    final document = widget.cad.document;
    if (document == null) {
      operational.detachProject();
      fittedDocumentId = null;
      return;
    }
    unawaited(
      widget.commands.repository
          .directoryFor(document.projectId)
          .then(
            (directory) => operational.configureProject(
              projectId: document.projectId,
              projectDirectory: directory,
            ),
          ),
    );
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

  @override
  void dispose() {
    widget.cad.removeListener(_synchronizeScene);
    operational.dispose();
    camera.dispose();
    modelingViewport.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
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
                      ? RecognitionWorkspacePanel(controller: operational)
                      : module == 'Sketch & Surface'
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SketchSurfaceWorkspacePanel(
                              controller: operational,
                            ),
                            const Divider(),
                            Text(
                              'Scene',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            for (final entity in scene.entities)
                              ListTile(
                                dense: true,
                                selected: entity.selected,
                                onTap: () {
                                  geometrySelection.select(
                                    entity.id,
                                    toggle: HardwareKeyboard
                                        .instance
                                        .isControlPressed,
                                    range: HardwareKeyboard
                                        .instance
                                        .isShiftPressed,
                                  );
                                  if (entity.kind ==
                                      CadSceneEntityKind.sketch) {
                                    operational.toggleSketchSelection(
                                      entity.id,
                                    );
                                  }
                                },
                                leading: Icon(switch (entity.kind) {
                                  CadSceneEntityKind.sketch => Icons.gesture,
                                  CadSceneEntityKind.surface => Icons.layers,
                                  CadSceneEntityKind.plane => Icons.crop_16_9,
                                  _ => Icons.category_outlined,
                                }),
                                title: Text(entity.id),
                                subtitle: Text(entity.kind.name),
                              ),
                          ],
                        )
                      : widget.cad.document == null
                      ? const _EmptyState(
                          icon: Icons.folder_outlined,
                          message:
                              'Open a project to populate the engineering tree.',
                        )
                      : ListTile(
                          selected: modelingViewport.selection.any(
                            (e) => e.id == widget.cad.document!.id,
                          ),
                          onTap: selectDocument,
                          leading: Icon(
                            widget.cad.document!.isMesh
                                ? Icons.grid_on
                                : Icons.view_in_ar,
                          ),
                          title: Text(
                            widget.cad.document!.sourcePath
                                .split(RegExp(r'[/\\]'))
                                .last,
                          ),
                          subtitle: Text(
                            widget.cad.document!.format.name.toUpperCase(),
                          ),
                        ),
                ),
              ),
              const VerticalDivider(),
              Expanded(
                child: ProfessionalCadViewportWidget(
                  scene: scene,
                  camera: camera,
                  showSketchGrid:
                      module == 'Sketch & Surface' &&
                      operational.stage == SketchSurfaceStage.sketchActive,
                  onSketchTap:
                      module == 'Sketch & Surface' &&
                          operational.stage == SketchSurfaceStage.sketchActive
                      ? (position) =>
                            operational.captureSketchTap(position, camera)
                      : null,
                  onPick: widget.cad.document == null
                      ? null
                      : (pick) async {
                          geometrySelection.select(
                            pick.entityId,
                            toggle: HardwareKeyboard.instance.isControlPressed,
                            range: HardwareKeyboard.instance.isShiftPressed,
                          );
                          selectDocument();
                          await operational.recognizePick(pick: pick);
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
                          onParameterChanged: (key, value) => widget.cad
                              .setStatus('Parameter $key updated to $value.'),
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
                            if (operational.surfacePlan != null)
                              for (final evidence
                                  in operational
                                      .surfacePlan!
                                      .candidates
                                      .first
                                      .evidence)
                                Text('• ${evidence.description}'),
                          ],
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
                                in modelingViewport.selection.first.evidence)
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
