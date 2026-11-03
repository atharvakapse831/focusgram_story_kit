import 'package:flutter_test/flutter_test.dart';
import 'package:example/main.dart';

void main() {
  testWidgets('StoryKitExampleApp launches and displays showcase UI', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const StoryKitExampleApp());
    await tester.pumpAndSettle();

    expect(find.text('FocusGram Story Kit Showcase'), findsOneWidget);
    expect(find.text('FocusGram Phase 5 Production Story'), findsOneWidget);
    expect(find.byTooltip('Export MP4'), findsOneWidget);
  });
}
