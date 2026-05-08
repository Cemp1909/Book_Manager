import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:book_manager/main.dart';

void main() {
  testWidgets('Editorial Manager shows authentication screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const EditorialManagerApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.text('Editorial Manager'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Crear usuario'), findsNothing);
  });
}
