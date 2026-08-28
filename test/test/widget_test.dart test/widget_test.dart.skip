import 'package:flutter_test/flutter_test.dart';

import 'package:my_note_app/main.dart';

void main() {
  testWidgets('Notebook app can add a note', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('我的笔记本'), findsOneWidget);
    expect(find.byKey(const ValueKey('add_note_fab')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('add_note_fab')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('title_field')), '周末散步');
    await tester.enterText(
      find.byKey(const ValueKey('content_field')),
      '去公园散步，记录一下灵感和想法。',
    );

    await tester.tap(find.byKey(const ValueKey('save_note_button')));
    await tester.pumpAndSettle();

    expect(find.text('周末散步'), findsOneWidget);
    expect(find.text('去公园散步，记录一下灵感和想法。'), findsOneWidget);
  });
}
