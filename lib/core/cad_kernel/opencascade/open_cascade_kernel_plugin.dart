import '../manager/kernel_manager.dart';
import '../plugins/kernel_plugin.dart';
import 'open_cascade_bridge.dart';
import 'open_cascade_ffi.dart';
import 'open_cascade_kernel_adapter.dart';

class OpenCascadeKernelPlugin implements KernelPlugin {
  OpenCascadeKernelPlugin({this.bridge});
  final OpenCascadeNativeBridge? bridge;
  @override
  String get pluginId => 'opencascade-plugin';
  @override
  String get pluginVersion => '1.0.0';
  @override
  bool get compatible => true;
  @override
  OpenCascadeKernelAdapter createKernel() => OpenCascadeKernelAdapter(
    bridge: bridge,
    bridgeFactory: OpenCascadeFFI.loadOrUnavailable,
  );
  void register(KernelManager manager) {
    manager.plugins.register(this);
    manager.loadPlugin(pluginId, makeDefault: true);
  }
}
