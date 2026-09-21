import 'package:flutter/material.dart';

import 'navigation/app_shell.dart';
import 'screens/caretaker/caretaker_dashboard_screen.dart';
import 'screens/onboarding_screen.dart';
import 'state/app_settings.dart';
import 'state/auth_session.dart';
import 'state/auth_state.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmirithiSaathiApp());
}

class SmirithiSaathiApp extends StatefulWidget {
  const SmirithiSaathiApp({super.key});

  @override
  State<SmirithiSaathiApp> createState() => _SmirithiSaathiAppState();
}

class _SmirithiSaathiAppState extends State<SmirithiSaathiApp> {
  final AppSettings _settings = AppSettings();
  final AuthState _auth = AuthState();
  final AuthSession _legacySession = AuthSession();

  @override
  Widget build(BuildContext context) {
    return AppSettingsScope(
      settings: _settings,
      child: AuthScope(
        auth: _auth,
        child: AuthSessionScope(
          session: _legacySession,
          child: ListenableBuilder(
            listenable: Listenable.merge([_settings, _auth]),
            builder: (context, _) {
              return MaterialApp(
                title: 'Smriti Saathi',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light,
                builder: (context, child) {
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(_settings.textScale),
                    ),
                    child: child ?? const SizedBox.shrink(),
                  );
                },
                home: _getInitialScreen(),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _getInitialScreen() {
    if (!_auth.isInitialized) {
      return const Scaffold(
        backgroundColor: AppTheme.cream,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.forest),
        ),
      );
    }

    if (_auth.isCaretaker) {
      return const CaretakerDashboardScreen();
    } else if (_auth.isPatient) {
      return const AppShell();
    } else {
      return const OnboardingScreen();
    }
  }
}
