import '../models/reference_models.dart';

class ReferenceParameterEngine {
  const ReferenceParameterEngine();
  void update(
    ReferenceEntity entity,
    void Function(ReferenceParameters) change,
  ) {
    if (entity.frozen) throw StateError('Reference is frozen: ${entity.id}');
    change(entity.parameters);
    entity.version++;
    entity.status = ReferenceStatus.prepared;
  }
}
