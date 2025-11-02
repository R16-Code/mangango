// Basic smoke test for Mangan Go.
// Menghindari referensi ke MyApp (tidak ada di project).
// Kita cukup memastikan App bisa dirender tanpa crash.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangango/app.dart';

void main() {
  testWidgets('App renders without crashing and shows title text', (WidgetTester tester) async {
    // Render aplikasi utama
    await tester.pumpWidget(const App());

    // Biarkan satu frame pertama berjalan
    await tester.pump();

    // Cek adanya teks "Mangan Go" (muncul di SplashGate)
    expect(find.textContaining('Mangan Go'), findsWidgets);

    // Opsional: pastikan tidak ada error widget dasar
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
