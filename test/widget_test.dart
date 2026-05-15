// Basic Flutter widget test for IntegraTax.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:integratax/main.dart';

void main() {
  testWidgets('IntegraTax initial UI smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Sama seperti di main.dart, kita wajib membungkusnya dengan ProviderScope
    await tester.pumpWidget(const ProviderScope(child: IntegraTaxApp()));

    // Memastikan teks placeholder yang kita buat di main.dart muncul di layar
    expect(
      find.textContaining('Mesin IntegraTax sudah menyala!'),
      findsOneWidget,
    );
  });
}
