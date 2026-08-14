import '../models/validation_models.dart';

class ToleranceManager {
  const ToleranceManager();
  void update(
    LiveValidationSession session,
    void Function(ValidationParameters) change,
  ) {
    change(session.parameters);
    session.updatedAt = DateTime.now().toUtc();
  }

  bool inside(ValidationParameters parameters, double deviation) =>
      deviation.abs() <= parameters.tolerance;
}
