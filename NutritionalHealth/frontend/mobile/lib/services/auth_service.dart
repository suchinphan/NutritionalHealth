import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';
import 'app_config.dart';

class AuthService with ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _token;
  Map<String, dynamic>? _user;
  bool _isGuest = false;
  bool _guestUsed = false;
  String? _anonId;
  Map<String, dynamic>? _guestPersonal;
  Map<String, dynamic>? _guestSelections;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;
  bool get isGuest => _isGuest;
  bool get guestUsed => _guestUsed;

  bool get isGuestLocked {
    if (!_isGuest || !_guestUsed) return false;
    final Map<String, dynamic>? p = _guestPersonal;
    if (p == null) return false;
    try {
      final g = (p['gender'] ?? '').toString().trim();
      final a = (p['age'] ?? '').toString().trim();
      final w = (p['weight'] ?? '').toString().trim();
      final h = (p['height'] ?? '').toString().trim();
      return g.isNotEmpty && a.isNotEmpty && w.isNotEmpty && h.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  bool get canUseGuest => _isGuest && !_guestUsed;

  Future<void> loadToken() async {
    try {
      final guestVal = await _storage.read(key: 'auth_guest');
      final guestUsedVal = await _storage.read(key: 'auth_guest_used');
      final guestPersonalJson = await _storage.read(key: 'auth_guest_personal');
      final guestSelectionsJson = await _storage.read(
        key: 'auth_guest_selections',
      );
      if (guestVal == '1') {
        _isGuest = true;
        _guestUsed = (guestUsedVal == '1');
        _token = null;
        _user = null;

        try {
          if (guestPersonalJson != null) {
            _guestPersonal =
                jsonDecode(guestPersonalJson) as Map<String, dynamic>?;
          }
        } catch (_) {
          _guestPersonal = null;
        }

        try {
          if (guestSelectionsJson != null) {
            _guestSelections =
                jsonDecode(guestSelectionsJson) as Map<String, dynamic>?;
          }
        } catch (_) {
          _guestSelections = null;
        }

        if (kDebugMode) {
          debugPrint(
            'Guest state restored (persisted guest_used=$guestUsedVal)',
          );
        }
      } else {
        _token = await _storage.read(key: 'auth_token');
        final userJson = await _storage.read(key: 'auth_user');
        _isGuest = false;
        _guestUsed = false;
        if (userJson != null) {
          try {
            _user = jsonDecode(userJson) as Map<String, dynamic>?;
          } catch (_) {
            _user = null;
          }
        }
        debugPrint(
          'AuthService.loadToken: loaded persisted user/token (isGuest=false)',
        );
      }
    } catch (e) {
      debugPrint('AuthService.loadToken ERROR: $e');
    }
    notifyListeners();
  }

  Future<void> saveToken(String token) async {
    _token = token;
    try {
      await _storage.write(key: 'auth_token', value: token);
      debugPrint('AuthService.saveToken: wrote auth_token');
    } catch (e) {
      debugPrint('AuthService.saveToken ERROR: $e');
    }
    _isGuest = false;
    _guestUsed = false;
    await _storage.delete(key: 'auth_guest');
    await _storage.delete(key: 'auth_guest_used');
    notifyListeners();
  }

  Future<void> saveUser(Map<String, dynamic> u) async {
    _user = u;
    final encoded = jsonEncode(u);
    try {
      await _storage.write(key: 'auth_user', value: encoded);
      debugPrint('AuthService.saveUser: wrote auth_user');
    } catch (e) {
      debugPrint('AuthService.saveUser ERROR: $e');
    }

    try {
      final token = _token;
      final userMap = _user;
      if (token != null && userMap != null) {
        final idVal = userMap['id'] ?? userMap['user_id'] ?? userMap['userid'];
        final intId = idVal == null ? null : int.tryParse(idVal.toString());
        if (intId != null) {
          final Map<String, dynamic> toSend = {};
          void addIfPresent(String key) {
            final v = userMap[key];
            if (v != null) {
              final s = v.toString().trim();
              if (s.isNotEmpty) toSend[key] = s;
            }
          }

          addIfPresent('gender');
          addIfPresent('age');
          addIfPresent('weight');
          addIfPresent('height');

          if (toSend.isNotEmpty) {
            final api = ApiClient(getApiBase());
            final body = jsonEncode(toSend);
            const int maxAttempts = 1;
            int attempt = 0;
            bool succeeded = false;
            while (attempt < maxAttempts && !succeeded) {
              attempt += 1;
              try {
                final resp = await api.post(
                  '/user/$intId',
                  headers: {'Authorization': 'Bearer $token'},
                  body: body,
                  timeoutSeconds: 3,
                );
                if (resp.statusCode >= 200 && resp.statusCode < 300) {
                  debugPrint(
                    'AuthService.saveUser: remote profile updated for user $intId (attempt $attempt)',
                  );
                  succeeded = true;
                } else {
                  debugPrint(
                    'AuthService.saveUser: remote update failed ${resp.statusCode} ${resp.body} (attempt $attempt)',
                  );
                }
              } catch (e) {
                debugPrint(
                  'AuthService.saveUser: remote update error on attempt $attempt: $e',
                );
              }
            }
            if (!succeeded) {
              debugPrint(
                'AuthService.saveUser: all attempts failed for user $intId',
              );
            }
          } else {
            debugPrint(
              'AuthService.saveUser: no personal fields to send for user $intId; skipping remote update',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('AuthService.saveUser: remote update error: $e');
    }

    notifyListeners();
  }

  Future<void> saveGuest() async {
    try {
      _isGuest = true;
      try {
        await _storage.write(key: 'auth_guest', value: '1');
        debugPrint('AuthService.saveGuest: persisted auth_guest=1');
      } catch (e) {
        debugPrint('AuthService.saveGuest: failed to persist auth_guest: $e');
      }
      _guestUsed = false;
      if (_anonId == null) {
        final rnd = Random();
        _anonId =
            '${DateTime.now().millisecondsSinceEpoch}_${rnd.nextInt(1 << 31)}';
      }
    } catch (e) {
      debugPrint('AuthService.saveGuest ERROR: $e');
    }
    notifyListeners();
  }

  Future<void> clearGuest() async {
    debugPrint('AuthService.clearGuest: clearing guest-only state');
    _guestUsed = false;
    _guestPersonal = null;
    _guestSelections = null;
    _anonId = null;
    try {
      await _storage.delete(key: 'auth_guest');
      await _storage.delete(key: 'auth_guest_used');
      await _storage.delete(key: 'auth_guest_personal');
      await _storage.delete(key: 'auth_guest_selections');
      debugPrint('AuthService.clearGuest: removed persisted guest markers');
    } catch (e) {
      debugPrint('AuthService.clearGuest ERROR: $e');
    }
    _isGuest = false;
    notifyListeners();
  }

  Future<void> handleAuthSuccess(String token, Map<String, dynamic> u) async {
    await clearGuest();
    _isGuest = false;
    await saveToken(token);
    await saveUser(u);
    notifyListeners();
  }

  String? get anonId => _anonId;
  Map<String, dynamic>? get guestPersonal => _guestPersonal;
  Map<String, dynamic>? get guestSelections => _guestSelections;
  Map<String, dynamic>? _tempPersonal;
  Map<String, dynamic>? _tempSelections;

  Map<String, dynamic>? get tempPersonal => _tempPersonal;
  Map<String, dynamic>? get tempSelections => _tempSelections;

  void setTempPersonal(Map<String, dynamic> p) {
    _tempPersonal = Map<String, dynamic>.from(p);
    notifyListeners();
  }

  void setTempSelections(Map<String, dynamic> s) {
    _tempSelections = Map<String, dynamic>.from(s);
    notifyListeners();
  }

  Future<void> saveGuestPersonal(Map<String, dynamic> p) async {
    _guestPersonal = Map<String, dynamic>.from(p);
    try {
      final encoded = jsonEncode(_guestPersonal);
      await _storage.write(key: 'auth_guest_personal', value: encoded);
      debugPrint(
        'AuthService.saveGuestPersonal: persisted auth_guest_personal',
      );
    } catch (e) {
      debugPrint('AuthService.saveGuestPersonal ERROR: $e');
    }
    notifyListeners();
  }

  Future<void> saveGuestSelections(Map<String, dynamic> s) async {
    // 🔒 ป้องกัน guest ใช้ซ้ำ
    if (_guestUsed) {
      debugPrint('Guest already used — skip saving selections');
      return;
    }

    _guestSelections = Map<String, dynamic>.from(s);
    try {
      final encoded = jsonEncode(_guestSelections);
      await _storage.write(key: 'auth_guest_selections', value: encoded);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> ensureAnonId() async {
    if (_anonId != null) return;
    final rnd = Random();
    _anonId =
        '${DateTime.now().millisecondsSinceEpoch}_${rnd.nextInt(1 << 31)}';
  }

  Future<void> markGuestUsed() async {
    if (!_isGuest) return;
    if (_guestUsed) return;
    _guestUsed = true;
    try {
      await _storage.write(key: 'auth_guest_used', value: '1');
      debugPrint('AuthService.markGuestUsed: persisted auth_guest_used=1');
    } catch (e) {
      debugPrint('AuthService.markGuestUsed ERROR: $e');
    }
    notifyListeners();
  }

  Future<void> resetGuestUsed() async {
    _guestUsed = false;
    try {
      await _storage.delete(key: 'auth_guest_used');
      debugPrint(
        'AuthService.resetGuestUsed: removed persisted auth_guest_used',
      );
    } catch (e) {
      debugPrint('AuthService.resetGuestUsed ERROR: $e');
    }
    notifyListeners();
  }

  Future<void> clearToken({bool force = false}) async {
    if (_isGuest && !force) {
      debugPrint(
        'AuthService.clearToken skipped: current session is Guest (use force=true to override)',
      );
      return;
    }
    debugPrint('AuthService.clearToken: clearing auth state (force=$force)');
    _token = null;
    _user = null;
    _isGuest = false;
    _guestUsed = false;
    _guestPersonal = null;
    _guestSelections = null;
    _anonId = null;
    try {
      await _storage.delete(key: 'auth_token');
      await _storage.delete(key: 'auth_user');
      await _storage.delete(key: 'auth_guest');
      await _storage.delete(key: 'auth_guest_used');
      await _storage.delete(key: 'auth_guest_personal');
      await _storage.delete(key: 'auth_guest_selections');
      await _storage.delete(key: 'anon_id');
      debugPrint('AuthService.clearToken: cleared auth storage keys');
    } catch (e) {
      debugPrint('AuthService.clearToken ERROR: $e');
    }
    notifyListeners();
  }

  Future<void> logout() async {
    debugPrint('🔥 LOGOUT CALLED 🔥');
    try {
      debugPrint('Logout stack:\n' + StackTrace.current.toString());
    } catch (_) {}
    await clearToken(force: true);
  }

  // 🔥 FIXED CHANGE PASSWORD
  Future<Map<String, dynamic>> changePassword({
    required String username,
    required String email,
    required String oldPassword,
    required String newPassword,
    bool useAuth = true,
  }) async {
    // ✅ โหลด token จาก memory หรือ storage (แต่ไม่บังคับให้ต้องมี)
    if (_token == null || _token!.isEmpty) {
      _token = await _storage.read(key: 'auth_token');
    }

    final api = ApiClient(getApiBase());

    final body = jsonEncode({
      'username': username,
      'email': email,
      'old_password': oldPassword,
      'new_password': newPassword,
    });

    final headers = <String, String>{'Content-Type': 'application/json'};
    if (useAuth) {
      if (_token != null && _token!.isNotEmpty) {
        headers['Authorization'] = 'Bearer $_token';
      }
    }

    final resp = await api.post(
      '/change-password',
      headers: headers,
      body: body,
    );

    final decoded = <String, dynamic>{};

    try {
      if (resp.body.isNotEmpty) {
        final d = jsonDecode(resp.body);
        if (d is Map<String, dynamic>) {
          decoded.addAll(d);
        }
      }
    } catch (_) {}

    decoded['statusCode'] = resp.statusCode;
    return decoded;
  }

  // ==========================================================
  // 🔥 RESET PASSWORD (ใช้ reset_token + current_password)
  // Backend ต้องการ:
  // reset_token
  // current_password
  // new_password
  // ==========================================================
  Future<Map<String, dynamic>> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    // Client-side validation: token must be present and non-empty
    if (resetToken.trim().isEmpty) {
      return {'error': 'reset_token required', 'statusCode': 400};
    }

    final api = ApiClient(getApiBase());

    final body = jsonEncode({
      'reset_token': resetToken.trim(),
      'new_password': newPassword,
    });

    final resp = await api.post(
      '/reset-password',
      headers: {'Content-Type': 'application/json', 'X-Skip-Auth': '1'},
      body: body,
    );

    final decoded = <String, dynamic>{};

    try {
      if (resp.body.isNotEmpty) {
        final d = jsonDecode(resp.body);
        if (d is Map<String, dynamic>) {
          decoded.addAll(d);
        }
      }
    } catch (_) {}

    decoded['statusCode'] = resp.statusCode;
    return decoded;
  }

  // New: reset via OTP (forgot-password flow)
  Future<Map<String, dynamic>> resetPasswordWithOtp({
    required String resetToken,
    required String otp,
    required String newPassword,
    String? username,
    String? email,
  }) async {
    final t = resetToken.trim();
    final o = otp.trim();
    final u = username?.trim();
    final e = email?.trim();
    if (t.isEmpty) return {'error': 'reset_token required', 'statusCode': 400};
    if (o.isEmpty) return {'error': 'otp required', 'statusCode': 400};

    final api = ApiClient(getApiBase());
    final bodyMap = {'reset_token': t, 'otp': o, 'new_password': newPassword};
    if (u != null && u.isNotEmpty) bodyMap['username'] = u;
    if (e != null && e.isNotEmpty) bodyMap['email'] = e;
    final body = jsonEncode(bodyMap);

    final resp = await api.post(
      '/reset-password',
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    final decoded = <String, dynamic>{};
    try {
      if (resp.body.isNotEmpty) {
        final d = jsonDecode(resp.body);
        if (d is Map<String, dynamic>) decoded.addAll(d);
      }
    } catch (_) {}
    decoded['statusCode'] = resp.statusCode;
    return decoded;
  }

  // Compatibility wrapper: some pages still call `resetPassword` with the
  // change-password parameter names (username/email/oldPassword/newPassword).
  // The compatibility extension is placed after the class closing brace.

  Future<bool> saveSelection(Map<String, dynamic> data) async {
    try {
      // ensure token loaded
      if (_token == null || _token!.isEmpty) {
        _token = await _storage.read(key: 'auth_token');
      }
      if (_token == null || _token!.isEmpty) return false;

      final api = ApiClient(getApiBase());

      final resp = await api.post(
        '/save-selection',
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
        timeoutSeconds: 7,
      );

      return resp.statusCode >= 200 && resp.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
}
