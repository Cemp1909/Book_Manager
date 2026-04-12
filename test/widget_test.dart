import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_manager/main.dart';

void main() {
  testWidgets('Editorial Manager app test', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const EditorialManagerApp());

    // Wait for app to load
    await tester.pumpAndSettle();

    // Verify that the app loads without errors
    expect(find.byType(Scaffold), findsOneWidget);

    // Verify that the bottom navigation bar exists
    expect(find.byType(NavigationBar), findsOneWidget);

    // Verify that the app bar exists
    expect(find.byType(AppBar), findsOneWidget);
  });
}
