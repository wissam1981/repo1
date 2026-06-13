import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:contract_english_trainer/l10n/strings.dart';
import 'package:contract_english_trainer/providers/auth_provider.dart';
import 'package:contract_english_trainer/providers/locale_provider.dart';
import 'package:contract_english_trainer/screens/login.dart';
import 'package:contract_english_trainer/services/auth_service.dart';
import 'package:contract_english_trainer/theme.dart';

void main() {
  testWidgets('LoginScreen renders guest button and language toggle',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider(AuthService())),
        ],
        child: MaterialApp(theme: buildAppTheme(), home: const LoginScreen()),
      ),
    );
    await tester.pump();
    // Arabic default
    expect(find.text('المتابعة كضيف'), findsOneWidget);
    expect(find.text('ع / EN'), findsOneWidget);

    // Toggle to English
    await tester.tap(find.text('ع / EN'));
    await tester.pump();
    expect(find.text('Continue as Guest'), findsOneWidget);
  });

  test('AppStrings switches between Arabic and English', () {
    const ar = AppStrings('ar');
    const en = AppStrings('en');
    expect(ar.isArabic, isTrue);
    expect(en.isArabic, isFalse);
    expect(ar.todaysClause, 'بند اليوم');
    expect(en.todaysClause, "Today's clause");
    expect(ar.progressOf(7, 60), contains('7'));
    expect(en.progressOf(7, 60), '7 of 60 clauses completed');
  });

  test('LocaleProvider toggles direction', () {
    final p = LocaleProvider();
    expect(p.isArabic, isTrue);
    expect(p.direction, TextDirection.rtl);
    p.toggle();
    expect(p.isArabic, isFalse);
    expect(p.direction, TextDirection.ltr);
  });
}
