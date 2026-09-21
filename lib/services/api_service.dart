import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service connecting Smrithi Saathi to the MongoDB Atlas Backend API
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Dynamic backend endpoint URL supporting localhost and devtunnels
  static String? _customBaseUrl;
  static set baseUrl(String val) => _customBaseUrl = val;

  static String get baseUrl {
    if (_customBaseUrl != null) return _customBaseUrl!;
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host.contains('devtunnels.ms')) {
        final parts = host.split('.');
        final subparts = parts.first.split('-');
        if (subparts.length >= 2) {
          final tunnelId = subparts.sublist(0, subparts.length - 1).join('-');
          final domain = parts.sublist(1).join('.');
          return 'https://$tunnelId-5000.$domain/api';
        }
      }
    }
    return 'http://localhost:5000/api';
  }

  bool _isOnline = false;
  bool get isOnline => _isOnline;

  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _isOnline = data['connected'] == true;
        return _isOnline;
      }
      _isOnline = false;
      return false;
    } catch (_) {
      _isOnline = false;
      return false;
    }
  }

  // ----------------------------------------------------
  // CARETAKER AUTHENTICATION & PROFILES (MongoDB Atlas)
  // ----------------------------------------------------
  Future<Map<String, dynamic>?> signUpCaretaker(Map<String, dynamic> data) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/caretakers/signup'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 6));
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 || response.statusCode == 201) {
        _isOnline = true;
      }
      return decoded;
    } catch (e) {
      debugPrint('ApiService.signUpCaretaker error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> loginCaretaker({
    required String emailOrPhone,
    String? password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/caretakers/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'emailOrPhone': emailOrPhone,
              'password': password ?? '',
            }),
          )
          .timeout(const Duration(seconds: 6));
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        _isOnline = true;
      }
      return decoded;
    } catch (e) {
      debugPrint('ApiService.loginCaretaker error: $e');
    }
    return null;
  }

  // ----------------------------------------------------
  // PATIENTS / SENIORS (MongoDB Atlas)
  // ----------------------------------------------------
  Future<Map<String, dynamic>?> registerPatient(Map<String, dynamic> data) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/patients'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 6));
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 || response.statusCode == 201) {
        _isOnline = true;
      }
      return decoded;
    } catch (e) {
      debugPrint('ApiService.registerPatient error: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> fetchPatients({String? caretakerId}) async {
    try {
      final uri = caretakerId != null
          ? Uri.parse('$baseUrl/patients?caretakerId=$caretakerId')
          : Uri.parse('$baseUrl/patients');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        _isOnline = true;
        return list.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('ApiService.fetchPatients error: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> validatePatientPassKey(String passKey) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/patients/validate-passkey'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'passKey': passKey}),
          )
          .timeout(const Duration(seconds: 6));
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        _isOnline = true;
        return decoded;
      } else {
        return decoded;
      }
    } catch (e) {
      debugPrint('ApiService.validatePatientPassKey error: $e');
    }
    return null;
  }

  // ----------------------------------------------------
  // MEMORIES (MongoDB Atlas)
  // ----------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchMemories({String? patientId}) async {
    try {
      final uri = patientId != null
          ? Uri.parse('$baseUrl/memories?patientId=$patientId')
          : Uri.parse('$baseUrl/memories');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        _isOnline = true;
        return list.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('ApiService.fetchMemories error: $e');
    }
    return [];
  }

  Future<bool> saveMemory(Map<String, dynamic> memoryData) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/memories'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(memoryData),
          )
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('ApiService.saveMemory error: $e');
      return false;
    }
  }

  Future<bool> deleteMemory(String id) async {
    try {
      final response = await http
          .delete(Uri.parse('$baseUrl/memories/$id'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService.deleteMemory error: $e');
      return false;
    }
  }

  // ----------------------------------------------------
  // FAMILY MEMBERS (MongoDB Atlas)
  // ----------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchFamilyMembers({String? patientId}) async {
    try {
      final uri = patientId != null
          ? Uri.parse('$baseUrl/family?patientId=$patientId')
          : Uri.parse('$baseUrl/family');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        _isOnline = true;
        return list.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('ApiService.fetchFamilyMembers error: $e');
    }
    return [];
  }

  Future<bool> saveFamilyMember(Map<String, dynamic> data) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/family'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('ApiService.saveFamilyMember error: $e');
      return false;
    }
  }

  Future<bool> deleteFamilyMember(String id) async {
    try {
      final response = await http
          .delete(Uri.parse('$baseUrl/family/$id'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService.deleteFamilyMember error: $e');
      return false;
    }
  }

  // ----------------------------------------------------
  // ROUTINE REMINDERS (MongoDB Atlas)
  // ----------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchReminders({String? patientId}) async {
    try {
      final uri = patientId != null
          ? Uri.parse('$baseUrl/reminders?patientId=$patientId')
          : Uri.parse('$baseUrl/reminders');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        _isOnline = true;
        return list.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('ApiService.fetchReminders error: $e');
    }
    return [];
  }

  Future<bool> saveReminder(Map<String, dynamic> data) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/reminders'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('ApiService.saveReminder error: $e');
      return false;
    }
  }

  Future<bool> updateReminder(String id, Map<String, dynamic> data) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/reminders/$id'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService.updateReminder error: $e');
      return false;
    }
  }

  Future<bool> deleteReminder(String id) async {
    try {
      final response = await http
          .delete(Uri.parse('$baseUrl/reminders/$id'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService.deleteReminder error: $e');
      return false;
    }
  }
}
