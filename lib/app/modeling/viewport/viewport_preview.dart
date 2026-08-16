import '../interaction/interaction_context.dart';

class ViewportPreview {
  const ViewportPreview({this.value, this.transparent = true});
  final EngineeringPreview? value;
  final bool transparent;
  bool get visible => value != null;
}
