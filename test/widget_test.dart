import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_manager/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Editorial Manager shows authentication screen', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const EditorialManagerApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.text('Editorial Manager'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Crear usuario'), findsNothing);
  });

  testWidgets('Temporary login accepts any email and password', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const EditorialManagerApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(find.byType(TextFormField).at(0), 'lo-que-sea');
    await tester.enterText(find.byType(TextFormField).at(1), 'x');
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Editorial Manager'), findsOneWidget);
  });
}
