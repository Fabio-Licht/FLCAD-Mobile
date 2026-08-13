class RegionLayer {
  const RegionLayer({
    required this.id,
    required this.name,
    required this.visible,
    required this.locked,
    required this.order,
  });
  final String id, name;
  final bool visible, locked;
  final int order;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'visible': visible,
    'locked': locked,
    'order': order,
  };
}

class RegionGroup {
  const RegionGroup({required this.id, required this.name, this.parentId});
  final String id, name;
  final String? parentId;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'parentId': parentId,
  };
}
