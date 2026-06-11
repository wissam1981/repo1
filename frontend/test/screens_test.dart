import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:contract_english_trainer/models/contract.dart';
import 'package:contract_english_trainer/providers/contracts_provider.dart';
import 'package:contract_english_trainer/providers/locale_provider.dart';
import 'package:contract_english_trainer/providers/quizzes_provider.dart';
import 'package:contract_english_trainer/providers/tutor_provider.dart';
import 'package:contract_english_trainer/providers/vocabulary_provider.dart';
import 'package:contract_english_trainer/screens/clause_study.dart';
import 'package:contract_english_trainer/screens/dashboard.dart';
import 'package:contract_english_trainer/screens/vocabulary.dart';
import 'package:contract_english_trainer/services/api_client.dart';
import 'package:contract_english_trainer/theme.dart';

/// An ApiClient that always fails fast, so screens settle into their empty /
/// error states without making real network calls during widget tests.
ApiClient _offlineClient() =>
    ApiClient(baseUrl: 'http://127.0.0.1:1', getToken: () async => null);

Widget _wrap(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ChangeNotifierProvider(
          create: (_) => ContractsProvider(_offlineClient())),
      ChangeNotifierProvider(
          create: (_) => VocabularyProvider(_offlineClient())),
      ChangeNotifierProvider(create: (_) => QuizzesProvider(_offlineClient())),
      ChangeNotifierProvider(create: (_) => TutorProvider(_offlineClient())),
    ],
    child: MaterialApp(theme: buildAppTheme(), home: child),
  );
}

void main() {
  testWidgets('VocabularyScreen shows Arabic title and empty state',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const VocabularyScreen()));
    await tester.pumpAndSettle();
    expect(find.text('مفرداتي'), findsOneWidget);
  });

  testWidgets('DashboardScreen shows progress stats and actions',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const DashboardScreen()));
    await tester.pump();
    expect(find.text('تقدّمي'), findsOneWidget);
    expect(find.text('بنود مكتملة'), findsOneWidget);
    expect(find.text('راجع كلماتك'), findsOneWidget);
    expect(find.text('اسأل المعلّم'), findsOneWidget);
  });

  testWidgets('ClauseStudyScreen shows stages and tappable clause text',
      (WidgetTester tester) async {
    final contract = Contract(id: 1, title: 'T', clauses: const []);
    final clause = Clause(
      id: 10,
      order: 1,
      originalText: 'The term of this Agreement is twelve months.',
      simpleEn: 'It lasts one year.',
      arabic: 'مدتها سنة واحدة.',
    );
    await tester.pumpWidget(
        _wrap(ClauseStudyScreen(contract: contract, clause: clause)));
    await tester.pump();
    expect(find.text('اقرأ'), findsOneWidget);
    expect(find.text('افهم'), findsOneWidget);
    expect(find.text('اختبر'), findsOneWidget);
    expect(find.text('Agreement'), findsOneWidget);
    expect(find.text('twelve'), findsOneWidget);
  });

  testWidgets('ClauseStudyScreen understand stage shows explanations',
      (WidgetTester tester) async {
    final contract = Contract(id: 1, title: 'T', clauses: const []);
    final clause = Clause(
      id: 10,
      order: 1,
      originalText: 'Payment is due monthly.',
      simpleEn: 'You pay every month.',
      arabic: 'تدفع كل شهر.',
      keyTerms: [KeyTerm(term: 'Payment', meaning: 'Money you give')],
    );
    await tester.pumpWidget(
        _wrap(ClauseStudyScreen(contract: contract, clause: clause)));
    await tester.pump();
    await tester.tap(find.textContaining('افهم').last);
    await tester.pump();
    expect(find.text('You pay every month.'), findsOneWidget);
    expect(find.text('تدفع كل شهر.'), findsOneWidget);
    expect(find.text('Payment'), findsOneWidget);
  });
}
