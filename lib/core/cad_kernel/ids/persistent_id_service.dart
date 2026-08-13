import 'package:uuid/uuid.dart';

class PersistentIdService {
  const PersistentIdService();
  static const _uuid = Uuid();
  String create(String projectId, String namespace) =>
      '$projectId:$namespace:${_uuid.v4()}';
  bool valid(String value) =>
      value.split(':').length >= 3 && value.trim().isNotEmpty;
}
