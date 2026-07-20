import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'controllers/app_controller.dart';
import 'core/theme/app_theme.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/shell/app_shell.dart';

class EnglishForgeApp extends StatelessWidget {
  const EnglishForgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EnglishForge',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: controller.themeMode,
      locale: const Locale('pt'),
      supportedLocales: const [Locale('pt'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: controller.loading
          ? const _LoadingView()
          : controller.errorMessage != null
              ? _ErrorView(message: controller.errorMessage!)
              : controller.onboardingComplete
                  ? const AppShell()
                  : const OnboardingScreen(),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 64),
                  const SizedBox(height: 16),
                  Text('Não foi possível iniciar o EnglishForge.',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  SelectableText(message),
                ],
              ),
            ),
          ),
        ),
      );
}
