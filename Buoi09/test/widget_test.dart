import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/views/expense_screen.dart';

void main() {
  testWidgets('Expense screen opens without setState Future assertion', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ExpenseScreen()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Quản lý chi tiêu'), findsOneWidget);
  });
  testWidgets('Menu displays four exercises and opens login', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Bài 09: SQLite'), findsOneWidget);
    expect(find.byType(ListTile), findsNWidgets(4));
    await tester.tap(find.text('Tài khoản: bài 2 về nhà'));
    await tester.pumpAndSettle();
    expect(find.text('Đăng nhập'), findsOneWidget);
  });
  testWidgets('Expense form validates content and amount', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ExpenseDialog()));
    await tester.tap(find.text('Lưu'));
    await tester.pump();
    expect(find.text('Không được để trống.'), findsOneWidget);
    expect(
      find.text('Số tiền phải là số nguyên dương, tối đa 1.000.000.000.000.'),
      findsOneWidget,
    );
  });
}
