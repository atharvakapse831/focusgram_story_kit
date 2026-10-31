import 'package:flutter/material.dart';

/// Semantic design tokens for styling and customizing the Story Kit editor UI.
@immutable
class StoryKitEditorTheme {
  const StoryKitEditorTheme({
    this.backgroundColor = Colors.black,
    this.topBarColor = const Color(0xDD111111),
    this.bottomBarColor = const Color(0xDD111111),
    this.sheetBackgroundColor = const Color(0xFF222222),
    this.accentColor = Colors.blueAccent,
    this.primaryIconColor = Colors.white,
    this.secondaryIconColor = Colors.white60,
    this.disabledIconColor = Colors.white24,
    this.dangerColor = Colors.redAccent,
    this.activeSelectionColor = Colors.blueAccent,
    this.canvasBackgroundColor = Colors.black,
    this.toolbarBorderRadius = 16.0,
  });

  final Color backgroundColor;
  final Color topBarColor;
  final Color bottomBarColor;
  final Color sheetBackgroundColor;
  final Color accentColor;
  final Color primaryIconColor;
  final Color secondaryIconColor;
  final Color disabledIconColor;
  final Color dangerColor;
  final Color activeSelectionColor;
  final Color canvasBackgroundColor;
  final double toolbarBorderRadius;

  /// Default dark theme optimized for full-screen immersive media editing.
  static const dark = StoryKitEditorTheme();

  /// Clean light theme option.
  static const light = StoryKitEditorTheme(
    backgroundColor: Color(0xFFEEEEEE),
    topBarColor: Color(0xFFFAFAFA),
    bottomBarColor: Color(0xFFFAFAFA),
    sheetBackgroundColor: Colors.white,
    accentColor: Color(0xFF1976D2),
    primaryIconColor: Colors.black87,
    secondaryIconColor: Colors.black54,
    disabledIconColor: Colors.black26,
    dangerColor: Colors.red,
    activeSelectionColor: Color(0xFF1976D2),
    canvasBackgroundColor: Colors.white,
  );

  StoryKitEditorTheme copyWith({
    Color? backgroundColor,
    Color? topBarColor,
    Color? bottomBarColor,
    Color? sheetBackgroundColor,
    Color? accentColor,
    Color? primaryIconColor,
    Color? secondaryIconColor,
    Color? disabledIconColor,
    Color? dangerColor,
    Color? activeSelectionColor,
    Color? canvasBackgroundColor,
    double? toolbarBorderRadius,
  }) {
    return StoryKitEditorTheme(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      topBarColor: topBarColor ?? this.topBarColor,
      bottomBarColor: bottomBarColor ?? this.bottomBarColor,
      sheetBackgroundColor: sheetBackgroundColor ?? this.sheetBackgroundColor,
      accentColor: accentColor ?? this.accentColor,
      primaryIconColor: primaryIconColor ?? this.primaryIconColor,
      secondaryIconColor: secondaryIconColor ?? this.secondaryIconColor,
      disabledIconColor: disabledIconColor ?? this.disabledIconColor,
      dangerColor: dangerColor ?? this.dangerColor,
      activeSelectionColor: activeSelectionColor ?? this.activeSelectionColor,
      canvasBackgroundColor:
          canvasBackgroundColor ?? this.canvasBackgroundColor,
      toolbarBorderRadius: toolbarBorderRadius ?? this.toolbarBorderRadius,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryKitEditorTheme &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          topBarColor == other.topBarColor &&
          bottomBarColor == other.bottomBarColor &&
          sheetBackgroundColor == other.sheetBackgroundColor &&
          accentColor == other.accentColor &&
          primaryIconColor == other.primaryIconColor &&
          secondaryIconColor == other.secondaryIconColor &&
          disabledIconColor == other.disabledIconColor &&
          dangerColor == other.dangerColor &&
          activeSelectionColor == other.activeSelectionColor &&
          canvasBackgroundColor == other.canvasBackgroundColor &&
          toolbarBorderRadius == other.toolbarBorderRadius;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    topBarColor,
    bottomBarColor,
    sheetBackgroundColor,
    accentColor,
    primaryIconColor,
    secondaryIconColor,
    disabledIconColor,
    dangerColor,
    activeSelectionColor,
    canvasBackgroundColor,
    toolbarBorderRadius,
  );
}
