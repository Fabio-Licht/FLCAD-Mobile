import 'dart:async';
import '../models/studio_models.dart';

class StudioNotificationCenter {
  final _controller = StreamController<StudioNotification>.broadcast();
  final List<StudioNotification> _history = [];
  Stream<StudioNotification> get notifications => _controller.stream;
  List<StudioNotification> get history => List.unmodifiable(_history);
  void publish(StudioNotification value) {
    _history.add(value);
    _controller.add(value);
  }

  Future<void> dispose() => _controller.close();
}
