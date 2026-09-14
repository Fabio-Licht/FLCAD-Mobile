import 'package:flutter/foundation.dart';
import 'dart:io';

import '../../core/cad_kernel/opencascade/open_cascade_kernel_adapter.dart';
import 'cad_asset_fs_native.dart';

/// Development diagnostics contain only fixed categories and numeric statuses.
/// Never interpolate exceptions, native messages, locators or object identities.
String managedStepFailureDiagnostic(Object error) {
  if (error is NativeSourceNotificationFailure) {
    return managedStepFailureDiagnostic(error.cause);
  }
  if (error is NativeSourceRecoveryFailure) {
    return managedStepFailureDiagnostic(error.cause ?? error.cleanup);
  }
  if (error is FileSystemException) return 'runtime.filesystem';
  if (error is CadAssetNativeError) {
    final operation = switch (error.operation) {
      'read' => '.read',
      'write' => '.write',
      'info' => '.info',
      'seal' => '.seal',
      'open/create child' => '.child',
      'open root' => '.root',
      'acquire writer' => '.writer_acquire',
      'seal writer' => '.writer_seal',
      'release writer' => '.writer_release',
      'enumerate' => '.enumerate',
      'lock' => '.lock',
      'rename' => '.rename',
      'close' => '.close',
      _ => '',
    };
    return 'caf.failure$operation status=${error.status} win32=${error.win32} nt=${error.nt}';
  }
  if (error is NativeSourceFailure) {
    final category = switch (error.message) {
      'STEP line limit' => 'step.limit.line',
      'STEP token/string limit' => 'step.limit.token',
      'STEP token count limit' => 'step.limit.token_count',
      'STEP entity label range' => 'step.limit.entity_label',
      'STEP nesting limit' => 'step.limit.nesting',
      'STEP entity limit' => 'step.limit.entity_count',
      'STEP model entity limit' => 'step.limit.model_count',
      'STEP metadata string limit' => 'step.limit.metadata',
      'Binary STEP parameters unsupported' => 'step.binary_parameter',
      'Invalid or incomplete STEP framing' => 'step.framing',
      'STEP model validation failed' => 'step.model_validation',
      'STEP compatibility memory limit' => 'step.compatibility.memory_limit',
      'STEP compatibility signature mismatch' =>
        'step.compatibility.signature_mismatch',
      'STEP compatibility ambiguous dimensions' =>
        'step.compatibility.ambiguous_dimensions',
      'STEP compatibility ReadStream failed' => 'step.compatibility.readstream',
      'STEP transfer validation failed' => 'step.transfer_validation',
      'STEP requires one product and one root' => 'step.product_or_root_count',
      'STEP non-single-part XDE document' => 'step.non_single_part',
      'STEP-1A0 requires one solid' => 'step.solid_topology',
      'STEP length unit unresolved' => 'step.unit_unresolved',
      'STEP external references unsupported' => 'step.external_reference',
      'STEP unknown or invalid entity' => 'step.invalid_entity',
      'STEP transparency unsupported' => 'step.transparency',
      _ => 'bridge.native_rejected',
    };
    return '$category bridge=${error.bridgeStatus} native=${error.nativeStatus} phase=${error.phase} domain=${error.domain} code=${error.code}';
  }
  if (error is UnsupportedError) return 'runtime.unsupported';
  if (error is FormatException) return 'runtime.invalid_metadata';
  if (error is StateError) {
    return switch (error.message) {
      'Path escapes project' => 'runtime.project_boundary',
      'Invalid path' => 'runtime.project_path',
      'Rename requires owned live capability' => 'runtime.staging_ownership',
      'Payload identity changed after seal' => 'runtime.payload_identity',
      'Payload changed after validation' => 'runtime.payload_changed',
      'Journal temporary verification failed' => 'runtime.journal_verification',
      'Manifest readback mismatch' => 'runtime.journal_readback',
      'Native mesh does not match its published descriptor' =>
        'runtime.mesh_descriptor',
      'Native mesh bounds do not match its descriptor' => 'runtime.mesh_bounds',
      'Native mesh bounds are invalid' => 'runtime.mesh_bounds_invalid',
      _ => 'runtime.state_failure',
    };
  }
  if (error is ArgumentError) return 'runtime.argument';
  if (error is AssertionError) return 'runtime.assertion';
  return 'runtime.failure';
}

void logManagedStepFailure(Object error) {
  if (kDebugMode) {
    debugPrint('[managed-step] ${managedStepFailureDiagnostic(error)}');
  }
}
