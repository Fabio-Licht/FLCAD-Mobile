# Recognition Plugins

Plugins register `UniversalRecognizer` implementations with unique IDs. Each must implement detect, evaluate, refine, validate, explain and confidence. Recognizers receive only `RecognitionContext`; inter-domain communication remains the engine's responsibility.
