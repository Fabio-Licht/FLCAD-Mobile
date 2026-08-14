import 'dart:io';
import '../../sketch_engine/api/sketch_engine_api.dart';
import '../api/profile_recognition_api.dart';
import '../engine/profile_recognition_engine.dart';
import '../repository/profile_repository.dart';

class ProfileRecognitionFactory {
  const ProfileRecognitionFactory();
  ProfileRecognitionApi create({
    required Directory projectDirectory,
    required SketchEngineApi sketch,
  }) => ProfileRecognitionApi(
    ProfileRecognitionEngine(
      sketch: sketch,
      repository: ProfileRepository(projectDirectory),
    ),
  );
}
