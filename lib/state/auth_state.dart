import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

enum UserRole {
  unauthenticated,
  caretaker,
  patient,
}

class CaretakerProfile {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String relationship;
  final String password;

  const CaretakerProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.relationship,
    this.password = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'relationship': relationship,
        'password': password,
      };

  factory CaretakerProfile.fromJson(Map<String, dynamic> json) =>
      CaretakerProfile(
        id: json['id'] as String? ?? 'ct_${DateTime.now().millisecondsSinceEpoch}',
        name: json['name'] as String? ?? 'Caretaker',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        relationship: json['relationship'] as String? ?? 'Family Member',
        password: json['password'] as String? ?? '',
      );
}

class PatientProfile {
  final String id;
  final String caretakerId;
  final String name;
  final String nickname;
  final int age;
  final String gender;
  final String condition;
  final String language;
  final String emergencyContact;
  final String emergencyPhone;
  final String pairingCode;
  final String notes;

  const PatientProfile({
    required this.id,
    this.caretakerId = '',
    required this.name,
    this.nickname = '',
    required this.age,
    required this.gender,
    required this.condition,
    required this.language,
    required this.emergencyContact,
    required this.emergencyPhone,
    required this.pairingCode,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'caretakerId': caretakerId,
        'name': name,
        'nickname': nickname,
        'age': age,
        'gender': gender,
        'condition': condition,
        'language': language,
        'emergencyContact': emergencyContact,
        'emergencyPhone': emergencyPhone,
        'pairingCode': pairingCode,
        'notes': notes,
      };

  factory PatientProfile.fromJson(Map<String, dynamic> json) => PatientProfile(
        id: json['id'] as String? ?? 'pt_${DateTime.now().millisecondsSinceEpoch}',
        caretakerId: json['caretakerId'] as String? ?? '',
        name: json['name'] as String? ?? 'Elderly Companion',
        nickname: json['nickname'] as String? ?? '',
        age: (json['age'] is num)
            ? (json['age'] as num).toInt()
            : (int.tryParse('${json['age']}') ?? 72),
        gender: json['gender'] as String? ?? '',
        condition: json['condition'] as String? ?? 'General Wellness',
        language: json['language'] as String? ?? '',
        emergencyContact: json['emergencyContact'] as String? ?? '',
        emergencyPhone: json['emergencyPhone'] as String? ?? '',
        pairingCode: (json['pairingCode'] as String? ?? 'SAATHI-7821').trim().toUpperCase(),
        notes: json['notes'] as String? ?? '',
      );
}

class AuthState extends ChangeNotifier {
  AuthState() {
    _loadFromPrefs();
  }

  UserRole _currentRole = UserRole.unauthenticated;
  CaretakerProfile? _activeCaretaker;
  PatientProfile? _activePatient;
  List<PatientProfile> _registeredPatients = [];
  bool _isInitialized = false;
  bool _onboardingCompleted = false;

  UserRole get currentRole => _currentRole;
  CaretakerProfile? get activeCaretaker => _activeCaretaker;
  PatientProfile? get activePatient => _activePatient;
  List<PatientProfile> get registeredPatients => List.unmodifiable(_registeredPatients);
  bool get isInitialized => _isInitialized;
  bool get onboardingCompleted => _onboardingCompleted;

  bool get isAuthenticated => _currentRole != UserRole.unauthenticated;
  bool get isCaretaker => _currentRole == UserRole.caretaker;
  bool get isPatient => _currentRole == UserRole.patient;

  static const String _kRoleKey = 'smirithi_auth_role';
  static const String _kCaretakerKey = 'smirithi_caretaker_profile';
  static const String _kPatientKey = 'smirithi_patient_profile';
  static const String _kPatientsListKey = 'smirithi_registered_patients';
  static const String _kOnboardingKey = 'smirithi_onboarding_completed';

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final roleStr = prefs.getString(_kRoleKey);
      final caretakerJson = prefs.getString(_kCaretakerKey);
      final patientJson = prefs.getString(_kPatientKey);
      final patientsListJson = prefs.getString(_kPatientsListKey);
      _onboardingCompleted = prefs.getBool(_kOnboardingKey) ?? false;

      if (caretakerJson != null) {
        _activeCaretaker = CaretakerProfile.fromJson(jsonDecode(caretakerJson));
      }
      if (patientJson != null) {
        _activePatient = PatientProfile.fromJson(jsonDecode(patientJson));
      }
      if (patientsListJson != null) {
        final List<dynamic> list = jsonDecode(patientsListJson);
        _registeredPatients = list
            .map((e) => PatientProfile.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      if (roleStr == 'caretaker') {
        _currentRole = UserRole.caretaker;
      } else if (roleStr == 'patient') {
        _currentRole = UserRole.patient;
      } else {
        _currentRole = UserRole.unauthenticated;
      }

      // Sync registered patients from MongoDB Atlas in background if caretaker is known
      refreshPatientsFromBackend();
    } catch (_) {
      _currentRole = UserRole.unauthenticated;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentRole == UserRole.caretaker) {
        await prefs.setString(_kRoleKey, 'caretaker');
      } else if (_currentRole == UserRole.patient) {
        await prefs.setString(_kRoleKey, 'patient');
      } else {
        await prefs.remove(_kRoleKey);
      }

      if (_activeCaretaker != null) {
        await prefs.setString(
            _kCaretakerKey, jsonEncode(_activeCaretaker!.toJson()));
      }
      if (_activePatient != null) {
        await prefs.setString(
            _kPatientKey, jsonEncode(_activePatient!.toJson()));
      }
      await prefs.setString(
        _kPatientsListKey,
        jsonEncode(_registeredPatients.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  /// Sync patients list from MongoDB Atlas
  Future<void> refreshPatientsFromBackend() async {
    try {
      final list = await ApiService().fetchPatients(
        caretakerId: _activeCaretaker?.id,
      );
      if (list.isNotEmpty) {
        final parsed = list.map((e) => PatientProfile.fromJson(e)).toList();
        _registeredPatients = parsed;
        if (_activePatient == null && _registeredPatients.isNotEmpty) {
          _activePatient = _registeredPatients.first;
        }
        await _saveToPrefs();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('AuthState.refreshPatientsFromBackend error: $e');
    }
  }

  Future<String?> signUpCaretaker({
    required String name,
    required String email,
    required String phone,
    required String relationship,
    String password = '',
  }) async {
    final generatedId = 'ct_${DateTime.now().millisecondsSinceEpoch}';
    final profile = CaretakerProfile(
      id: generatedId,
      name: name,
      email: email,
      phone: phone,
      relationship: relationship,
      password: password,
    );

    // Save to MongoDB Atlas
    try {
      final res = await ApiService().signUpCaretaker(profile.toJson());
      if (res != null && res['success'] == true && res['caretaker'] != null) {
        _activeCaretaker = CaretakerProfile.fromJson(res['caretaker'] as Map<String, dynamic>);
      } else if (res != null && res['error'] != null) {
        return res['error'] as String;
      } else {
        _activeCaretaker = profile;
      }
    } catch (e) {
      debugPrint('MongoDB signUp error: $e');
      _activeCaretaker = profile;
    }

    _currentRole = UserRole.caretaker;
    await _saveToPrefs();
    notifyListeners();
    return null;
  }

  Future<String?> loginCaretaker({
    required String emailOrPhone,
    String? passwordOrPin,
  }) async {
    final input = emailOrPhone.trim();
    if (input.isEmpty) return 'Please enter email or phone number';

    // 1. Authenticate with MongoDB Atlas
    try {
      final res = await ApiService().loginCaretaker(
        emailOrPhone: input,
        password: passwordOrPin,
      );

      if (res != null) {
        if (res['success'] == true && res['caretaker'] != null) {
          _activeCaretaker = CaretakerProfile.fromJson(res['caretaker'] as Map<String, dynamic>);
          if (res['patients'] is List) {
            final List list = res['patients'];
            final parsed = list
                .map((e) => PatientProfile.fromJson(e as Map<String, dynamic>))
                .toList();
            if (parsed.isNotEmpty) {
              _registeredPatients = parsed;
              _activePatient = _registeredPatients.first;
            }
          }
          _currentRole = UserRole.caretaker;
          await _saveToPrefs();
          notifyListeners();
          return null;
        } else if (res['error'] != null) {
          // Check local offline match before returning server error
          if (_activeCaretaker != null &&
              (_activeCaretaker!.email.toLowerCase() == input.toLowerCase() ||
               _activeCaretaker!.phone.replaceAll(' ', '') == input.replaceAll(' ', ''))) {
            if (_activeCaretaker!.password.isNotEmpty &&
                passwordOrPin != _activeCaretaker!.password) {
              return 'Incorrect password or PIN. Please try again.';
            }
            _currentRole = UserRole.caretaker;
            await _saveToPrefs();
            notifyListeners();
            return null;
          }
          return res['error'] as String;
        }
      }
    } catch (e) {
      debugPrint('MongoDB login error: $e');
    }

    // 2. Offline fallback to local SharedPreferences
    final caretaker = _activeCaretaker;
    if (caretaker == null) {
      return 'No caretaker account found with that email or phone. Please sign up first.';
    }

    final matchesContact = caretaker.email.toLowerCase() == input.toLowerCase() ||
        caretaker.phone.replaceAll(' ', '') == input.replaceAll(' ', '');
    if (!matchesContact) {
      return 'Account not found. Please check your email or phone, or sign up.';
    }

    if (caretaker.password.isNotEmpty &&
        (passwordOrPin == null || passwordOrPin != caretaker.password)) {
      return 'Incorrect password or PIN. Please try again.';
    }

    _currentRole = UserRole.caretaker;
    await _saveToPrefs();
    notifyListeners();
    return null;
  }

  Future<PatientProfile> registerPatient({
    required String name,
    required String nickname,
    required int age,
    required String gender,
    required String condition,
    required String language,
    required String emergencyContact,
    required String emergencyPhone,
    String notes = '',
  }) async {
    final code = 'SAATHI-${(1000 + (DateTime.now().millisecondsSinceEpoch % 9000))}';
    PatientProfile newPatient = PatientProfile(
      id: 'pt_${DateTime.now().millisecondsSinceEpoch}',
      caretakerId: _activeCaretaker?.id ?? '',
      name: name,
      nickname: nickname,
      age: age,
      gender: gender,
      condition: condition,
      language: language,
      emergencyContact: emergencyContact,
      emergencyPhone: emergencyPhone,
      pairingCode: code,
      notes: notes,
    );

    // Save to MongoDB Atlas
    try {
      final res = await ApiService().registerPatient(newPatient.toJson());
      if (res != null && res['success'] == true && res['patient'] != null) {
        newPatient = PatientProfile.fromJson(res['patient'] as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Error registering patient in MongoDB Atlas: $e');
    }

    _registeredPatients.removeWhere((p) => p.id == newPatient.id || p.pairingCode == newPatient.pairingCode);
    _registeredPatients.insert(0, newPatient);
    _activePatient = newPatient;
    await _saveToPrefs();
    notifyListeners();
    return newPatient;
  }

  Future<bool> loginAsPatientWithCode(String code) async {
    final cleanCode = code.trim().toUpperCase();

    // 1. Validate against MongoDB Atlas
    try {
      final res = await ApiService().validatePatientPassKey(cleanCode);
      if (res != null && res['success'] == true && res['patient'] != null) {
        final profile = PatientProfile.fromJson(res['patient'] as Map<String, dynamic>);
        _activePatient = profile;
        if (!_registeredPatients.any((p) => p.id == profile.id)) {
          _registeredPatients.insert(0, profile);
        }
        _currentRole = UserRole.patient;
        await _saveToPrefs();
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Passkey validation error from MongoDB Atlas: $e');
    }

    // 2. Offline / Local fallback check
    PatientProfile? found;
    for (final patient in _registeredPatients) {
      if (patient.pairingCode.toUpperCase() == cleanCode) {
        found = patient;
        break;
      }
    }
    if (found != null) {
      _activePatient = found;
      _currentRole = UserRole.patient;
      await _saveToPrefs();
      notifyListeners();
      return true;
    }

    // 3. Built-in DEMO / GUEST fallback if offline
    if (cleanCode == 'DEMO' || cleanCode == 'GUEST') {
      const demoPatient = PatientProfile(
        id: 'pt_demo_senior',
        name: 'Shanti Devi',
        nickname: 'Dadi',
        age: 76,
        gender: 'Female',
        condition: 'Mild Cognitive Impairment (Early Stage)',
        language: 'Hindi & English',
        emergencyContact: 'Rajesh Kumar (Son)',
        emergencyPhone: '+91 98450 12345',
        pairingCode: 'SAATHI-DEMO',
        notes: 'Enjoys classical music, morning garden strolls, and looking at family albums.',
      );
      _activePatient = demoPatient;
      if (!_registeredPatients.any((p) => p.id == demoPatient.id)) {
        _registeredPatients.insert(0, demoPatient);
      }
      _currentRole = UserRole.patient;
      await _saveToPrefs();
      notifyListeners();
      return true;
    }

    return false;
  }

  Future<void> selectActivePatient(PatientProfile patient) async {
    _activePatient = patient;
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> switchToPatientMode() async {
    _currentRole = UserRole.patient;
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> switchToCaretakerMode() async {
    _currentRole = UserRole.caretaker;
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> logout() async {
    _currentRole = UserRole.unauthenticated;
    _onboardingCompleted = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kRoleKey);
    await prefs.remove(_kOnboardingKey);
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _onboardingCompleted = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingKey, true);
    notifyListeners();
  }
}

class AuthScope extends InheritedNotifier<AuthState> {
  const AuthScope({
    super.key,
    required AuthState auth,
    required super.child,
  }) : super(notifier: auth);

  static AuthState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope not found in context');
    return scope!.notifier!;
  }
}
