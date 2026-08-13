import '../../engineering/runtime/engineering_runtime.dart';

class DesktopWindowDescriptor {
  const DesktopWindowDescriptor(this.id, this.projectId, this.title);
  final String id, projectId, title;
}

abstract interface class NativeWindowBackend {
  bool get supportsMultipleWindows;
  Future<void> open(DesktopWindowDescriptor window);
  Future<void> close(String id);
}

class DesktopRuntime {
  DesktopRuntime({EngineeringRuntime? runtime, NativeWindowBackend? windows})
    : runtime = runtime ?? EngineeringRuntime.shared,
      windows = windows;
  final EngineeringRuntime runtime;
  final NativeWindowBackend? windows;
  final Map<String, DesktopWindowDescriptor> _open = {};
  Future<void> openWindow(DesktopWindowDescriptor value) async {
    if (windows?.supportsMultipleWindows != true) {
      throw UnsupportedError('Native multi-window backend unavailable');
    }
    await windows!.open(value);
    _open[value.id] = value;
  }

  Future<void> closeWindow(String id) async {
    await windows?.close(id);
    _open.remove(id);
  }

  List<DesktopWindowDescriptor> get openWindows =>
      List.unmodifiable(_open.values);
  EngineeringTask<T> background<T>(String id, Future<T> Function() operation) =>
      runtime.submit(id, operation, namespace: 'desktop');
}
