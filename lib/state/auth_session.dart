import 'package:flutter/material.dart';

enum UserRole { user, caretaker }

extension UserRoleLabel on UserRole {
  String get label => this == UserRole.caretaker ? 'Caretaker' : 'User';
}

class PatientRecord {
  PatientRecord({
    required this.name,
    required this.age,
    required this.relationship,
    required this.loginEmail,
    required this.loginPassword,
    this.notes = '',
  });

  final String name;
  final String age;
  final String relationship;
  final String loginEmail;
  final String loginPassword;
  final String notes;
}

class StoredAccount {
  StoredAccount({
    required this.role,
    required this.name,
    required this.email,
    required this.password,
    List<PatientRecord>? patients,
    this.caretakerEmail,
  }) : patients = patients ?? [];

  UserRole role;
  String name;
  String email;
  String password;
  String? caretakerEmail;
  final List<PatientRecord> patients;
}

class AuthSession extends ChangeNotifier {
  UserRole? selectedRole;
  StoredAccount? currentAccount;
  PatientRecord? activePatient;

  final List<StoredAccount> _accounts = [];

  bool get isLoggedIn => currentAccount != null;
  bool get isCaretaker => currentAccount?.role == UserRole.caretaker;
  bool get isUser => currentAccount?.role == UserRole.user;
  String get displayName => currentAccount?.name ?? 'Friend';
  List<PatientRecord> get patients =>
      List.unmodifiable(currentAccount?.patients ?? const []);

  void selectRole(UserRole role) {
    selectedRole = role;
    notifyListeners();
  }

  String? signUp({
    required String name,
    required String email,
    required String password,
  }) {
    if (selectedRole != UserRole.caretaker) {
      return 'Only a caretaker can create an account. Users are registered by their caretaker.';
    }
    if (name.trim().isEmpty) return 'Please enter your name';
    if (!_looksLikeEmail(email)) return 'Please enter a valid email';
    if (password.trim().length < 4) {
      return 'Password should be at least 4 characters';
    }
    if (_findByEmail(email) != null) {
      return 'This email is already registered. Please log in.';
    }

    final account = StoredAccount(
      role: UserRole.caretaker,
      name: name.trim(),
      email: email.trim(),
      password: password,
    );
    _accounts.add(account);
    currentAccount = account;
    selectedRole = UserRole.caretaker;
    notifyListeners();
    return null;
  }

  String? logIn({
    required String email,
    required String password,
  }) {
    final account = _findByEmail(email);
    if (account == null || account.password != password) {
      return 'No matching account. Check the details, or ask a caretaker to register you.';
    }
    if (selectedRole != null && account.role != selectedRole) {
      return 'This account is for a ${account.role.label}. Go back and choose ${account.role.label}.';
    }

    currentAccount = account;
    selectedRole = account.role;
    if (account.role == UserRole.user) {
      activePatient = _patientForUser(account);
    }
    notifyListeners();
    return null;
  }

  String? registerPatient({
    required String name,
    required String age,
    required String relationship,
    required String loginEmail,
    required String loginPassword,
    String notes = '',
  }) {
    if (!isCaretaker || currentAccount == null) {
      return 'Only a caretaker can register a patient.';
    }
    if (name.trim().isEmpty) return 'Please enter the patient’s name';
    if (age.trim().isEmpty) return 'Please enter the patient’s age';
    if (relationship.trim().isEmpty) {
      return 'Please say how you are related to the patient';
    }
    if (!_looksLikeEmail(loginEmail)) {
      return 'Please enter a login email for the patient';
    }
    if (loginPassword.trim().length < 4) {
      return 'Patient password should be at least 4 characters';
    }
    if (_findByEmail(loginEmail) != null) {
      return 'That login email is already used. Choose another.';
    }

    final patient = PatientRecord(
      name: name.trim(),
      age: age.trim(),
      relationship: relationship.trim(),
      loginEmail: loginEmail.trim(),
      loginPassword: loginPassword,
      notes: notes.trim(),
    );
    currentAccount!.patients.add(patient);
    _accounts.add(
      StoredAccount(
        role: UserRole.user,
        name: patient.name,
        email: patient.loginEmail,
        password: patient.loginPassword,
        caretakerEmail: currentAccount!.email,
      ),
    );
    notifyListeners();
    return null;
  }

  void openPatientCompanion(PatientRecord patient) {
    activePatient = patient;
    notifyListeners();
  }

  void logOut() {
    currentAccount = null;
    selectedRole = null;
    activePatient = null;
    notifyListeners();
  }

  StoredAccount? _findByEmail(String email) {
    final needle = email.trim().toLowerCase();
    for (final account in _accounts) {
      if (account.email.toLowerCase() == needle) return account;
    }
    return null;
  }

  PatientRecord? _patientForUser(StoredAccount user) {
    if (user.caretakerEmail == null) return null;
    final caretaker = _findByEmail(user.caretakerEmail!);
    if (caretaker == null) return null;
    for (final patient in caretaker.patients) {
      if (patient.loginEmail.toLowerCase() == user.email.toLowerCase()) {
        return patient;
      }
    }
    return null;
  }

  bool _looksLikeEmail(String value) {
    final email = value.trim();
    return email.contains('@') && email.contains('.');
  }
}

class AuthSessionScope extends InheritedNotifier<AuthSession> {
  const AuthSessionScope({
    super.key,
    required AuthSession session,
    required super.child,
  }) : super(notifier: session);

  static AuthSession of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AuthSessionScope>();
    assert(scope != null, 'AuthSessionScope not found');
    return scope!.notifier!;
  }
}
