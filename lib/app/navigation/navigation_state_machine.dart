import 'navigation_contracts.dart';

class NavigationStateMachine {
  NavigationState _state = NavigationState.idle;
  NavigationState get state => _state;
  bool get isNavigating => const {
    NavigationState.orbiting,
    NavigationState.panning,
    NavigationState.zooming,
    NavigationState.boxZoom,
    NavigationState.seek,
  }.contains(_state);

  NavigationTransition? transitionTo(NavigationState next) {
    if (_state == next) return null;
    final transition = NavigationTransition(_state, next);
    _state = next;
    return transition;
  }
}

class NavigationTransition {
  const NavigationTransition(this.from, this.to);
  final NavigationState from;
  final NavigationState to;
}
