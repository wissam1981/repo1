import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/contracts_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/quizzes_provider.dart';
import 'providers/tutor_provider.dart';
import 'providers/vocabulary_provider.dart';
import 'screens/dashboard.dart';
import 'screens/journey.dart';
import 'screens/login.dart';
import 'screens/splash.dart';
import 'screens/tutor.dart';
import 'screens/vocabulary.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
        ProxyProvider<AuthProvider, ApiClient>(
          update: (_, authProvider, __) => ApiClient(
            getToken: () async => authProvider.token,
          ),
        ),
        ChangeNotifierProxyProvider<ApiClient, ContractsProvider>(
          create: (_) =>
              ContractsProvider(ApiClient(getToken: () async => null)),
          update: (_, apiClient, __) => ContractsProvider(apiClient),
        ),
        ChangeNotifierProxyProvider<ApiClient, VocabularyProvider>(
          create: (_) =>
              VocabularyProvider(ApiClient(getToken: () async => null)),
          update: (_, apiClient, __) => VocabularyProvider(apiClient),
        ),
        ChangeNotifierProxyProvider<ApiClient, QuizzesProvider>(
          create: (_) =>
              QuizzesProvider(ApiClient(getToken: () async => null)),
          update: (_, apiClient, __) => QuizzesProvider(apiClient),
        ),
        ChangeNotifierProxyProvider<ApiClient, TutorProvider>(
          create: (_) => TutorProvider(ApiClient(getToken: () async => null)),
          update: (_, apiClient, __) => TutorProvider(apiClient),
        ),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, locale, _) => MaterialApp(
          title: locale.s.appTitle,
          theme: buildAppTheme(),
          builder: (context, child) => Directionality(
            textDirection: locale.direction,
            child: child ?? const SizedBox.shrink(),
          ),
          home: const SplashScreen(),
          routes: {
            '/login': (_) => const LoginScreen(),
            '/home': (_) => const JourneyScreen(),
            '/dashboard': (_) => const DashboardScreen(),
            '/vocabulary': (_) => const VocabularyScreen(),
            '/tutor': (_) => const TutorScreen(),
          },
        ),
      ),
    );
  }
}
