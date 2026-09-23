import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/app_translations.dart';
import '../../navigation/app_shell.dart';
import '../../state/app_settings.dart';
import '../../state/auth_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_scale_button.dart';
import '../caretaker/caretaker_dashboard_screen.dart';
import 'patient_registration_screen.dart';

class CaretakerAuthScreen extends StatefulWidget {
  const CaretakerAuthScreen({super.key});

  @override
  State<CaretakerAuthScreen> createState() => _CaretakerAuthScreenState();
}

class _CaretakerAuthScreenState extends State<CaretakerAuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AuthScope.of(context).clearDemoUsers();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
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

    return Scaffold(
      backgroundColor: AppTheme.cream,
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
              width: 36,
              height: 36,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.forest.withValues(alpha: 0.12),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.forest.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Premium Portal Header Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      AppTheme.paleSage.withValues(alpha: 0.35),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radius24),
                  border: Border.all(
                    color: AppTheme.forest.withValues(alpha: 0.12),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.forest.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.paleSage.withValues(alpha: 0.85),
                            AppTheme.sage.withValues(alpha: 0.65),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radius16),
                        border: Border.all(
                          color: AppTheme.forest.withValues(alpha: 0.15),
                          width: 1.2,
                        ),
                      ),
                      child: const Icon(
                        Icons.verified_user_rounded,
                        color: AppTheme.forest,
                        size: 26,
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
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.deepForest,
                              letterSpacing: -0.1,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _auth.portalSubtitle,
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
              ),

              const SizedBox(height: 22),

              Text(
                _auth.howToContinue,
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.deepForest,
                ),
              ),
              const SizedBox(height: 12),

              // Segmented Tab Switcher (Log In / Sign Up)
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.paleSage.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(AppTheme.radius18),
                  border: Border.all(
                    color: AppTheme.forest.withValues(alpha: 0.12),
                    width: 1.2,
                  ),
                ),
                padding: const EdgeInsets.all(4),
                child: AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, _) {
                    final isLogin = _tabController.index == 0;
                    return Row(
                      children: [
                        Expanded(
                          child: AnimatedScaleButton(
                            onTap: () {
                              if (!isLogin) _tabController.animateTo(0);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                gradient: isLogin
                                    ? AppTheme.emeraldGradient
                                    : null,
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radius14),
                                boxShadow: isLogin ? AppTheme.buttonGlow : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.login_rounded,
                                    size: 18,
                                    color: isLogin
                                        ? Colors.white
                                        : AppTheme.deepForest,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _auth.logIn,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isLogin
                                          ? Colors.white
                                          : AppTheme.deepForest,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: AnimatedScaleButton(
                            onTap: () {
                              if (isLogin) _tabController.animateTo(1);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                gradient: !isLogin
                                    ? AppTheme.emeraldGradient
                                    : null,
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radius14),
                                boxShadow:
                                    !isLogin ? AppTheme.buttonGlow : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person_add_alt_1_rounded,
                                    size: 18,
                                    color: !isLogin
                                        ? Colors.white
                                        : AppTheme.deepForest,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _auth.signUp,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: !isLogin
                                          ? Colors.white
                                          : AppTheme.deepForest,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Caretaker Form Card
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radius24),
                  boxShadow: AppTheme.cardLift,
                  border: Border.all(
                    color: AppTheme.forest.withValues(alpha: 0.09),
                    width: 1.2,
                  ),
                ),
                child: AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, _) {
                    return _tabController.index == 0
                        ? _buildLoginForm()
                        : _buildSignUpForm();
                  },
                ),
              ),

              const SizedBox(height: 32),

              // Elegant Divider
              Row(
                children: [
                  const Expanded(
                      child: Divider(color: AppTheme.divider, thickness: 1.2)),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.paleSage.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      border: Border.all(
                        color: AppTheme.forest.withValues(alpha: 0.12),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.elderly_rounded,
                            size: 18, color: AppTheme.forest),
                        const SizedBox(width: 6),
                        Text(
                          _auth.seniorCompanionLabel,
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.forest,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Expanded(
                      child: Divider(color: AppTheme.divider, thickness: 1.2)),
                ],
              ),

              const SizedBox(height: 20),

              // Elderly Pass Key Access Section
              _buildElderlyPassKeySection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.badge_outlined, size: 16, color: AppTheme.forest),
            const SizedBox(width: 6),
            Text(
              _auth.emailOrPhone,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.deepForest,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _loginEmailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          style: AppTheme.inputText(),
          decoration: InputDecoration(
            hintText: _auth.emailHint,
            hintStyle: AppTheme.inputHint(),
            prefixIcon:
                const Icon(Icons.email_outlined, color: AppTheme.forest),
            filled: true,
            fillColor: AppTheme.cream,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius16),
              borderSide:
                  BorderSide(color: AppTheme.divider.withValues(alpha: 0.8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius16),
              borderSide:
                  BorderSide(color: AppTheme.divider.withValues(alpha: 0.8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius16),
              borderSide:
                  const BorderSide(color: AppTheme.forest, width: 1.8),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Icon(Icons.lock_outline_rounded,
                size: 16, color: AppTheme.forest),
            const SizedBox(width: 6),
            Text(
              _auth.passwordLabel,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.deepForest,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _loginPasswordController,
          obscureText: _obscureLoginPassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _handleLogin(),
          style: AppTheme.inputText(),
          decoration: InputDecoration(
            hintText: _auth.passwordHint,
            hintStyle: AppTheme.inputHint(),
            prefixIcon:
                const Icon(Icons.lock_outline_rounded, color: AppTheme.forest),
            suffixIcon: IconButton(
              tooltip:
                  _obscureLoginPassword ? _auth.showPassword : _auth.hidePassword,
              onPressed: () {
                setState(
                    () => _obscureLoginPassword = !_obscureLoginPassword);
              },
              icon: Icon(
                _obscureLoginPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppTheme.forest,
              ),
            ),
            filled: true,
            fillColor: AppTheme.cream,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius16),
              borderSide:
                  BorderSide(color: AppTheme.divider.withValues(alpha: 0.8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius16),
              borderSide:
                  BorderSide(color: AppTheme.divider.withValues(alpha: 0.8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius16),
              borderSide:
                  const BorderSide(color: AppTheme.forest, width: 1.8),
            ),
          ),
        ),
        const SizedBox(height: 24),
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
        const SizedBox(height: 12),
        Center(
          child: OutlinedButton.icon(
            onPressed: () {
              _loginEmailController.text = 'rajesh.care@health.org';
              _loginPasswordController.text = 'care123';
              _handleLogin();
            },
            icon: const Icon(Icons.flash_on_rounded, size: 16, color: AppTheme.forest),
            label: Text(
              'Quick Demo Login (Dr. Rajesh)',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.forest,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppTheme.forest.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radius12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () {
              _tabController.animateTo(1);
            },
            child: Text(
              _auth.newCaretakerLink,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.forest,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.person_outline_rounded,
                size: 16, color: AppTheme.forest),
            const SizedBox(width: 6),
            Text(
              _auth.yourFullName,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.deepForest,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _signupNameController,
          textInputAction: TextInputAction.next,
          style: AppTheme.inputText(),
          decoration: InputDecoration(
            hintText: 'e.g. Meena Raman',
            hintStyle: AppTheme.inputHint(),
            prefixIcon:
                const Icon(Icons.person_outline, color: AppTheme.forest),
            filled: true,
            fillColor: AppTheme.cream,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius16),
              borderSide:
                  BorderSide(color: AppTheme.divider.withValues(alpha: 0.8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius16),
              borderSide:
                  BorderSide(color: AppTheme.divider.withValues(alpha: 0.8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius16),
              borderSide:
                  const BorderSide(color: AppTheme.forest, width: 1.8),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.favorite_outline_rounded,
                size: 16, color: AppTheme.forest),
            const SizedBox(width: 6),
            Text(
              _auth.relationshipToPatient,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.deepForest,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.cream,
            borderRadius: BorderRadius.circular(AppTheme.radius16),
            border: Border.all(
                color: AppTheme.divider.withValues(alpha: 0.8)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedRelationship,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.forest),
              items: _relationships.map((rel) {
                return DropdownMenuItem(
                  value: rel,
                  child: Text(
                    rel,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
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
        Row(
          children: [
            const Icon(Icons.phone_outlined, size: 16, color: AppTheme.forest),
            const SizedBox(width: 6),
            Text(
              _auth.phoneAndEmail,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.deepForest,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _signupPhoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          style: AppTheme.inputText(),
          decoration: InputDecoration(
            hintText: _auth.phoneHint,
            hintStyle: AppTheme.inputHint(),
            prefixIcon:
                const Icon(Icons.phone_outlined, color: AppTheme.forest),
            filled: true,
            fillColor: AppTheme.cream,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius16),
              borderSide:
                  BorderSide(color: AppTheme.divider.withValues(alpha: 0.8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius16),
              borderSide:
                  BorderSide(color: AppTheme.divider.withValues(alpha: 0.8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius16),
              borderSide:
                  const BorderSide(color: AppTheme.forest, width: 1.8),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _signupEmailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          style: AppTheme.inputText(),
          decoration: InputDecoration(
            hintText: _auth.emailHintSignup,
            hintStyle: AppTheme.inputHint(),
            prefixIcon:
                const Icon(Icons.email_outlined, color: AppTheme.forest),
            filled: true,
            fillColor: AppTheme.cream,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius16),
              borderSide:
                  BorderSide(color: AppTheme.divider.withValues(alpha: 0.8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius16),
              borderSide:
                  BorderSide(color: AppTheme.divider.withValues(alpha: 0.8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius16),
              borderSide:
                  const BorderSide(color: AppTheme.forest, width: 1.8),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.lock_outline_rounded,
                size: 16, color: AppTheme.forest),
            const SizedBox(width: 6),
            Text(
              _auth.passwordLabel,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.deepForest,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _signupPasswordController,
          obscureText: _obscureSignupPassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _handleSignUp(),
          style: AppTheme.inputText(),
          decoration: InputDecoration(
            hintText: 'Create 4-digit PIN or password',
            hintStyle: AppTheme.inputHint(),
            prefixIcon:
                const Icon(Icons.lock_outline_rounded, color: AppTheme.forest),
            suffixIcon: IconButton(
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
                color: AppTheme.forest,
              ),
            ),
            filled: true,
            fillColor: AppTheme.cream,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius16),
              borderSide:
                  BorderSide(color: AppTheme.divider.withValues(alpha: 0.8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius16),
              borderSide:
                  BorderSide(color: AppTheme.divider.withValues(alpha: 0.8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius16),
              borderSide:
                  const BorderSide(color: AppTheme.forest, width: 1.8),
            ),
          ),
        ),
        const SizedBox(height: 24),
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
        const SizedBox(height: 14),
        Center(
          child: TextButton(
            onPressed: () {
              _tabController.animateTo(0);
            },
            child: Text(
              'Already registered? Log in here',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.forest,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildElderlyPassKeySection() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.paleSage.withValues(alpha: 0.45),
            AppTheme.sage.withValues(alpha: 0.25),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radius28),
        boxShadow: AppTheme.softShadow,
        border: Border.all(
          color: AppTheme.forest.withValues(alpha: 0.18),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.forest.withValues(alpha: 0.15),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.forest.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.key_rounded,
                  color: AppTheme.forest,
                  size: 26,
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
                        fontSize: 18,
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
              letterSpacing: 2.5,
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
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radius18),
                borderSide: BorderSide(
                  color: AppTheme.forest.withValues(alpha: 0.25),
                  width: 1.3,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radius18),
                borderSide: BorderSide(
                  color: AppTheme.forest.withValues(alpha: 0.25),
                  width: 1.3,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radius18),
                borderSide: const BorderSide(
                  color: AppTheme.forest,
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
                gradient: AppTheme.emeraldGradient,
                borderRadius: BorderRadius.circular(AppTheme.radius18),
                boxShadow: AppTheme.buttonGlow,
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
}
