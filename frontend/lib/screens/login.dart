import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleProvider>().s;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.gavel, size: 56, color: AppColors.goldLight),
              const SizedBox(height: 14),
              Text(
                s.appTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 20,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                s.journeySubtitle,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: AppColors.textFaint, fontSize: 13),
              ),
              const SizedBox(height: 32),
              // Google/Apple sign-in intentionally hidden until real OAuth
              // is configured — guest is the single entry point for now.
              ElevatedButton.icon(
                onPressed: () => _loginWithGoogle(context),
                icon: const Icon(Icons.g_mobiledata, size: 28), // Placeholder for Google Icon
                label: Text(s.signInGoogle),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _loginWithApple(context),
                icon: const Icon(Icons.apple, size: 28),
                label: Text(s.signInApple),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(color: AppColors.navy700),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _loginAsGuest(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600),
                ),
                child: Text(s.continueGuest),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () =>
                    Provider.of<LocaleProvider>(context, listen: false)
                        .toggle(),
                icon: const Icon(Icons.translate, size: 16),
                label: const Text('ع / EN'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loginAsGuest(BuildContext context) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.loginAsGuest();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('❌ $e')));
    }
  }

  Future<void> _loginWithGoogle(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Sign-In coming soon...')));
  }

  Future<void> _loginWithApple(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Apple Sign-In coming soon...')));
  }
}
