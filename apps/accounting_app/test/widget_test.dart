// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:accounting_app/widgets/payment_method_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:accounting_app/main.dart';

void _noop(String? _) {}

String? _requiredPaymentMethod(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Payment method is required.';
  }
  return null;
}

void main() {
  testWidgets('App loads auth gate without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const AccountingApp());

    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Payment method field requires a selection', (WidgetTester tester) async {
    final formKey = GlobalKey<FormState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: const PaymentMethodField(
              value: null,
              onChanged: _noop,
              validator: _requiredPaymentMethod,
            ),
          ),
        ),
      ),
    );

    final isValid = formKey.currentState!.validate();
    expect(isValid, isFalse);
  });
}
