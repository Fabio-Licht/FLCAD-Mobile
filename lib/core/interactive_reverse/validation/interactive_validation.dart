import '../models/interactive_models.dart';

class InteractiveValidation {
  const InteractiveValidation();
  List<String> validate(InteractiveSelection selection) => [
    if (selection.objectId.trim().isEmpty) 'Selected object is required',
    if (selection.confidence < 0 || selection.confidence > 1)
      'Confidence must be between 0 and 1',
    if (selection.quality < 0 || selection.quality > 1)
      'Quality must be between 0 and 1',
  ];
}
