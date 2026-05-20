// Basic Flutter widget test for IntegraTax.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:integratax/main.dart';

void main() {
  testWidgets('IntegraTax initial UI smoke test', (WidgetTester tester) async {
    await _pumpLoggedInApp(tester);

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Notifikasi'), findsOneWidget);
    expect(find.text('Approval'), findsOneWidget);
    expect(find.text('Log'), findsOneWidget);
    expect(find.text('MODE DEMO'), findsOneWidget);
    expect(find.byTooltip('SIMPBB Explorer'), findsNothing);
  });

  testWidgets('Approval actions update dummy state', (tester) async {
    await _pumpLoggedInApp(tester);
    await tester.tap(find.text('Approval'));
    await tester.pump();

    await tester.tap(find.text('Setujui').first);
    await tester.pump();

    expect(find.text('Status: Disetujui'), findsOneWidget);
  });

  testWidgets('Approval reject requires a reason', (tester) async {
    await _pumpLoggedInApp(tester);
    await tester.tap(find.text('Approval'));
    await tester.pump();

    await tester.tap(find.text('Tolak').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Tolak'));
    await tester.pump();

    expect(find.text('Alasan minimal 10 karakter.'), findsOneWidget);
  });

  testWidgets('Log filter shows failed logs only', (tester) async {
    await _pumpLoggedInApp(tester);
    await tester.tap(find.text('Log'));
    await tester.pump();

    expect(find.text('BPN'), findsOneWidget);
    expect(find.text('BPJS'), findsOneWidget);

    await tester.tap(find.text('Gagal').first);
    await tester.pump();

    expect(find.text('BPJS'), findsOneWidget);
    expect(find.text('BPN'), findsNothing);
  });
}

Future<void> _pumpLoggedInApp(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: IntegraTaxApp()));
  await tester.pump(const Duration(milliseconds: 1300));

  expect(find.text('INTEGRATAX.'), findsOneWidget);
  expect(find.text('Masuk Dashboard'), findsOneWidget);

  await tester.tap(find.text('Masuk Dashboard'));
  await tester.pump(const Duration(milliseconds: 700));
  await tester.pump(const Duration(milliseconds: 1300));
}
