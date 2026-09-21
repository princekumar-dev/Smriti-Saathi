import 'package:flutter/material.dart';

import '../navigation/app_shell.dart';
import '../state/auth_session.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_mark.dart';
import 'caretaker_home_screen.dart';
import 'register_patient_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.role});

  final UserRole role;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late bool _isSignUp;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;
  bool _obscurePassword = true;

  bool get _isCaretaker => widget.role == UserRole.caretaker;

  @override
  void initState() {
    super.initState();
    _isSignUp = _isCaretaker;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(child: BrandMark()),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                _isCaretaker
                    ? (_isSignUp ? 'Caretaker sign up' : 'Caretaker login')
                    : 'User login',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 10),
              Text(
                _isCaretaker
                    ? (_isSignUp
                        ? 'Create your caretaker account. Next, you will register your patient.'
                        : 'Welcome back. After login you can care for the patients you registered.')
                    : 'Use the email and password your caretaker created when they registered you.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.muted,
                    ),
              ),
              const SizedBox(height: 24),
              if (_isCaretaker && _isSignUp) ...[
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Your name',
                    hintText: 'e.g. Meena',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'e.g. meena@email.com',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'At least 4 characters',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: Text(_isSignUp ? 'Create caretaker account' : 'Log in'),
                ),
              ),
              const SizedBox(height: 12),
              if (_isCaretaker)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isSignUp = !_isSignUp;
                        _error = null;
                      });
                    },
                    child: Text(
                      _isSignUp
                          ? 'I already have an account'
                          : 'I need to sign up',
                    ),
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Need an account? Ask your caretaker to register you as their patient.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.muted,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    final session = AuthSessionScope.of(context);
    session.selectRole(widget.role);

    final String? error;
    if (_isSignUp) {
      error = session.signUp(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
    } else {
      error = session.logIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
    }

    if (error != null) {
      setState(() => _error = error);
      return;
    }

    if (!session.isCaretaker) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AppShell()),
        (route) => false,
      );
      return;
    }

    final next = session.patients.isEmpty
        ? const RegisterPatientScreen(requiredFirstPatient: true)
        : const CaretakerHomeScreen();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => next),
      (route) => false,
    );
  }
}
