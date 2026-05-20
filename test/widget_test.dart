// Basic Flutter widget test for IntegraTax.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:integratax/main.dart';

void main() {
  testWidgets('IntegraTax initial UI smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Sama seperti di main.dart, kita wajib membungkusnya dengan ProviderScope
    await tester.pumpWidget(const ProviderScope(child: IntegraTaxApp()));

    await tester.pump(const Duration(milliseconds: 1300));

    expect(find.text('INTEGRATAX.'), findsOneWidget);
    expect(find.text('Masuk Dashboard'), findsOneWidget);

    await tester.tap(find.text('Masuk Dashboard'));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 1300));

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Notifikasi'), findsOneWidget);
    expect(find.text('Approval'), findsOneWidget);
    expect(find.text('Log'), findsOneWidget);
  });
}
