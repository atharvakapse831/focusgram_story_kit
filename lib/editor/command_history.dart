import 'package:flutter/foundation.dart';
import '../models/story_project.dart';

/// Base contract for an undoable/redoable mutation on a [StoryProject].
@immutable
abstract class EditorCommand {
  const EditorCommand();

  /// Human-readable description of the operation (e.g., 'Move Element', 'Add Text').
  String get description;

  /// Applies the mutation to [project] and returns the resulting document.
  StoryProject execute(StoryProject project);

  /// Reverses the mutation on [project] and returns the previous document state.
  StoryProject undo(StoryProject project);

  /// Whether this command can coalesce with an incoming [next] command
  /// (e.g. continuous slider or drag gestures merging into a single undo entry).
  bool canMergeWith(EditorCommand next) => false;

  /// Produces a merged command combining the original baseline state with the new state.
  EditorCommand mergeWith(EditorCommand next) => next;
}

/// Manages the undo and redo stacks for story document operations.
class CommandHistory {
  CommandHistory({this.maxDepth = 50});

  /// Maximum number of undoable steps retained in memory.
  final int maxDepth;

  final List<EditorCommand> _undoStack = [];
  final List<EditorCommand> _redoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  int get undoCount => _undoStack.length;
  int get redoCount => _redoStack.length;

  /// Executes [command] against [project], pushing it to the undo stack
  /// (or coalescing with the latest command) and clearing the redo stack.
  StoryProject execute(EditorCommand command, StoryProject project) {
    if (_undoStack.isNotEmpty && _undoStack.last.canMergeWith(command)) {
      final merged = _undoStack.removeLast().mergeWith(command);
      _undoStack.add(merged);
    } else {
      _undoStack.add(command);
      if (_undoStack.length > maxDepth) {
        _undoStack.removeAt(0);
      }
    }

    _redoStack.clear();
    final updated = command.execute(project);
    return updated.copyWith(revision: updated.revision + 1);
  }

  /// Reverses the most recent command on the undo stack.
  StoryProject undo(StoryProject project) {
    if (!canUndo) return project;

    final command = _undoStack.removeLast();
    _redoStack.add(command);
    final updated = command.undo(project);
    return updated.copyWith(revision: updated.revision + 1);
  }

  /// Re-applies the most recent command on the redo stack.
  StoryProject redo(StoryProject project) {
    if (!canRedo) return project;

    final command = _redoStack.removeLast();
    _undoStack.add(command);
    final updated = command.execute(project);
    return updated.copyWith(revision: updated.revision + 1);
  }

  /// Clears all undo and redo history.
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}
