import '../engine/profile_recognition_engine.dart';
import '../models/profile_models.dart';
import '../validation/profile_validation.dart';

class ProfileRecognitionApi {
  const ProfileRecognitionApi(this.engine);
  final ProfileRecognitionEngine engine;
  void recognize() => engine.recognize();
  List<RecognizedProfile> get profiles =>
      List.unmodifiable(engine.profiles.values);
  List<ProfileLoop> get loops => List.unmodifiable(engine.loops.values);
  List<SketchRegion> get regions => List.unmodifiable(engine.regions.values);
  ProfileValidationResult get validation => engine.validation;
  IntentRecognition get intent => engine.intent;
  ProfileQuality? get quality => engine.lastQuality;
  FeatureReadiness? get readiness => engine.lastReadiness;
  List<ProfileRecommendation> recommendations() => engine.recommendations();
}
