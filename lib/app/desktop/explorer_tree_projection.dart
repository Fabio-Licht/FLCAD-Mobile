/// Presentation-only child projection for Explorer groups.
///
/// Empty groups deliberately project to no rows. They remain visible through
/// their group header, but never receive a synthetic document-like child.
abstract final class ExplorerTreeProjection {
  static List<T> rowsFor<T>(Iterable<T> entities) =>
      List.unmodifiable(entities);
}
