import '../models/alignment_models.dart';

class AlignmentParameterEngine {
  const AlignmentParameterEngine();
  void update(Alignment alignment, void Function(AlignmentParameters) change) {
    change(alignment.parameters);
    alignment.version++;
    alignment.status = AlignmentStatus.prepared;
  }

  void lock(Alignment alignment, String axis) =>
      alignment.parameters.lockedAxes.add(axis);
  void unlock(Alignment alignment, String axis) =>
      alignment.parameters.lockedAxes.remove(axis);
}
