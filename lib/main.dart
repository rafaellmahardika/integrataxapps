import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'screens/app_gate.dart';

void main() {
  runApp(const ProviderScope(child: IntegraTaxApp()));
}

class IntegraTaxApp extends StatelessWidget {
  const IntegraTaxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IntegraTax Dashboard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const AppGate(),
    );
  }
}
