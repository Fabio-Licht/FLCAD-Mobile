import '../models/session_models.dart';

class SessionValidation {
  const SessionValidation();
  List<String> validate(ReverseSession session) => [
    if (session.name.trim().isEmpty) 'Session name is required',
    if (session.context.projectId.trim().isEmpty) 'Project ID is required',
  ];
}
