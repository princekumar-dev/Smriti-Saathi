import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service connecting Smrithi Saathi to the MongoDB Atlas Backend API
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Dynamic backend endpoint URL supporting localhost, 10.0.2.2, LAN IP, and devtunnels
  static String? _customBaseUrl;
  static String? _resolvedBaseUrl;

  static set baseUrl(String val) {
    _customBaseUrl = val;
    _resolvedBaseUrl = val;
  }

  static List<String> get candidateUrls {
    if (_customBaseUrl != null && _customBaseUrl!.trim().isNotEmpty) {
      return [_customBaseUrl!.trim()];
    }

    final List<String> candidates = [];
    if (_resolvedBaseUrl != null && _resolvedBaseUrl!.isNotEmpty) {
      candidates.add(_resolvedBaseUrl!);
    }

    if (kIsWeb) {
      final host = Uri.base.host;
      if (host.contains('devtunnels.ms')) {
        final parts = host.split('.');
        final subparts = parts.first.split('-');
        if (subparts.length >= 2) {
          final tunnelId = subparts.sublist(0, subparts.length - 1).join('-');
          final domain = parts.sublist(1).join('.');
          final tunnelUrl = 'https://$tunnelId-5000.$domain/api';
          if (!candidates.contains(tunnelUrl)) candidates.add(tunnelUrl);
        }
      }
      if (!candidates.contains('http://localhost:5000/api')) candidates.add('http://localhost:5000/api');
      if (!candidates.contains('http://127.0.0.1:5000/api')) candidates.add('http://127.0.0.1:5000/api');
      return candidates;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      // 10.0.2.2 is the official host machine loopback on standard Android emulator
      if (!candidates.contains('http://10.0.2.2:5000/api')) candidates.add('http://10.0.2.2:5000/api');
      // localhost works if adb reverse tcp:5000 tcp:5000 is active
      if (!candidates.contains('http://localhost:5000/api')) candidates.add('http://localhost:5000/api');
      if (!candidates.contains('http://127.0.0.1:5000/api')) candidates.add('http://127.0.0.1:5000/api');
      // Host machine local LAN IP for physical Android phones on the same Wi-Fi
      if (!candidates.contains('http://192.168.29.35:5000/api')) candidates.add('http://192.168.29.35:5000/api');
      return candidates;
    }

    if (!candidates.contains('http://localhost:5000/api')) candidates.add('http://localhost:5000/api');
    if (!candidates.contains('http://127.0.0.1:5000/api')) candidates.add('http://127.0.0.1:5000/api');
    return candidates;
  }

  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.trim().isNotEmpty) return _customBaseUrl!.trim();
    if (_resolvedBaseUrl != null && _resolvedBaseUrl!.isNotEmpty) return _resolvedBaseUrl!;
    return candidateUrls.first;
  }

  bool _isOnline = false;
  bool get isOnline => _isOnline;

  // ----------------------------------------------------
  // RESILIENT HTTP TRANSPORT WITH CANDIDATE FALLBACK
  // ----------------------------------------------------

  Future<http.Response?> _get(
    String path, {
    Map<String, String>? queryParams,
    Duration timeout = const Duration(seconds: 4),
  }) async {
    final targets = candidateUrls;
    for (int i = 0; i < targets.length; i++) {
      final base = targets[i];
      try {
        final uri = queryParams != null && queryParams.isNotEmpty
            ? Uri.parse('$base$path').replace(queryParameters: queryParams)
            : Uri.parse('$base$path');
        final res = await http.get(uri).timeout(timeout);
        _isOnline = true;
        _resolvedBaseUrl = base;
        return res;
      } catch (e) {
        debugPrint('ApiService._get ($base$path) failed: $e');
      }
    }
    _isOnline = false;
    return null;
  }

  Future<http.Response?> _post(
    String path, {
    Object? body,
    Duration timeout = const Duration(seconds: 6),
  }) async {
    final targets = candidateUrls;
    for (int i = 0; i < targets.length; i++) {
      final base = targets[i];
      try {
        final uri = Uri.parse('$base$path');
        final res = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: body != null ? jsonEncode(body) : null,
            )
            .timeout(timeout);
        _isOnline = true;
        _resolvedBaseUrl = base;
        return res;
      } catch (e) {
        debugPrint('ApiService._post ($base$path) failed: $e');
      }
    }
    _isOnline = false;
    return null;
  }

  Future<http.Response?> _put(
    String path, {
    Object? body,
    Duration timeout = const Duration(seconds: 6),
  }) async {
    final targets = candidateUrls;
    for (int i = 0; i < targets.length; i++) {
      final base = targets[i];
      try {
        final uri = Uri.parse('$base$path');
        final res = await http
            .put(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: body != null ? jsonEncode(body) : null,
            )
            .timeout(timeout);
        _isOnline = true;
        _resolvedBaseUrl = base;
        return res;
      } catch (e) {
        debugPrint('ApiService._put ($base$path) failed: $e');
      }
    }
    _isOnline = false;
    return null;
  }

  Future<http.Response?> _delete(
    String path, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final targets = candidateUrls;
    for (int i = 0; i < targets.length; i++) {
      final base = targets[i];
      try {
        final uri = Uri.parse('$base$path');
        final res = await http.delete(uri).timeout(timeout);
        _isOnline = true;
        _resolvedBaseUrl = base;
        return res;
      } catch (e) {
        debugPrint('ApiService._delete ($base$path) failed: $e');
      }
    }
    _isOnline = false;
    return null;
  }

  Future<bool> checkHealth() async {
    try {
      final response = await _get('/health', timeout: const Duration(seconds: 3));
      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _isOnline = data['connected'] == true;
        return _isOnline;
      }
    } catch (_) {}
    _isOnline = false;
    return false;
  }

  // ----------------------------------------------------
  // CARETAKER AUTHENTICATION & PROFILES (MongoDB Atlas)
  // ----------------------------------------------------
  Future<Map<String, dynamic>?> signUpCaretaker(Map<String, dynamic> data) async {
    try {
      final response = await _post('/caretakers/signup', body: data);
      if (response != null) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
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
      final response = await _post('/caretakers/login', body: {
        'emailOrPhone': emailOrPhone,
        'password': password ?? '',
      });
      if (response != null) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
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
      final response = await _post('/patients', body: data);
      if (response != null) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('ApiService.registerPatient error: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> fetchPatients({String? caretakerId}) async {
    try {
      final response = await _get(
        '/patients',
        queryParams: caretakerId != null ? {'caretakerId': caretakerId} : null,
      );
      if (response != null && response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('ApiService.fetchPatients error: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> validatePatientPassKey(String passKey) async {
    try {
      final response = await _post('/patients/validate-passkey', body: {'passKey': passKey});
      if (response != null) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('ApiService.validatePatientPassKey error: $e');
    }
    return null;
  }

  // ----------------------------------------------------
  // MEMORIES (MongoDB Atlas)
  // ----------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchMemories({
    String? patientId,
    String? since,
  }) async {
    try {
      final response = await _get(
        '/memories',
        queryParams: _syncQuery(patientId, since),
      );
      if (response != null && response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('ApiService.fetchMemories error: $e');
    }
    return [];
  }

  Future<bool> saveMemory(Map<String, dynamic> memoryData) async {
    try {
      final response = await _post('/memories', body: memoryData);
      return response != null && (response.statusCode == 200 || response.statusCode == 201);
    } catch (e) {
      debugPrint('ApiService.saveMemory error: $e');
      return false;
    }
  }

  Future<bool> deleteMemory(String id) async {
    try {
      final response = await _delete('/memories/$id');
      return response != null && response.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService.deleteMemory error: $e');
      return false;
    }
  }

  // ----------------------------------------------------
  // FAMILY MEMBERS (MongoDB Atlas)
  // ----------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchFamilyMembers({
    String? patientId,
    String? since,
  }) async {
    try {
      final response = await _get(
        '/family',
        queryParams: _syncQuery(patientId, since),
      );
      if (response != null && response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('ApiService.fetchFamilyMembers error: $e');
    }
    return [];
  }

  Future<bool> saveFamilyMember(Map<String, dynamic> data) async {
    try {
      final response = await _post('/family', body: data);
      return response != null && (response.statusCode == 200 || response.statusCode == 201);
    } catch (e) {
      debugPrint('ApiService.saveFamilyMember error: $e');
      return false;
    }
  }

  Future<bool> deleteFamilyMember(String id) async {
    try {
      final response = await _delete('/family/$id');
      return response != null && response.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService.deleteFamilyMember error: $e');
      return false;
    }
  }

  // ----------------------------------------------------
  // ROUTINE REMINDERS (MongoDB Atlas)
  // ----------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchReminders({
    String? patientId,
    String? since,
  }) async {
    try {
      final response = await _get(
        '/reminders',
        queryParams: _syncQuery(patientId, since),
      );
      if (response != null && response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('ApiService.fetchReminders error: $e');
    }
    return [];
  }

  Future<bool> saveReminder(Map<String, dynamic> data) async {
    try {
      final response = await _post('/reminders', body: data);
      return response != null && (response.statusCode == 200 || response.statusCode == 201);
    } catch (e) {
      debugPrint('ApiService.saveReminder error: $e');
      return false;
    }
  }

  Future<bool> updateReminder(String id, Map<String, dynamic> data) async {
    try {
      final response = await _put('/reminders/$id', body: data);
      return response != null && response.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService.updateReminder error: $e');
      return false;
    }
  }

  Future<bool> deleteReminder(String id) async {
    try {
      final response = await _delete('/reminders/$id');
      return response != null && response.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService.deleteReminder error: $e');
      return false;
    }
  }

  // ----------------------------------------------------
  // GAME SCORES (MongoDB Atlas)
  // ----------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchGameScores({
    String? patientId,
    String? since,
  }) async {
    try {
      final response = await _get(
        '/gamescores',
        queryParams: _syncQuery(patientId, since),
      );
      if (response != null && response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('ApiService.fetchGameScores error: $e');
    }
    return [];
  }

  Future<bool> saveGameScore(Map<String, dynamic> data) async {
    try {
      final response = await _post('/gamescores', body: data);
      return response != null && (response.statusCode == 200 || response.statusCode == 201);
    } catch (e) {
      debugPrint('ApiService.saveGameScore error: $e');
      return false;
    }
  }

  Future<bool> deleteGameScore(String id) async {
    try {
      final response = await _delete('/gamescores/$id');
      return response != null && response.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService.deleteGameScore error: $e');
      return false;
    }
  }

  /// Builds the shared `?patientId=&since=` query map used by every
  /// incremental pull. Returns null when both are absent.
  Map<String, String>? _syncQuery(String? patientId, String? since) {
    final q = <String, String>{};
    if (patientId != null) q['patientId'] = patientId;
    if (since != null) q['since'] = since;
    return q.isEmpty ? null : q;
  }
}
