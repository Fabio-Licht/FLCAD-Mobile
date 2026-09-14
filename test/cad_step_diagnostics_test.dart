import 'package:flcad_mobile/app/runtime/cad_step_diagnostics.dart';
import 'package:flcad_mobile/app/runtime/cad_asset_fs_native.dart';
import 'package:flcad_mobile/core/cad_kernel/opencascade/open_cascade_kernel_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'development diagnostics contain only fixed categories and status codes',
    () {
      final native = NativeSourceFailure(
        0,
        6,
        2,
        0,
        0,
        0,
        123,
        'STEP line limit',
      );
      expect(
        managedStepFailureDiagnostic(native),
        'step.limit.line bridge=0 native=6 phase=2 domain=0 code=0',
      );
      final untrusted = NativeSourceFailure(
        1,
        5,
        2,
        0,
        0,
        987,
        123,
        r'C:\private\source.stp token=secret',
      );
      expect(
        managedStepFailureDiagnostic(untrusted),
        'bridge.native_rejected bridge=1 native=5 phase=2 domain=0 code=0',
      );
      expect(
        managedStepFailureDiagnostic(
          CadAssetNativeError('private-operation', 2, 32, 0, 1),
        ),
        'caf.failure status=2 win32=32 nt=0',
      );
      expect(
        managedStepFailureDiagnostic(StateError('private detail')),
        'runtime.state_failure',
      );
    },
  );
}
