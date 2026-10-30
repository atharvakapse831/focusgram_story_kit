import 'package:flutter/material.dart';
import '../models/element_payloads.dart';
import '../models/story_element.dart';
import '../models/story_media_asset.dart';
import '../models/story_page.dart';
import '../models/story_project.dart';
import '../models/story_transform.dart';
import 'command_history.dart';

/// Appends a new [element] to the specified [pageId].
class AddElementCommand extends EditorCommand {
  const AddElementCommand({required this.pageId, required this.element});

  final String pageId;
  final StoryElement element;

  @override
  String get description => 'Add ${element.type.name}';

  @override
  StoryProject execute(StoryProject project) {
    return _modifyPage(project, pageId, (page) {
      return page.copyWith(elements: [...page.elements, element]);
    });
  }

  @override
  StoryProject undo(StoryProject project) {
    return _modifyPage(project, pageId, (page) {
      return page.copyWith(
        elements: page.elements.where((e) => e.id != element.id).toList(),
      );
    });
  }
}

/// Removes an element by ID, preserving its prior state for undo.
class RemoveElementCommand extends EditorCommand {
  const RemoveElementCommand({
    required this.pageId,
    required this.element,
    required this.index,
  });

  final String pageId;
  final StoryElement element;
  final int index;

  @override
  String get description => 'Remove ${element.type.name}';

  @override
  StoryProject execute(StoryProject project) {
    return _modifyPage(project, pageId, (page) {
      return page.copyWith(
        elements: page.elements.where((e) => e.id != element.id).toList(),
      );
    });
  }

  @override
  StoryProject undo(StoryProject project) {
    return _modifyPage(project, pageId, (page) {
      final list = List<StoryElement>.from(page.elements);
      final insertAt = index.clamp(0, list.length);
      list.insert(insertAt, element);
      return page.copyWith(elements: list);
    });
  }
}

/// Updates the [StoryTransform] of an element. Supports transaction coalescing
/// so dragging/scaling/rotating gestures produce only one undo entry.
class TransformElementCommand extends EditorCommand {
  const TransformElementCommand({
    required this.pageId,
    required this.elementId,
    required this.previousTransform,
    required this.newTransform,
    this.isCoalescing = false,
  });

  final String pageId;
  final String elementId;
  final StoryTransform previousTransform;
  final StoryTransform newTransform;
  final bool isCoalescing;

  @override
  String get description => 'Transform element';

  @override
  bool canMergeWith(EditorCommand next) {
    if (!isCoalescing) return false;
    if (next is! TransformElementCommand) return false;
    return next.pageId == pageId && next.elementId == elementId;
  }

  @override
  EditorCommand mergeWith(EditorCommand next) {
    final nextCmd = next as TransformElementCommand;
    return TransformElementCommand(
      pageId: pageId,
      elementId: elementId,
      previousTransform: previousTransform,
      newTransform: nextCmd.newTransform,
      isCoalescing: nextCmd.isCoalescing,
    );
  }

  @override
  StoryProject execute(StoryProject project) {
    return _modifyElement(project, pageId, elementId, (el) {
      return el.copyWith(transform: newTransform);
    });
  }

  @override
  StoryProject undo(StoryProject project) {
    return _modifyElement(project, pageId, elementId, (el) {
      return el.copyWith(transform: previousTransform);
    });
  }
}

/// Updates the payload data of an element (e.g. text content, styling, colors).
class UpdateElementPayloadCommand extends EditorCommand {
  const UpdateElementPayloadCommand({
    required this.pageId,
    required this.elementId,
    required this.previousPayload,
    required this.newPayload,
  });

  final String pageId;
  final String elementId;
  final StoryElementPayload previousPayload;
  final StoryElementPayload newPayload;

  @override
  String get description => 'Update element content';

  @override
  StoryProject execute(StoryProject project) {
    return _modifyElement(project, pageId, elementId, (el) {
      return el.copyWith(payload: newPayload);
    });
  }

  @override
  StoryProject undo(StoryProject project) {
    return _modifyElement(project, pageId, elementId, (el) {
      return el.copyWith(payload: previousPayload);
    });
  }
}

/// Modifies the stacking z-order index of an element.
class ReorderElementCommand extends EditorCommand {
  const ReorderElementCommand({
    required this.pageId,
    required this.elementId,
    required this.previousZIndex,
    required this.newZIndex,
  });

  final String pageId;
  final String elementId;
  final int previousZIndex;
  final int newZIndex;

  @override
  String get description => 'Reorder layer';

  @override
  StoryProject execute(StoryProject project) {
    return _modifyElement(project, pageId, elementId, (el) {
      return el.copyWith(zIndex: newZIndex);
    });
  }

  @override
  StoryProject undo(StoryProject project) {
    return _modifyElement(project, pageId, elementId, (el) {
      return el.copyWith(zIndex: previousZIndex);
    });
  }
}

/// Adds a new page to the story project.
class AddPageCommand extends EditorCommand {
  const AddPageCommand({required this.page, this.index});

  final StoryPage page;
  final int? index;

  @override
  String get description => 'Add Page';

  @override
  StoryProject execute(StoryProject project) {
    final pages = List<StoryPage>.from(project.pages);
    if (index != null && index! >= 0 && index! <= pages.length) {
      pages.insert(index!, page);
    } else {
      pages.add(page);
    }
    return project.copyWith(pages: pages);
  }

  @override
  StoryProject undo(StoryProject project) {
    return project.copyWith(
      pages: project.pages.where((p) => p.id != page.id).toList(),
    );
  }
}

/// Removes a page from the project.
class RemovePageCommand extends EditorCommand {
  const RemovePageCommand({required this.page, required this.index});

  final StoryPage page;
  final int index;

  @override
  String get description => 'Remove Page';

  @override
  StoryProject execute(StoryProject project) {
    if (project.pages.length <= 1) {
      return project; // Guard: preserve at least 1 page
    }
    return project.copyWith(
      pages: project.pages.where((p) => p.id != page.id).toList(),
    );
  }

  @override
  StoryProject undo(StoryProject project) {
    final pages = List<StoryPage>.from(project.pages);
    final insertAt = index.clamp(0, pages.length);
    pages.insert(insertAt, page);
    return project.copyWith(pages: pages);
  }
}

/// Duplicates an existing page and all of its elements with fresh IDs.
class DuplicatePageCommand extends EditorCommand {
  const DuplicatePageCommand({
    required this.sourcePageId,
    required this.duplicatedPage,
    required this.insertIndex,
  });

  final String sourcePageId;
  final StoryPage duplicatedPage;
  final int insertIndex;

  @override
  String get description => 'Duplicate Page';

  @override
  StoryProject execute(StoryProject project) {
    final pages = List<StoryPage>.from(project.pages);
    final at = insertIndex.clamp(0, pages.length);
    pages.insert(at, duplicatedPage);
    return project.copyWith(pages: pages);
  }

  @override
  StoryProject undo(StoryProject project) {
    return project.copyWith(
      pages: project.pages.where((p) => p.id != duplicatedPage.id).toList(),
    );
  }
}

/// Changes the background color or media asset of a page.
class SetPageBackgroundCommand extends EditorCommand {
  const SetPageBackgroundCommand({
    required this.pageId,
    required this.previousColor,
    required this.newColor,
    this.previousAsset,
    this.newAsset,
  });

  final String pageId;
  final Color previousColor;
  final Color newColor;
  final StoryMediaAsset? previousAsset;
  final StoryMediaAsset? newAsset;

  @override
  String get description => 'Change Background';

  @override
  StoryProject execute(StoryProject project) {
    return _modifyPage(project, pageId, (page) {
      return page.copyWith(
        backgroundColor: newColor,
        backgroundAsset: newAsset,
        clearBackgroundAsset: newAsset == null,
      );
    });
  }

  @override
  StoryProject undo(StoryProject project) {
    return _modifyPage(project, pageId, (page) {
      return page.copyWith(
        backgroundColor: previousColor,
        backgroundAsset: previousAsset,
        clearBackgroundAsset: previousAsset == null,
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

StoryProject _modifyPage(
  StoryProject project,
  String pageId,
  StoryPage Function(StoryPage page) modifier,
) {
  final pages =
      project.pages.map((p) {
        if (p.id == pageId) return modifier(p);
        return p;
      }).toList();
  return project.copyWith(pages: pages);
}

StoryProject _modifyElement(
  StoryProject project,
  String pageId,
  String elementId,
  StoryElement Function(StoryElement el) modifier,
) {
  return _modifyPage(project, pageId, (page) {
    final elements =
        page.elements.map((el) {
          if (el.id == elementId) return modifier(el);
          return el;
        }).toList();
    return page.copyWith(elements: elements);
  });
}
