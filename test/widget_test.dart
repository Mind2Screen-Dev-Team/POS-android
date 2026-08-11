import 'package:flutter_test/flutter_test.dart';

import 'package:pos_android/app.dart';

void main() {
  testWidgets('POS Penglaris renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const PosApp());

    expect(find.text('POS Penglaris'), findsWidgets);
    expect(find.text('POS Penglaris — home screen placeholder'), findsOneWidget);
  });
}