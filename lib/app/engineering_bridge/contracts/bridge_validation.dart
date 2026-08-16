// ignore_for_file: curly_braces_in_flow_control_structures

import 'bridge_context.dart';

class BridgeValidation {
  const BridgeValidation();
  void requireRegion(BridgeContext context) {
    final region = context.region;
    if (region == null ||
        region.triangleIndices.isEmpty ||
        region.points.length < 3) {
      throw StateError('A non-empty kernel mesh region is required.');
    }
  }

  void requireConfirmation(BridgeContext context) {
    if (!context.userConfirmed)
      throw StateError('Explicit user confirmation is required.');
  }

  void requireAttribute(BridgeContext context, String key) {
    if (!context.attributes.containsKey(key) ||
        context.attributes[key] == null) {
      throw StateError(
        'Bridge context is missing required official contract: $key',
      );
    }
  }
}
