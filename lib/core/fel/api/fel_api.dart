import '../../smart_regions/api/smart_regions_api.dart';
import '../commands/native_commands.dart';
import '../executor/fel_executor.dart';
import '../functions/fel_function_library.dart';
import '../runtime/fel_context.dart';
import '../runtime/fel_runtime.dart';
import '../validators/semantic_analyzer.dart';

class FELApi {
  FELApi._(this.runtime, this.executor);
  factory FELApi.standard() {
    final commands = createNativeCommandRegistry(),
        functions = FELFunctionLibrary(),
        runtime = FELRuntime(commands: commands, functions: functions);
    return FELApi._(
      runtime,
      FELExecutor(
        runtime: runtime,
        analyzer: FELSemanticAnalyzer(commands, functions),
      ),
    );
  }
  final FELRuntime runtime;
  final FELExecutor executor;
  Future<FELExecutionResult> execute({
    required String source,
    required String projectId,
    required String projectPath,
    SmartRegionsApi? regions,
    FELExecutionContext? context,
  }) => executor.execute(
    source,
    context ??
        FELExecutionContext(
          projectId: projectId,
          projectPath: projectPath,
          regions: regions ?? SmartRegionsApi(),
        ),
  );
}
