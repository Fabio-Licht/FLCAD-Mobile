import 'package:flutter/material.dart';
import '../../../core/engineering_studio/commands/studio_commands.dart';
import '../../../core/engineering_studio/models/studio_models.dart';
import '../../../core/engineering_studio/properties/property_inspector.dart';
import '../../../core/engineering_studio/selection/selection_manager.dart';
import '../../../core/engineering_studio/tree/engineering_tree_manager.dart';
import '../../../core/engineering_studio/workspace/studio_managers.dart';
import '../../projects/models/project.dart';

class EngineeringStudioScreen extends StatefulWidget {
  const EngineeringStudioScreen({super.key, required this.project});
  final Project project;
  @override
  State<EngineeringStudioScreen> createState() =>
      _EngineeringStudioScreenState();
}

class _EngineeringStudioScreenState extends State<EngineeringStudioScreen> {
  final layouts = LayoutManager(),
      selection = SelectionManager(),
      tree = EngineeringTreeManager(),
      commands = StudioCommandManager();
  late final docks = DockManager(layouts), views = ViewManager(layouts);
  @override
  void initState() {
    super.initState();
    tree.add(
      EngineeringTreeNode(
        id: widget.project.id,
        projectId: widget.project.id,
        name: widget.project.name,
        type: StudioEntityType.project,
        context: {
          'origin': 'Project Manifest',
          'analytics': {'photos': widget.project.statistics.photoCount},
        },
      ),
    );
    for (final e in const [
      (StudioEntityType.mesh, 'Mesh'),
      (StudioEntityType.region, 'Smart Regions'),
      (StudioEntityType.reference, 'References'),
      (StudioEntityType.sketch, 'Sketches'),
      (StudioEntityType.surface, 'Surfaces'),
      (StudioEntityType.feature, 'Features'),
      (StudioEntityType.recognition, 'Recognition'),
      (StudioEntityType.workflow, 'Workflow'),
      (StudioEntityType.decision, 'Decision'),
      (StudioEntityType.analytics, 'Analytics'),
    ]) {
      tree.add(
        EngineeringTreeNode(
          id: '${widget.project.id}:${e.$1.name}',
          projectId: widget.project.id,
          name: e.$2,
          type: e.$1,
          parentId: widget.project.id,
          status: 'prepared',
          confidence: 0,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final layout = layouts.layout,
        selected = tree.nodes
            .where((n) => selection.selection.ids.contains(n.id))
            .firstOrNull;
    return Scaffold(
      backgroundColor: const Color(0xff10151d),
      body: SafeArea(
        child: Column(
          children: [
            _Toolbar(
              project: widget.project,
              onLayout: (value) => setState(() => views.configure(value)),
              onPalette: () => _palette(context),
            ),
            Expanded(
              child: Row(
                children: [
                  SizedBox(
                    width: 260,
                    child: _TreePanel(
                      nodes: tree.nodes,
                      selected: selection.selection.ids,
                      onSelect: (id) {
                        setState(() {
                          selection.select(id);
                          tree.select(selection.selection.ids);
                        });
                      },
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: _ViewportArea(layout: layout)),
                  const VerticalDivider(width: 1),
                  SizedBox(width: 300, child: _Properties(node: selected)),
                ],
              ),
            ),
            const _StatusBar(),
          ],
        ),
      ),
    );
  }

  Future<void> _palette(BuildContext context) async {
    await showSearch<void>(
      context: context,
      delegate: _PaletteDelegate(commands),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.project,
    required this.onLayout,
    required this.onPalette,
  });
  final Project project;
  final ValueChanged<ViewportLayout> onLayout;
  final VoidCallback onPalette;
  @override
  Widget build(BuildContext context) => Container(
    height: 48,
    color: const Color(0xff18212d),
    child: Row(
      children: [
        const SizedBox(width: 12),
        const Icon(Icons.architecture, color: Colors.lightBlueAccent),
        const SizedBox(width: 8),
        Text('FLCAD Engineering Studio — ${project.name}'),
        const Spacer(),
        IconButton(
          onPressed: onPalette,
          tooltip: 'Command Palette',
          icon: const Icon(Icons.search),
        ),
        PopupMenuButton<ViewportLayout>(
          tooltip: 'Viewport Layout',
          onSelected: onLayout,
          itemBuilder: (_) => ViewportLayout.values
              .map((e) => PopupMenuItem(value: e, child: Text(e.name)))
              .toList(),
        ),
        const SizedBox(width: 8),
      ],
    ),
  );
}

class _TreePanel extends StatelessWidget {
  const _TreePanel({
    required this.nodes,
    required this.selected,
    required this.onSelect,
  });
  final List<EngineeringTreeNode> nodes;
  final Set<String> selected;
  final ValueChanged<String> onSelect;
  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xff141b24),
    child: ListView(
      padding: const EdgeInsets.all(8),
      children: [
        const Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            'ENGINEERING TREE',
            style: TextStyle(fontSize: 11, color: Colors.blueGrey),
          ),
        ),
        for (final n in nodes)
          ListTile(
            dense: true,
            selected: selected.contains(n.id),
            contentPadding: EdgeInsets.only(
              left: n.parentId == null ? 8 : 24,
              right: 4,
            ),
            leading: Icon(
              n.type == StudioEntityType.project
                  ? Icons.folder
                  : Icons.account_tree,
              size: 18,
            ),
            title: Text(n.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  n.visible ? Icons.visibility : Icons.visibility_off,
                  size: 14,
                ),
                if (n.locked) const Icon(Icons.lock, size: 14),
              ],
            ),
            onTap: () => onSelect(n.id),
          ),
      ],
    ),
  );
}

class _ViewportArea extends StatelessWidget {
  const _ViewportArea({required this.layout});
  final StudioLayout layout;
  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: layout.viewportLayout == ViewportLayout.verticalSplit
        ? 1
        : layout.viewports.length >= 4
        ? 2
        : layout.viewports.length,
    children: [
      for (final view in layout.viewports)
        Container(
          margin: const EdgeInsets.all(1),
          color: const Color(0xff0b0f15),
          child: Stack(
            children: [
              CustomPaint(painter: _GridPainter(), size: Size.infinite),
              Positioned(
                top: 8,
                left: 8,
                child: Chip(label: Text('${view.id} • ${view.orientation}')),
              ),
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.view_in_ar_outlined,
                      size: 48,
                      color: Colors.blueGrey,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'GPU backend preparado',
                      style: TextStyle(color: Colors.blueGrey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = const Color(0xff172231)
      ..strokeWidth = .5;
    for (double x = 0; x < s.width; x += 32) {
      c.drawLine(Offset(x, 0), Offset(x, s.height), p);
    }
    for (double y = 0; y < s.height; y += 32) {
      c.drawLine(Offset(0, y), Offset(s.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Properties extends StatelessWidget {
  const _Properties({this.node});
  final EngineeringTreeNode? node;
  @override
  Widget build(BuildContext context) {
    if (node == null) return const Center(child: Text('Selecione um item'));
    final sections = const PropertyInspector().inspect(node!);
    return Container(
      color: const Color(0xff141b24),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Text(
            'PROPERTIES',
            style: TextStyle(fontSize: 11, color: Colors.blueGrey),
          ),
          for (final section in sections)
            ExpansionTile(
              initiallyExpanded: true,
              title: Text(section.name),
              children: [
                for (final e in section.values.entries)
                  ListTile(
                    dense: true,
                    title: Text(e.key),
                    trailing: SizedBox(
                      width: 130,
                      child: Text(
                        '${e.value ?? '—'}',
                        textAlign: TextAlign.end,
                        maxLines: 2,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar();
  @override
  Widget build(BuildContext context) => Container(
    height: 26,
    color: const Color(0xff0875b9),
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: const Row(
      children: [
        Text('Ready'),
        Spacer(),
        Text('Triangles: —   FPS: —   Runtime: idle'),
      ],
    ),
  );
}

class _PaletteDelegate extends SearchDelegate<void> {
  _PaletteDelegate(this.manager);
  final StudioCommandManager manager;
  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear)),
  ];
  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    onPressed: () => close(context, null),
    icon: const Icon(Icons.arrow_back),
  );
  @override
  Widget buildResults(BuildContext context) => _results();
  @override
  Widget buildSuggestions(BuildContext context) => _results();
  Widget _results() => ListView(
    children: [
      for (final c in manager.search(query))
        ListTile(
          title: Text(c.label),
          subtitle: Text(c.category),
          onTap: () async {
            await c.execute();
          },
        ),
    ],
  );
}
