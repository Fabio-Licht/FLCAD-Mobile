import '../models/session_models.dart';

class SessionAdvisor {
  const SessionAdvisor();
  List<String> recommendations(ReverseSession session) => [
    if (session.progress < 1) 'Session incomplete',
    if (session.context.state['validation'] == null) 'Validation pending',
    if (session.context.state['alignment'] == null) 'Alignment pending',
    if (session.context.state['activeFeature'] != null &&
        session.context.state['validation'] == null)
      'Feature without validation',
    if (session.context.state['activeSketch'] != null &&
        session.context.state['activeFeature'] == null)
      'Unused sketch',
    if (session.status == ReverseSessionStatus.paused) 'Workflow interrupted',
  ];
}
