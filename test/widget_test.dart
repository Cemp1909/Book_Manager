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

  testWidgets('Stored account can log in with its saved role', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'auth_user_name': 'Ana',
      'auth_user_email': 'ana@test.com',
      'auth_user_role': 'Vendedor',
      'auth_user_password': '123456',
      'auth_logged_in': false,
    });

    await tester.pumpWidget(const EditorialManagerApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(find.byType(TextFormField).at(0), 'ana@test.com');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byIcon(Icons.menu), findsOneWidget);
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.text('Inicio'), findsWidgets);
    expect(find.text('Biblioteca'), findsWidgets);
    expect(find.text('Agregar'), findsNothing);
    expect(find.text('Combos'), findsOneWidget);
    expect(find.text('Pedidos'), findsOneWidget);
    expect(find.text('Despachos'), findsOneWidget);
    expect(find.text('Perfil'), findsWidgets);
  });

  testWidgets('Warehouse role only sees warehouse inventory', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'auth_user_name': 'Bodega',
      'auth_user_email': 'bodega@test.com',
      'auth_user_role': 'Bodeguero',
      'auth_user_password': '123456',
      'auth_logged_in': false,
    });

    await tester.pumpWidget(const EditorialManagerApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'bodega@test.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byIcon(Icons.menu), findsNothing);
    expect(find.text('Inventario de bodega'), findsOneWidget);
    expect(find.text('Editorial Manager'), findsNothing);
    expect(find.text('Combos'), findsNothing);
    expect(find.text('Pedidos'), findsNothing);
    expect(find.text('Despachos'), findsNothing);
  });
}
