import '../engine/reverse_session_engine.dart';
import '../models/session_models.dart';

class ReverseSessionApi {
  const ReverseSessionApi(this.engine);
  final ReverseSessionEngine engine;
  ReverseSession create({
    required String name,
    required String user,
    required SessionContext context,
  }) => engine.create(name: name, user: user, context: context);
  void open(String id) => engine.open(id);
  void close(String id) => engine.close(id);
  void pause(String id) => engine.pause(id);
  void resume(String id) => engine.resume(id);
  void archive(String id) => engine.archive(id);
  void delete(String id) => engine.delete(id);
  ReverseSession duplicate(String id) => engine.duplicate(id);
  ReverseSession merge(String target, String source) =>
      engine.merge(target, source);
  SessionSnapshot snapshot(String id) => engine.snapshot(id);
  void restore(String id, String snapshot) => engine.restore(id, snapshot);
  RecoveryState recover(String id) => engine.crashRecovery(id);
  void restoreRecovery(String id) => engine.restoreRecovery(id);
  List<SessionJournalEntry> replay(String id) => engine.replay(id);
  Future<void> persist() => engine.persist();
}
