import '../models/session_models.dart';

class RecoveryEngine {
  final Map<String, RecoveryState> states = {};
  RecoveryState capture(ReverseSession session) {
    final state = RecoveryState(
      sessionId: session.id,
      context: session.context,
      diagnostics: 'Recovery state valid; no CAD operation executed.',
    );
    states[session.id] = state;
    return state;
  }

  List<String> validate(RecoveryState state) => [
    if (state.sessionId.isEmpty) 'Session ID is required',
    if (state.context.projectId.isEmpty) 'Project ID is required',
  ];
}
