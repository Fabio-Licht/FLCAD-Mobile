// ignore_for_file: curly_braces_in_flow_control_structures

import '../contracts/bridge_selection.dart';

class RegionClassifier {
  const RegionClassifier();
  BridgeSelectionKind classify(BridgeSelection selection) {
    if (selection.entityId != null && selection.triangleIndices.isEmpty)
      return BridgeSelectionKind.cadEntity;
    if (selection.triangleIndices.length == 1)
      return BridgeSelectionKind.triangle;
    return BridgeSelectionKind.meshRegion;
  }
}
