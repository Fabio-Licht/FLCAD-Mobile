# Preview Engine

Every creation or edit starts as an `EditorOperation` in preview state. Confirmation removes it from the preview layer and performs a transaction. Cancellation performs no domain mutation; failures roll back.
