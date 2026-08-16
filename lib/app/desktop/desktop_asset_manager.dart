import 'package:flutter/services.dart';

abstract final class DesktopAssets {
  static const logo = 'assets/branding/flcad_reverse_ai_mark.png';
  static const applicationIcon = 'assets/icons/flcad_reverse_ai_icon.png';
  static const splashTransformation = 'assets/splash/mesh_to_cad.png';
  static const all = [logo, applicationIcon, splashTransformation];
}

class DesktopAssetManager {
  const DesktopAssetManager(this.bundle);
  final AssetBundle bundle;

  Future<void> validate() async {
    for (final asset in DesktopAssets.all) {
      final data = await bundle.load(asset);
      if (data.lengthInBytes == 0) {
        throw StateError('Empty desktop asset: $asset');
      }
    }
  }
}
