import '../hybrid/hybrid_object.dart';
import '../layers/mesh_layer.dart';

TopologyDNA createTopologyDNA(
  List<GeometryAssetRef> assets,
  List<MeshLayer> layers,
  Iterable<String> relations,
) {
  final source = assets.map((a) => a.fingerprint).join('|'),
      layer = layers
          .map((l) => '${l.id}:${l.enabled}:${l.displacements}')
          .join('|'),
      relation = relations.join('|'),
      raw = '$source::$layer::$relation',
      hash = raw.codeUnits
          .fold<int>(17, (a, b) => 37 * a + b)
          .toUnsigned(32)
          .toRadixString(16);
  return TopologyDNA(source, layer, relation, hash);
}
