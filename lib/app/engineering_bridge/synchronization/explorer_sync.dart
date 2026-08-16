class BridgeExplorerState {
  final Map<String, Object> entities = {};
  void upsert(String id, Object entity) => entities[id] = entity;
  void remove(String id) => entities.remove(id);
}

class BridgeExplorerSync {
  const BridgeExplorerSync(this.state);
  final BridgeExplorerState state;
  void created(String id, Object entity) => state.upsert(id, entity);
  void deleted(String id) => state.remove(id);
}
