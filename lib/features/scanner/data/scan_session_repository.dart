import '../../../models/scan_session.dart';

class ScanSessionRepository {
  ScanSessionRepository._();

  static final ScanSessionRepository instance =
      ScanSessionRepository._();

  final List<ScanSession> _sessions = [];

  ScanSession? _currentSession;

  List<ScanSession> get sessions =>
      List.unmodifiable(_sessions);

  ScanSession? get currentSession =>
      _currentSession;

  void create(ScanSession session) {
    _sessions.add(session);
    _currentSession = session;
  }

  void open(ScanSession session) {
    _currentSession = session;
  }

  void delete(ScanSession session) {
    _sessions.removeWhere(
      (s) => s.id == session.id,
    );

    if (_currentSession?.id == session.id) {
      _currentSession = null;
    }
  }

  void clear() {
    _sessions.clear();
    _currentSession = null;
  }
}