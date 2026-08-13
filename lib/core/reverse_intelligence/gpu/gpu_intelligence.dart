import '../models/intelligence_models.dart';

abstract interface class GpuObservationBackend {
  bool get available;
  Future<MeshObservation> accelerate(MeshObservation observation);
}
