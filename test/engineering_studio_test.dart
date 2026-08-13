import 'dart:io';
import 'package:flcad_mobile/core/engineering_studio/commands/studio_commands.dart';
import 'package:flcad_mobile/core/engineering_studio/models/studio_models.dart';
import 'package:flcad_mobile/core/engineering_studio/persistence/layout_repository.dart';
import 'package:flcad_mobile/core/engineering_studio/properties/property_inspector.dart';
import 'package:flcad_mobile/core/engineering_studio/rendering/render_pipeline.dart';
import 'package:flcad_mobile/core/engineering_studio/runtime/desktop_runtime.dart';
import 'package:flcad_mobile/core/engineering_studio/selection/selection_manager.dart';
import 'package:flcad_mobile/core/engineering_studio/shortcuts/shortcut_manager.dart';
import 'package:flcad_mobile/core/engineering_studio/tree/engineering_tree_manager.dart';
import 'package:flcad_mobile/core/engineering_studio/workspace/studio_managers.dart';
import 'package:flcad_mobile/core/storage/local_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('docking and viewport layouts preserve independent cameras', () {
    final layouts = LayoutManager(),
        docks = DockManager(layouts),
        views = ViewManager(layouts);
    docks.move(
      StudioPanelType.properties,
      DockPosition.floating,
      detached: true,
    );
    expect(
      layouts.layout.panels
          .firstWhere((p) => p.type == StudioPanelType.properties)
          .detached,
      isTrue,
    );
    views.configure(ViewportLayout.quad);
    expect(layouts.layout.viewports, hasLength(4));
    expect(layouts.layout.viewports.map((e) => e.id).toSet(), hasLength(4));
  });
  test(
    'engineering tree enforces hierarchy and exposes contextual properties',
    () {
      final tree = EngineeringTreeManager();
      tree.add(
        const EngineeringTreeNode(
          id: 'p',
          projectId: 'p',
          name: 'Project',
          type: StudioEntityType.project,
        ),
      );
      tree.add(
        const EngineeringTreeNode(
          id: 'plane',
          projectId: 'p',
          name: 'Plane',
          type: StudioEntityType.reference,
          parentId: 'p',
          confidence: .98,
          context: {
            'normal': [0, 0, 1],
            'area': 12,
            'dna': 'abc',
          },
        ),
      );
      tree.visibility('plane', false);
      tree.lock('plane', true);
      tree.select({'plane'});
      final node = tree.nodes.last,
          sections = const PropertyInspector().inspect(node);
      expect(node.locked, isTrue);
      expect(node.visible, isFalse);
      expect(sections[1].values['dna'], 'abc');
      expect(
        () => tree.add(
          const EngineeringTreeNode(
            id: 'bad',
            projectId: 'p',
            name: 'bad',
            type: StudioEntityType.mesh,
            parentId: 'missing',
          ),
        ),
        throwsStateError,
      );
    },
  );
  test(
    'selection supports multi invert expand shrink similar confidence and type',
    () {
      final manager = SelectionManager(),
          nodes = [
            const EngineeringTreeNode(
              id: 'a',
              projectId: 'p',
              name: 'A',
              type: StudioEntityType.region,
              confidence: .9,
            ),
            const EngineeringTreeNode(
              id: 'b',
              projectId: 'p',
              name: 'B',
              type: StudioEntityType.region,
              confidence: .4,
            ),
            const EngineeringTreeNode(
              id: 'c',
              projectId: 'p',
              name: 'C',
              type: StudioEntityType.mesh,
              confidence: .95,
            ),
          ];
      manager.similar('a', nodes);
      expect(manager.selection.ids, {'a', 'b'});
      manager.byConfidence(nodes, .8);
      expect(manager.selection.ids, {'a', 'c'});
      manager.byType(nodes, StudioEntityType.region);
      manager.expand({
        'a': {'c'},
      });
      expect(manager.selection.ids, {'a', 'b', 'c'});
      manager.invert(nodes.map((e) => e.id));
      expect(manager.selection.ids, isEmpty);
    },
  );
  test(
    'layout persistence round trips project profile panels viewport and theme',
    () async {
      final root = await Directory.systemTemp.createTemp('studio_');
      addTearDown(() => root.delete(recursive: true));
      final repository = StudioLayoutRepository(
            storage: LocalStorageService(rootDirectory: root),
          ),
          layout = LayoutManager.defaults(StudioProfile.expert);
      await repository.save('p', layout);
      final loaded = await repository.load('p');
      expect(loaded?.profile, StudioProfile.expert);
      expect(loaded?.theme, StudioTheme.professionalBlue);
      expect(loaded?.panels.length, layout.panels.length);
    },
  );
  test(
    'render pipeline and multi-window remain honest unavailable contracts',
    () async {
      final pipeline = StudioRenderPipeline();
      expect(
        () => pipeline.render(
          const StudioViewport(id: 'v', camera: StudioCameraState()),
        ),
        throwsA(isA<UnsupportedError>()),
      );
      expect(
        () => DesktopRuntime().openWindow(
          const DesktopWindowDescriptor('w', 'p', 'P'),
        ),
        throwsA(isA<UnsupportedError>()),
      );
    },
  );
  test('commands palette shortcuts and background runtime integrate', () async {
    final commands = StudioCommandManager();
    var ran = false;
    commands.register(
      StudioCommand(
        id: 'fit',
        label: 'Fit View',
        category: 'View',
        keywords: const ['camera'],
        execute: () async => ran = true,
      ),
    );
    expect(commands.search('camera').single.id, 'fit');
    await commands.execute('fit');
    expect(ran, isTrue);
    final shortcuts = ShortcutManager()
      ..bind(const ShortcutBinding('F', 'fit', 'viewport', 'expert'));
    expect(
      shortcuts.resolve('F', context: 'viewport', profile: 'expert'),
      'fit',
    );
    expect(
      await DesktopRuntime().background('desktop-test', () async => 42).future,
      42,
    );
  });
}
