import 'dart:io';

class ImageQualityAnalysis {
  const ImageQualityAnalysis({
    required this.path,
    required this.score,
    required this.issues,
    required this.signature,
  });
  final String path;
  final int score;
  final List<String> issues;
  final String signature;
  Map<String, dynamic> toJson() => {
    'path': path,
    'score': score,
    'issues': issues,
    'signature': signature,
  };
}

abstract interface class ImageQualityService {
  Future<List<ImageQualityAnalysis>> analyze(List<String> imagePaths);
}

class AlphaImageQualityService implements ImageQualityService {
  const AlphaImageQualityService();
  @override
  Future<List<ImageQualityAnalysis>> analyze(List<String> imagePaths) async {
    final seen = <String>{};
    final result = <ImageQualityAnalysis>[];
    for (final imagePath in imagePaths) {
      final file = File(imagePath);
      final length = await file.length();
      final modified = (await file.stat()).modified.millisecondsSinceEpoch;
      final signature = '$length:$modified';
      final issues = <String>[];
      var score = 100;
      if (length < 16 * 1024) {
        issues.add('baixa_resolucao_ou_arquivo_pequeno');
        score -= 35;
      }
      if (!seen.add(signature)) {
        issues.add('possivel_duplicada');
        score -= 20;
      }
      result.add(
        ImageQualityAnalysis(
          path: imagePath,
          score: score.clamp(0, 100),
          issues: issues,
          signature: signature,
        ),
      );
    }
    return result;
  }
}
