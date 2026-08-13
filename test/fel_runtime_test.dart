import 'dart:io';

import 'package:flcad_mobile/core/fel/api/fel_api.dart';
import 'package:flcad_mobile/core/fel/commands/native_commands.dart';
import 'package:flcad_mobile/core/fel/compiler/fel_compiler.dart';
import 'package:flcad_mobile/core/fel/functions/fel_function_library.dart';
import 'package:flcad_mobile/core/fel/history/fel_history.dart';
import 'package:flcad_mobile/core/fel/lexer/fel_lexer.dart';
import 'package:flcad_mobile/core/fel/optimizer/fel_optimizer.dart';
import 'package:flcad_mobile/core/fel/parser/fel_parser.dart';
import 'package:flcad_mobile/core/fel/runtime/fel_context.dart';
import 'package:flcad_mobile/core/fel/runtime/fel_runtime.dart';
import 'package:flcad_mobile/core/smart_regions/api/smart_regions_api.dart';
import 'package:flcad_mobile/core/smart_regions/models/geometry.dart';
import 'package:flcad_mobile/core/smart_regions/repository/smart_region_repository.dart';
import 'package:flcad_mobile/core/smart_regions/selection/triangle_selection.dart';
import 'package:flcad_mobile/core/storage/local_storage_service.dart';
import 'package:flcad_mobile/features/projects/data/project_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'runtime executes Smart Region pipeline, saves and supports undo',
    () async {
      final root = await Directory.systemTemp.createTemp('fel_runtime_');
      addTearDown(() => root.delete(recursive: true));
      final projects = ProjectRepository(
        storage: LocalStorageService(rootDirectory: root),
      );
      final project = await projects.create(name: 'Part', client: 'Client');
      final repository = SmartRegionRepository(projects: projects),
          regions = SmartRegionsApi(repository: repository);
      final mesh = MeshTopology(
        id: 'mesh',
        vertices: const [
          Vec3(0, 0, 0),
          Vec3(1, 0, 0),
          Vec3(1, 1, 0),
          Vec3(0, 1, 0),
          Vec3(2, 0, 0),
          Vec3(2, 1, 0),
        ],
        triangles: const [
          Triangle(0, 1, 2),
          Triangle(0, 2, 3),
          Triangle(1, 4, 5),
          Triangle(1, 5, 2),
        ],
      );
      await regions.create(
        projectId: project.id,
        mesh: mesh,
        selection: TriangleSelection([0]),
        name: 'FLANGE',
      );
      final directory = await projects.directoryFor(project.id);
      final context = FELExecutionContext(
        projectId: project.id,
        projectPath: directory.path,
        regions: regions,
        meshes: {'mesh': mesh},
      );
      final api = FELApi.standard();
      final result = await api.executor.execute(
        'SELECT REGION "FLANGE" -> EXPAND REGION 1 -> SAVE PROJECT',
        context,
      );
      expect(result.state, FELRuntimeState.completed);
      expect(
        (await repository.loadRegions(project.id)).single.selection.length,
        3,
      );
      expect(api.runtime.debugger.entries, hasLength(3));
      expect(api.runtime.history.canUndo, isTrue);
    },
  );

  test(
    'optimizer/compiler cache, history redo and cancellation work',
    () async {
      final ast = FELParser(
        FELLexer().tokenize('SAVE PROJECT\nSAVE PROJECT'),
      ).parse();
      expect(const FELOptimizer().optimize(ast).statements, hasLength(1));
      final compiler = FELCompiler();
      expect(
        identical(compiler.compile('x', ast), compiler.compile('x', ast)),
        isTrue,
      );
      final history = FELHistory();
      var undone = false;
      history.record(
        FELHistoryEntry(
          source: 'x',
          command: 'X',
          timestamp: DateTime.now(),
          description: 'x',
          undo: () async => undone = true,
        ),
      );
      await history.undo();
      expect(undone, isTrue);
      expect(history.redoEntry()?.command, 'X');
      final runtime = FELRuntime(
        commands: createNativeCommandRegistry(),
        functions: FELFunctionLibrary(),
      );
      final token = FELCancellationToken()..cancel();
      final emptyContext = FELExecutionContext(
        projectId: 'p',
        projectPath: '',
        regions: SmartRegionsApi(),
      );
      final result = await runtime.execute(
        compiler.compile('cancel', ast),
        emptyContext,
        cancellation: token,
      );
      expect(result.state, FELRuntimeState.cancelled);
    },
  );
}
