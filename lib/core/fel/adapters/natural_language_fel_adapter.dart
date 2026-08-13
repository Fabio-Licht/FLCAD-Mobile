abstract interface class NaturalLanguageFELAdapter {
  Future<String> translate(String intent, {required String projectId});
}

class DeterministicIntentAdapter implements NaturalLanguageFELAdapter {
  @override
  Future<String> translate(String intent, {required String projectId}) async {
    final text = intent.toLowerCase();
    final quoted =
        RegExp(r'["“](.+?)["”]').firstMatch(intent)?.group(1) ?? 'TOP';
    if (text.contains('plano')) {
      return 'SELECT REGION "$quoted"\nFIT PLANE\nCREATE PLANE\nSAVE PROJECT';
    }
    if (text.contains('encolh') || text.contains('shrink')) {
      return 'SELECT REGION "$quoted"\nSHRINK REGION 1\nSAVE PROJECT';
    }
    throw UnsupportedError('Intenção ainda não mapeada para FEL');
  }
}
