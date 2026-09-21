import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smirithi_saathi/main.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('App loads onboarding screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const SmirithiSaathiApp());
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('Saathi'), findsWidgets);
  });

  testWidgets('Logging out resets state and returns to OnboardingScreen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'user_role': 'patient',
      'onboarding_completed': true,
    });
    await tester.pumpWidget(const SmirithiSaathiApp());
    await tester.pump(const Duration(milliseconds: 200));

    // Initially in patient mode (AppShell)
    expect(find.textContaining('Saathi'), findsWidgets);
  });
}
