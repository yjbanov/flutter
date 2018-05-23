/// Signature for a function that is called for each [RenderObject].
///
/// Used by [RenderObject.visitChildren].
typedef void RenderObjectVisitor(RenderObject child);

/// An object in the render tree.
abstract class RenderObject {
  /// The number of children.
  int get childCount {
    // TODO
    return null;
  }

  /// Insert child into this render object's child list after the given child.
  ///
  /// If `after` is null, then this inserts the child at the start of the list,
  /// and the child becomes the new [firstChild].
  void insert(RenderObject child, { RenderObject after }) {
    // TODO
  }

  /// Remove this child from the child list.
  ///
  /// Requires the child to be present in the child list.
  void remove(RenderObject child) {
    // TODO
  }

  /// Remove all their children from this render object's child list.
  ///
  /// More efficient than removing them individually.
  void removeAll() {
    // TODO
  }

  /// Move this child in the child list to be before the given child.
  ///
  /// More efficient than removing and re-adding the child. Requires the child
  /// to already be in the child list at some position. Pass null for before to
  /// move the child to the end of the child list.
  void move(RenderObject child, { RenderObject after }) {
    // TODO
  }
}
