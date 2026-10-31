import 'package:flutter/foundation.dart';

/// Centralized localizable string bundle for all Story Kit UI elements.
///
/// Injected into [StoryKitEditor] to support localization, RTL translations,
/// and custom brand terminology.
@immutable
class StoryKitStrings {
  const StoryKitStrings({
    this.closeEditor = 'Close Editor',
    this.undo = 'Undo',
    this.redo = 'Redo',
    this.addText = 'Add Text',
    this.addSticker = 'Add Sticker',
    this.addShape = 'Add Shape',
    this.draw = 'Draw',
    this.adjust = 'Adjust',
    this.changeBackground = 'Change Background',
    this.layers = 'Layers',
    this.templates = 'Templates',
    this.togglePageStrip = 'Toggle Page Strip',
    this.saveDraft = 'Save Draft',
    this.draftSaved = 'Draft saved successfully',
    this.export = 'Export',
    this.exportingStory = 'Exporting story...',
    this.solidColors = 'Solid Colors',
    this.gradients = 'Gradients',
    this.delete = 'Delete',
    this.bringForward = 'Bring Forward',
    this.sendBackward = 'Send Backward',
  });

  final String closeEditor;
  final String undo;
  final String redo;
  final String addText;
  final String addSticker;
  final String addShape;
  final String draw;
  final String adjust;
  final String changeBackground;
  final String layers;
  final String templates;
  final String togglePageStrip;
  final String saveDraft;
  final String draftSaved;
  final String export;
  final String exportingStory;
  final String solidColors;
  final String gradients;
  final String delete;
  final String bringForward;
  final String sendBackward;

  static const en = StoryKitStrings();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryKitStrings &&
          runtimeType == other.runtimeType &&
          closeEditor == other.closeEditor &&
          undo == other.undo &&
          redo == other.redo &&
          addText == other.addText &&
          addSticker == other.addSticker &&
          addShape == other.addShape &&
          draw == other.draw &&
          adjust == other.adjust &&
          changeBackground == other.changeBackground &&
          layers == other.layers &&
          templates == other.templates &&
          togglePageStrip == other.togglePageStrip &&
          saveDraft == other.saveDraft &&
          draftSaved == other.draftSaved &&
          export == other.export &&
          exportingStory == other.exportingStory;

  @override
  int get hashCode => Object.hash(
    closeEditor,
    undo,
    redo,
    addText,
    addSticker,
    addShape,
    draw,
    adjust,
    changeBackground,
    layers,
    templates,
    togglePageStrip,
    saveDraft,
    draftSaved,
    export,
    exportingStory,
  );
}
