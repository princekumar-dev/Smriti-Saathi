import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../navigation/app_shell.dart';
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

  // Caretaker Sign In controllers
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  // Caretaker Sign Up controllers
  final _signupNameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPhoneController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  String _selectedRelationship = 'Daughter';

  // Elderly Pass Key controller
  final _elderlyPassKeyController = TextEditingController();
  bool _isSeniorLoading = false;
  bool _isCaretakerLoading = false;
  bool _obscureLoginPassword = true;

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

  void _fillDemoSignup() {
    setState(() {
      _signupNameController.text = 'Dr. Rajesh Kumar';
      _signupEmailController.text = 'rajesh.care@health.org';
      _signupPhoneController.text = '+91 98450 12345';
      _signupPasswordController.text = 'care123';
      _selectedRelationship = 'Doctor / Nurse';
    });
  }

  void _fillDemoCaretakerLogin() {
    setState(() {
      _loginEmailController.text = 'rajesh.care@health.org';
      _loginPasswordController.text = 'care123';
    });
  }

  Future<void> _handleLogin() async {
    final auth = AuthScope.of(context);
    final emailOrPhone = _loginEmailController.text.trim();
    if (emailOrPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter email or phone number'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          content: const Text('Please enter your full name'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          content: const Text('Please enter the pass key or caretaker code'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          content: Text(
            'Pass key "$code" not found in MongoDB. Try DEMO or check with your caretaker.',
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _selectPatient(PatientProfile patient) async {
    final auth = AuthScope.of(context);
    await auth.selectActivePatient(patient);
    await auth.switchToPatientMode();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AppShell()),
        (route) => false,
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
    final auth = AuthScope.of(context);
    final registeredPatients = auth.registeredPatients;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF184E77)),
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
                  color: const Color(0xFF184E77).withValues(alpha: 0.16),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF184E77).withValues(alpha: 0.08),
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
              style: GoogleFonts.comfortaa(
                fontSize: 18.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF184E77),
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
              // Premium Family Portal Header Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFF184E77).withValues(alpha: 0.12),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF184E77).withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE8F4F8), Color(0xFFD5E7DB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF184E77).withValues(alpha: 0.14),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: Color(0xFF184E77),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Portal Login & Access',
                            style: GoogleFonts.comfortaa(
                              fontSize: 17.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF184E77),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Manage care, memories and routines, or enter as a senior companion.',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
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

              const SizedBox(height: 20),

              Text(
                'How would you like to continue?',
                style: GoogleFonts.comfortaa(
                  fontSize: 17.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.deepForest,
                ),
              ),
              const SizedBox(height: 12),

              // Horizontal Non-Squishing Luxury Segment Switcher
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF184E77).withValues(alpha: 0.14),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF184E77).withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              decoration: BoxDecoration(
                                gradient: isLogin
                                    ? const LinearGradient(
                                        colors: [Color(0xFF184E77), Color(0xFF2D6A4F)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: isLogin
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF184E77).withValues(alpha: 0.25),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.login_rounded,
                                    size: 18,
                                    color: isLogin ? Colors.white : AppTheme.deepForest,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Log In',
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: isLogin ? Colors.white : AppTheme.deepForest,
                                      letterSpacing: 0.2,
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
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              decoration: BoxDecoration(
                                gradient: !isLogin
                                    ? const LinearGradient(
                                        colors: [Color(0xFF184E77), Color(0xFF2D6A4F)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: !isLogin
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF184E77).withValues(alpha: 0.25),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person_add_alt_1_rounded,
                                    size: 18,
                                    color: !isLogin ? Colors.white : AppTheme.deepForest,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Sign Up',
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: !isLogin ? Colors.white : AppTheme.deepForest,
                                      letterSpacing: 0.2,
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
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF184E77).withValues(alpha: 0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(
                    color: const Color(0xFF184E77).withValues(alpha: 0.12),
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
                  const Expanded(child: Divider(color: AppTheme.divider, thickness: 1.2)),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F4F8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF184E77).withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.elderly_rounded, size: 18, color: Color(0xFF184E77)),
                        const SizedBox(width: 6),
                        Text(
                          'FOR THE SENIOR COMPANION',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF184E77),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Expanded(child: Divider(color: AppTheme.divider, thickness: 1.2)),
                ],
              ),

              const SizedBox(height: 20),

              // Elderly Login / Pass Key Section
              _buildElderlyPassKeySection(registeredPatients),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Email or Phone Number',
              style: GoogleFonts.outfit(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: AppTheme.deepForest,
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _fillDemoCaretakerLogin,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF184E77).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF184E77).withValues(alpha: 0.16),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flash_on_rounded, size: 13, color: Color(0xFF184E77)),
                    const SizedBox(width: 4),
                    Text(
                      'Demo Login',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF184E77),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _loginEmailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.deepForest,
          ),
          decoration: InputDecoration(
            hintText: 'e.g. meena.care@gmail.com',
            hintStyle: GoogleFonts.outfit(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: AppTheme.muted.withValues(alpha: 0.7),
            ),
            prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF184E77)),
            filled: true,
            fillColor: AppTheme.cream,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.divider.withValues(alpha: 0.8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.divider.withValues(alpha: 0.8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF184E77), width: 1.6),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'PIN or Password',
          style: GoogleFonts.outfit(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: AppTheme.deepForest,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _loginPasswordController,
          obscureText: _obscureLoginPassword,
          textInputAction: TextInputAction.done,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.deepForest,
          ),
          decoration: InputDecoration(
            hintText: 'Enter your password or 4-digit PIN',
            hintStyle: GoogleFonts.outfit(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: AppTheme.muted.withValues(alpha: 0.7),
            ),
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF184E77)),
            suffixIcon: IconButton(
              tooltip: _obscureLoginPassword ? 'Show password' : 'Hide password',
              onPressed: () {
                setState(() => _obscureLoginPassword = !_obscureLoginPassword);
              },
              icon: Icon(
                _obscureLoginPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: const Color(0xFF184E77),
              ),
            ),
            filled: true,
            fillColor: AppTheme.cream,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.divider.withValues(alpha: 0.8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.divider.withValues(alpha: 0.8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF184E77), width: 1.6),
            ),
          ),
        ),
        const SizedBox(height: 22),
        AnimatedScaleButton(
          onTap: _isCaretakerLoading ? null : _handleLogin,
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF184E77), Color(0xFF2D6A4F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF184E77).withValues(alpha: 0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
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
                  const Icon(Icons.login_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Log In as Caretaker',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () {
              _tabController.animateTo(1);
            },
            child: Text(
              'New caretaker? Create account here',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF184E77),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Full Name',
              style: GoogleFonts.outfit(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: AppTheme.deepForest,
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _fillDemoSignup,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF184E77).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF184E77).withValues(alpha: 0.16),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flash_on_rounded, size: 13, color: Color(0xFF184E77)),
                    const SizedBox(width: 4),
                    Text(
                      'Demo Auto-fill',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF184E77),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _signupNameController,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.deepForest,
          ),
          decoration: InputDecoration(
            hintText: 'e.g. Meena Raman',
            hintStyle: GoogleFonts.outfit(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: AppTheme.muted.withValues(alpha: 0.7),
            ),
            prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF184E77)),
            filled: true,
            fillColor: AppTheme.cream,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.divider.withValues(alpha: 0.8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.divider.withValues(alpha: 0.8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF184E77), width: 1.6),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Relationship to Patient',
          style: GoogleFonts.outfit(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: AppTheme.deepForest,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.cream,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.divider.withValues(alpha: 0.8)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedRelationship,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF184E77)),
              items: _relationships.map((rel) {
                return DropdownMenuItem(
                  value: rel,
                  child: Text(
                    rel,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
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
        const SizedBox(height: 14),
        Text(
          'Phone & Email',
          style: GoogleFonts.outfit(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: AppTheme.deepForest,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _signupPhoneController,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.deepForest,
          ),
          decoration: InputDecoration(
            hintText: '+91 98450 12345',
            hintStyle: GoogleFonts.outfit(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: AppTheme.muted.withValues(alpha: 0.7),
            ),
            prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF184E77)),
            filled: true,
            fillColor: AppTheme.cream,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.divider.withValues(alpha: 0.8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.divider.withValues(alpha: 0.8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF184E77), width: 1.6),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _signupEmailController,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.deepForest,
          ),
          decoration: InputDecoration(
            hintText: 'meena@gmail.com',
            hintStyle: GoogleFonts.outfit(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: AppTheme.muted.withValues(alpha: 0.7),
            ),
            prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF184E77)),
            filled: true,
            fillColor: AppTheme.cream,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.divider.withValues(alpha: 0.8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.divider.withValues(alpha: 0.8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF184E77), width: 1.6),
            ),
          ),
        ),
        const SizedBox(height: 22),
        AnimatedScaleButton(
          onTap: _isCaretakerLoading ? null : _handleSignUp,
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF184E77), Color(0xFF2D6A4F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF184E77).withValues(alpha: 0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
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
                  const Icon(Icons.how_to_reg_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Create Caretaker Account',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildElderlyPassKeySection(List<PatientProfile> registeredPatients) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F8F5),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.forest.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF2D6A4F).withValues(alpha: 0.22),
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
                    color: const Color(0xFF2D6A4F).withValues(alpha: 0.2),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2D6A4F).withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.key_rounded,
                  color: Color(0xFF2D6A4F),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter as a Senior',
                      style: GoogleFonts.comfortaa(
                        fontSize: 18.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.deepForest,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Use the pass key your family gave you, or tap below for guest mode.',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
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
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.5,
              color: const Color(0xFF184E77),
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: 'Enter Pass Key (e.g. SAATHI-7821)',
              hintStyle: GoogleFonts.outfit(
                fontSize: 15,
                letterSpacing: 0,
                fontWeight: FontWeight.w500,
                color: AppTheme.muted.withValues(alpha: 0.7),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: const Color(0xFF2D6A4F).withValues(alpha: 0.3),
                  width: 1.3,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: const Color(0xFF2D6A4F).withValues(alpha: 0.3),
                  width: 1.3,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: Color(0xFF184E77),
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
                  colors: [Color(0xFF2D6A4F), Color(0xFF184E77)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2D6A4F).withValues(alpha: 0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
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
                        const Icon(Icons.play_circle_filled_rounded, size: 22, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Start Senior Companion',
                          style: GoogleFonts.outfit(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          if (registeredPatients.isNotEmpty) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(child: Divider(color: AppTheme.divider)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'OR SELECT ACTIVE SENIOR',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.forest,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: AppTheme.divider)),
              ],
            ),
            const SizedBox(height: 12),
            ...registeredPatients.map((patient) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF184E77).withValues(alpha: 0.14),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.deepForest.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    onTap: () => _selectPatient(patient),
                    leading: const CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(0xFFE8F4F8),
                      child: Icon(Icons.person_rounded, color: Color(0xFF184E77), size: 22),
                    ),
                    title: Text(
                      patient.nickname.isNotEmpty
                          ? '${patient.name} (${patient.nickname})'
                          : patient.name,
                      style: GoogleFonts.outfit(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.deepForest,
                      ),
                    ),
                    subtitle: Text(
                      'Pass Key: ${patient.pairingCode}',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF184E77),
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 15,
                      color: Color(0xFF184E77),
                    ),
                  ),
                ),
              );
            }),
          ],

          const SizedBox(height: 14),

          // Instant Guest / Demo Senior Access Button
          Center(
            child: AnimatedScaleButton(
              onTap: () => _loginElderlyWithCode('DEMO'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF2D6A4F).withValues(alpha: 0.25),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2D6A4F).withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flash_on_rounded, size: 17, color: Color(0xFF2D6A4F)),
                    const SizedBox(width: 6),
                    Text(
                      'Instant Guest / Demo Senior Login',
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2D6A4F),
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
