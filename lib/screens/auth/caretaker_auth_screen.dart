import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/app_translations.dart';
import '../../navigation/app_shell.dart';
import '../../services/app_assets.dart';
import '../../state/app_settings.dart';
import '../../state/auth_state.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_scale_button.dart';
import '../../widgets/fx/fade_slide_in.dart';
import '../../widgets/language_selection_modal.dart';
import '../caretaker/caretaker_dashboard_screen.dart';
import 'patient_registration_screen.dart';

class CaretakerAuthScreen extends StatefulWidget {
  const CaretakerAuthScreen({super.key});

  @override
  State<CaretakerAuthScreen> createState() => _CaretakerAuthScreenState();
}

class _CaretakerAuthScreenState extends State<CaretakerAuthScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ambient; // floating backdrop orbs
  late final AnimationController _tabSlideController; // synchronized tab + form slide
  late final Animation<double> _tabSlideCurve;

  int _authMode = 0; // 0 = Log In, 1 = Sign Up

  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _signupNameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPhoneController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  String _selectedRelationship = 'Daughter';
  final _elderlyPassKeyController = TextEditingController();
  bool _isSeniorLoading = false;
  bool _isCaretakerLoading = false;
  bool _obscureLoginPassword = true;
  bool _obscureSignupPassword = true;

  AuthScreenTranslation get _auth {
    final language = AppSettingsScope.of(context).language;
    return AppTranslations.getAuth(language);
  }

  final List<String> _relationships = [
    'Daughter',
    'Son',
    'Spouse / Partner',
    'Grandchild',
    'Professional Caregiver',
    'Doctor / Nurse',
    'Other Relative / Friend',
  ];

  @override
  void initState() {
    super.initState();

    _ambient = AnimationController(
      duration: const Duration(seconds: 16),
      vsync: this,
    )..repeat();

    _tabSlideController = AnimationController(
      duration: const Duration(milliseconds: 320),
      vsync: this,
    );

    _tabSlideCurve = CurvedAnimation(
      parent: _tabSlideController,
      curve: Curves.easeInOutCubic,
    );
  }

  void _setAuthMode(int mode) {
    if (_authMode == mode) return;
    setState(() {
      _authMode = mode;
    });
    if (mode == 1) {
      _tabSlideController.forward();
    } else {
      _tabSlideController.reverse();
    }
  }

  @override
  void dispose() {
    _ambient.dispose();
    _tabSlideController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupNameController.dispose();
    _signupEmailController.dispose();
    _signupPhoneController.dispose();
    _signupPasswordController.dispose();
    _elderlyPassKeyController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final auth = AuthScope.of(context);
    final emailOrPhone = _loginEmailController.text.trim();
    if (emailOrPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_auth.emailEmptyError),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius14)),
        ),
      );
      return;
    }

    setState(() => _isCaretakerLoading = true);
    final password = _loginPasswordController.text.trim();
    final error = await auth.loginCaretaker(
      emailOrPhone: emailOrPhone,
      passwordOrPin: password.isNotEmpty ? password : null,
    );
    setState(() => _isCaretakerLoading = false);

    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius14)),
        ),
      );
      return;
    }

    _routeAfterAuth(auth);
  }

  Future<void> _handleSignUp() async {
    final auth = AuthScope.of(context);
    final name = _signupNameController.text.trim();
    final email = _signupEmailController.text.trim();
    final phone = _signupPhoneController.text.trim();
    final password = _signupPasswordController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_auth.nameEmptyError),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius14)),
        ),
      );
      return;
    }

    setState(() => _isCaretakerLoading = true);
    final error = await auth.signUpCaretaker(
      name: name,
      email: email.isNotEmpty ? email : 'care@smirithi.org',
      phone: phone.isNotEmpty ? phone : '+91 90000 00000',
      relationship: _selectedRelationship,
      password: password,
    );
    setState(() => _isCaretakerLoading = false);

    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius14)),
        ),
      );
      return;
    }

    _routeAfterAuth(auth);
  }

  Future<void> _loginElderlyWithCode([String? directCode]) async {
    final code = directCode ?? _elderlyPassKeyController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_auth.passKeyEmptyError),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius14)),
        ),
      );
      return;
    }

    setState(() => _isSeniorLoading = true);
    final auth = AuthScope.of(context);
    final success = await auth.loginAsPatientWithCode(code);
    setState(() => _isSeniorLoading = false);

    if (!mounted) return;

    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AppShell()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Pass key not found. Please check with your caretaker.',
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius14)),
        ),
      );
    }
  }

  void _routeAfterAuth(AuthState auth) {
    if (auth.registeredPatients.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const PatientRegistrationScreen(isInitialSetup: true),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const CaretakerDashboardScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    final settings = AppSettingsScope.of(context);
    final currentLang = AppTranslations.getLanguageInfo(settings.language);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5EE),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded,
                    color: AppTheme.deepForest, size: 26),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                gradient: AppTheme.emeraldGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.forest.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: AppAssets.logo(
                  fit: BoxFit.contain,
                  fallbackSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Smriti Saathi',
              style: GoogleFonts.playfairDisplay(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppTheme.deepForest,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: AnimatedScaleButton(
              onTap: () => LanguageSelectionModal.show(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  border: Border.all(
                    color: AppTheme.forest.withValues(alpha: 0.18),
                    width: 1.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.forest.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.translate_rounded,
                        size: 14, color: AppTheme.forest),
                    const SizedBox(width: 5),
                    Text(
                      currentLang.id.toUpperCase(),
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.deepForest,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Animated 3-color botanical glass backdrop (Forest, Amber, Coral)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _ambient,
              builder: (context, _) => CustomPaint(
                painter: _AuthBackdropPainter(_ambient.value),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Unified Flagship Glassmorphic Caretaker Portal Card
                  FadeSlideIn(
                    delay: AppMotion.staggerDelay(0),
                    child: _glass(
                      radius: AppTheme.radius28,
                      tint: AppTheme.forest,
                      strong: true,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Portal Header Lockup
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: AppTheme.emeraldGradient,
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radius16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.forest
                                          .withValues(alpha: 0.28),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.verified_user_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _auth.portalTitle,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.deepForest,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _auth.portalSubtitle,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.muted,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // Sliding Capsule Pill Tab Switcher
                          _buildTabSwitcher(),

                          const SizedBox(height: 22),

                          // Buttery-smooth form area using AnimatedCrossFade + directional slide
                          _buildFormArea(),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 26),

                  // Tri-color Themed Section Divider (Coral & Warm Amber)
                  FadeSlideIn(
                    delay: AppMotion.staggerDelay(2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.coral.withValues(alpha: 0.0),
                                  AppTheme.coral.withValues(alpha: 0.28),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFFBE7E0).withValues(alpha: 0.9),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusFull),
                            border: Border.all(
                              color: AppTheme.coral.withValues(alpha: 0.28),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.coral.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.elderly_rounded,
                                  size: 16, color: AppTheme.coral),
                              const SizedBox(width: 6),
                              Text(
                                _auth.seniorCompanionLabel,
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF9E432A),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.coral.withValues(alpha: 0.28),
                                  AppTheme.coral.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Elderly Pass Key Access Card (Coral Rose & Warm Amber Theme)
                  FadeSlideIn(
                    delay: AppMotion.staggerDelay(3),
                    child: _buildElderlyPassKeySection(),
                  ),

                  const SizedBox(height: 24),

                  // 3-Color Trust Badges Footer
                  FadeSlideIn(
                    delay: AppMotion.staggerDelay(4),
                    child: _buildTrustBadges(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Reusable specular frosted-glass card ──
  Widget _glass({
    required Widget child,
    required double radius,
    Color tint = AppTheme.forest,
    bool strong = false,
    EdgeInsets padding = const EdgeInsets.all(20),
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: strong ? 0.94 : 0.86),
            Colors.white.withValues(alpha: strong ? 0.82 : 0.68),
            tint.withValues(alpha: strong ? 0.04 : 0.02),
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
          width: 1.5,
        ),
        boxShadow: [
          // Soft ambient tint aura
          BoxShadow(
            color: tint.withValues(alpha: 0.1),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          // Specular ground shadow
          BoxShadow(
            color: const Color(0xFF1B3B2B).withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }

  // ── Sliding Capsule Pill Tab Switcher (60fps Synchronized) ──
  Widget _buildTabSwitcher() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final tabWidth = (totalWidth - 8) / 2;

        return AnimatedBuilder(
          animation: _tabSlideCurve,
          builder: (context, _) {
            final t = _tabSlideCurve.value; // 0.0 = Log In, 1.0 = Sign Up

            return Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(AppTheme.radius18),
                border: Border.all(
                  color: AppTheme.forest.withValues(alpha: 0.12),
                  width: 1.1,
                ),
              ),
              child: Stack(
                children: [
                  // Smooth sliding active pill indicator driven by _tabSlideCurve
                  Positioned(
                    left: 4.0 + t * tabWidth,
                    top: 4,
                    bottom: 4,
                    width: tabWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.emeraldGradient,
                        borderRadius: BorderRadius.circular(AppTheme.radius14),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.forest.withValues(alpha: 0.32),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Interactive Tab Targets
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _setAuthMode(0),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.login_rounded,
                                  size: 18,
                                  color: Color.lerp(
                                    Colors.white,
                                    AppTheme.forest,
                                    t,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _auth.logIn,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color.lerp(
                                      Colors.white,
                                      AppTheme.deepForest,
                                      t,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _setAuthMode(1),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_add_alt_1_rounded,
                                  size: 18,
                                  color: Color.lerp(
                                    AppTheme.forest,
                                    Colors.white,
                                    t,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _auth.signUp,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color.lerp(
                                      AppTheme.deepForest,
                                      Colors.white,
                                      t,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Form Area with 60fps Butter Slide + CrossFade ──
  Widget _buildFormArea() {
    return AnimatedBuilder(
      animation: _tabSlideCurve,
      builder: (context, _) {
        final t = _tabSlideCurve.value;

        return AnimatedCrossFade(
          duration: const Duration(milliseconds: 320),
          firstCurve: Curves.easeInOutCubic,
          secondCurve: Curves.easeInOutCubic,
          sizeCurve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
          crossFadeState: _authMode == 0
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Transform.translate(
            offset: Offset(-24 * t, 0),
            child: _buildLoginForm(),
          ),
          secondChild: Transform.translate(
            offset: Offset(24 * (1.0 - t), 0),
            child: _buildSignUpForm(),
          ),
        );
      },
    );
  }

  // ── Color-coded field label with icon squircle badge ──
  Widget _fieldLabel(
    IconData icon,
    String text, {
    required Color accentColor,
    required Color bgColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(icon, size: 14, color: accentColor),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.dmSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.deepForest,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  // ── Unified premium glass input decoration ──
  InputDecoration _fieldDecoration({
    required String hint,
    required IconData prefix,
    required Color accentColor,
    Widget? suffix,
  }) {
    OutlineInputBorder border(Color c, double w) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius16),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTheme.inputHint(),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 12, right: 10),
        child: Icon(prefix, color: accentColor, size: 20),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 46, minHeight: 24),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.88),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border(accentColor.withValues(alpha: 0.16), 1.2),
      enabledBorder: border(accentColor.withValues(alpha: 0.16), 1.2),
      focusedBorder: border(accentColor, 2.0),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      key: const ValueKey('login_form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fieldLabel(
          Icons.badge_outlined,
          _auth.emailOrPhone,
          accentColor: AppTheme.forest,
          bgColor: const Color(0xFFEAF3EC),
        ),
        TextField(
          controller: _loginEmailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          style: AppTheme.inputText(),
          decoration: _fieldDecoration(
            hint: _auth.emailHint,
            prefix: Icons.email_outlined,
            accentColor: AppTheme.forest,
          ),
        ),
        const SizedBox(height: 18),
        _fieldLabel(
          Icons.lock_outline_rounded,
          _auth.passwordLabel,
          accentColor: AppTheme.coral,
          bgColor: const Color(0xFFFBE7E0),
        ),
        TextField(
          controller: _loginPasswordController,
          obscureText: _obscureLoginPassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _handleLogin(),
          style: AppTheme.inputText(),
          decoration: _fieldDecoration(
            hint: _auth.passwordHint,
            prefix: Icons.lock_outline_rounded,
            accentColor: AppTheme.coral,
            suffix: IconButton(
              tooltip: _obscureLoginPassword
                  ? _auth.showPassword
                  : _auth.hidePassword,
              onPressed: () {
                setState(
                    () => _obscureLoginPassword = !_obscureLoginPassword);
              },
              icon: Icon(
                _obscureLoginPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppTheme.coral,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Primary Caretaker Login Button
        AnimatedScaleButton(
          onTap: _isCaretakerLoading ? null : _handleLogin,
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              gradient: AppTheme.emeraldGradient,
              borderRadius: BorderRadius.circular(AppTheme.radius18),
              boxShadow: AppTheme.buttonGlow,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isCaretakerLoading)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                else ...[
                  const Icon(Icons.login_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _auth.logInAsCaretaker,
                    style: AppTheme.buttonText(fontSize: 16),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Switch to Sign Up Link
        Center(
          child: AnimatedScaleButton(
            onTap: () => _setAuthMode(1),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: AppTheme.muted,
                  ),
                  children: [
                    const TextSpan(text: 'New caretaker? '),
                    TextSpan(
                      text: 'Create account here',
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.forest,
                        decoration: TextDecoration.underline,
                        decorationColor: AppTheme.forest.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpForm() {
    return Column(
      key: const ValueKey('signup_form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fieldLabel(
          Icons.person_outline_rounded,
          _auth.yourFullName,
          accentColor: AppTheme.forest,
          bgColor: const Color(0xFFEAF3EC),
        ),
        TextField(
          controller: _signupNameController,
          textInputAction: TextInputAction.next,
          style: AppTheme.inputText(),
          decoration: _fieldDecoration(
            hint: 'e.g. Meena Raman',
            prefix: Icons.person_outline,
            accentColor: AppTheme.forest,
          ),
        ),
        const SizedBox(height: 16),
        _fieldLabel(
          Icons.family_restroom_rounded,
          _auth.relationshipToPatient,
          accentColor: const Color(0xFFB88230),
          bgColor: const Color(0xFFFDF7EA),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(AppTheme.radius16),
            border: Border.all(
              color: AppTheme.warmAmber.withValues(alpha: 0.3),
              width: 1.2,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedRelationship,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFFB88230)),
              items: _relationships.map((rel) {
                return DropdownMenuItem(
                  value: rel,
                  child: Text(
                    rel,
                    style: GoogleFonts.dmSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.deepForest,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedRelationship = val);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        _fieldLabel(
          Icons.phone_outlined,
          _auth.phoneAndEmail,
          accentColor: AppTheme.forest,
          bgColor: const Color(0xFFEAF3EC),
        ),
        TextField(
          controller: _signupPhoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          style: AppTheme.inputText(),
          decoration: _fieldDecoration(
            hint: _auth.phoneHint,
            prefix: Icons.phone_outlined,
            accentColor: AppTheme.forest,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _signupEmailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          style: AppTheme.inputText(),
          decoration: _fieldDecoration(
            hint: _auth.emailHintSignup,
            prefix: Icons.email_outlined,
            accentColor: AppTheme.forest,
          ),
        ),
        const SizedBox(height: 16),
        _fieldLabel(
          Icons.lock_outline_rounded,
          _auth.passwordLabel,
          accentColor: AppTheme.coral,
          bgColor: const Color(0xFFFBE7E0),
        ),
        TextField(
          controller: _signupPasswordController,
          obscureText: _obscureSignupPassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _handleSignUp(),
          style: AppTheme.inputText(),
          decoration: _fieldDecoration(
            hint: 'Create 4-digit PIN or password',
            prefix: Icons.lock_outline_rounded,
            accentColor: AppTheme.coral,
            suffix: IconButton(
              tooltip: _obscureSignupPassword
                  ? _auth.showPassword
                  : _auth.hidePassword,
              onPressed: () {
                setState(
                    () => _obscureSignupPassword = !_obscureSignupPassword);
              },
              icon: Icon(
                _obscureSignupPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppTheme.coral,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.shield_outlined,
                size: 14, color: AppTheme.forest.withValues(alpha: 0.7)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'PIN & health data are encrypted strictly on-device',
                style: GoogleFonts.dmSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.muted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),

        // Primary Caretaker Sign Up Button
        AnimatedScaleButton(
          onTap: _isCaretakerLoading ? null : _handleSignUp,
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              gradient: AppTheme.emeraldGradient,
              borderRadius: BorderRadius.circular(AppTheme.radius18),
              boxShadow: AppTheme.buttonGlow,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isCaretakerLoading)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                else ...[
                  const Icon(Icons.how_to_reg_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _auth.createCaretakerAccount,
                    style: AppTheme.buttonText(fontSize: 16),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Switch to Log In Link
        Center(
          child: AnimatedScaleButton(
            onTap: () => _setAuthMode(0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: AppTheme.muted,
                  ),
                  children: [
                    const TextSpan(text: 'Already registered? '),
                    TextSpan(
                      text: 'Log in here',
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.forest,
                        decoration: TextDecoration.underline,
                        decorationColor: AppTheme.forest.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Elderly Pass Key Access Section (Coral Rose & Warm Amber Themed) ──
  Widget _buildElderlyPassKeySection() {
    return _glass(
      radius: AppTheme.radius28,
      tint: AppTheme.coral,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFDE8E1),
                      Color(0xFFFBF1DC),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.coral.withValues(alpha: 0.28),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.coral.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.key_rounded,
                  color: AppTheme.coral,
                  size: 25,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _auth.enterAsSenior,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.deepForest,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Use the pass key your family gave you to begin.',
                      style: GoogleFonts.dmSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // High-contrast, large passkey input
          TextField(
            controller: _elderlyPassKeyController,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.characters,
            onSubmitted: (_) => _loginElderlyWithCode(),
            style: GoogleFonts.dmSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 3.0,
              color: AppTheme.deepForest,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: _auth.passKeyHint,
              hintStyle: AppTheme.inputHint(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.9),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radius18),
                borderSide: BorderSide(
                  color: AppTheme.coral.withValues(alpha: 0.25),
                  width: 1.3,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radius18),
                borderSide: BorderSide(
                  color: AppTheme.coral.withValues(alpha: 0.25),
                  width: 1.3,
                ),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(AppTheme.radius18)),
                borderSide: BorderSide(
                  color: AppTheme.coral,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Start Senior Companion Button
          AnimatedScaleButton(
            onTap: _isSeniorLoading ? null : () => _loginElderlyWithCode(),
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppTheme.forest,
                    AppTheme.emerald,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radius18),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.forest.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: _isSeniorLoading
                  ? const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.play_circle_filled_rounded,
                            size: 22, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          _auth.startSeniorCompanion,
                          style: AppTheme.buttonText(fontSize: 16),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 3-Color Trust Badges ──
  Widget _buildTrustBadges() {
    Widget badge(IconData icon, String label, Color color, Color bg) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: color.withValues(alpha: 0.22),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: [
          badge(Icons.security_rounded, '100% Private', AppTheme.forest,
              const Color(0xFFEAF3EC)),
          badge(Icons.offline_bolt_rounded, 'Offline AI',
              const Color(0xFFB88230), const Color(0xFFFDF7EA)),
          badge(Icons.sync_rounded, 'Family Synced', AppTheme.coral,
              const Color(0xFFFBE7E0)),
        ],
      ),
    );
  }
}

// ── Animated 3-Color Botanical Glass Backdrop ──
class _AuthBackdropPainter extends CustomPainter {
  _AuthBackdropPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    // Base warm botanical wash
    final base = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFCFAF5),
          Color(0xFFF5F8F2),
          Color(0xFFEDF4EC),
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, base);

    final tau = t * 2 * math.pi;

    // 1. Floating Emerald Green Orb (top-left)
    _orb(
      canvas,
      Offset(
        size.width * (0.18 + 0.06 * math.sin(tau)),
        size.height * (0.16 + 0.05 * math.cos(tau)),
      ),
      size.width * 0.44,
      AppTheme.emerald.withValues(alpha: 0.16),
    );

    // 2. Floating Warm Amber Orb (mid-right)
    _orb(
      canvas,
      Offset(
        size.width * (0.84 + 0.05 * math.cos(tau * 0.8)),
        size.height * (0.42 + 0.06 * math.sin(tau * 0.8)),
      ),
      size.width * 0.46,
      AppTheme.warmAmber.withValues(alpha: 0.14),
    );

    // 3. Floating Coral Rose Orb (mid-left & lower)
    _orb(
      canvas,
      Offset(
        size.width * (0.15 + 0.05 * math.cos(tau * 1.1)),
        size.height * (0.75 + 0.05 * math.sin(tau * 1.1)),
      ),
      size.width * 0.42,
      AppTheme.coral.withValues(alpha: 0.13),
    );

    // 4. Soft Deep Forest base aura (bottom-center)
    _orb(
      canvas,
      Offset(
        size.width * (0.55 + 0.04 * math.sin(tau * 1.3)),
        size.height * (0.94 + 0.03 * math.cos(tau)),
      ),
      size.width * 0.52,
      AppTheme.forest.withValues(alpha: 0.09),
    );
  }

  void _orb(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 65)
      ..shader = RadialGradient(
        colors: [color, color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _AuthBackdropPainter oldDelegate) =>
      oldDelegate.t != t;
}
