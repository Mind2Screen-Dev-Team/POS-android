import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:pos_android/features/products/product_list.dart';

void main() {
  testWidgets('ProductList renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ProductList()));
    expect(find.byType(ProductList), findsOneWidget);
  });

  testWidgets('AppBar shows Products title', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ProductList()));
    expect(find.text('Products'), findsOneWidget);
  });
}
