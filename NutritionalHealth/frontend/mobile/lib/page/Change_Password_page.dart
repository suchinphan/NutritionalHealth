import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'login_page.dart';
import 'register_login_page.dart';
import '../services/auth_service.dart';

class ChangePasswordPage extends StatefulWidget {
  final String? initialUsername;
  final String? initialEmail;
  final String? initialToken;
  final String? initialOtp;

  const ChangePasswordPage({
    super.key,
    this.initialUsername,
    this.initialEmail,
    this.initialToken,
    this.initialOtp,
  });

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _isForgotMode = false;
  
  bool _loading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;

  final Color primaryGreen = const Color(0xFF00C700);

  @override
  void dispose() {
    _userCtrl.dispose();
    _emailCtrl.dispose();
    _tokenCtrl.dispose();
    _otpCtrl.dispose();
   
    _currentCtrl.dispose();
    _newCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Prefill controllers if initial values provided (from forgot flow)
    try {
      if (widget.initialUsername != null) _userCtrl.text = widget.initialUsername!;
    } catch (_) {}
    try {
      if (widget.initialEmail != null) _emailCtrl.text = widget.initialEmail!;
    } catch (_) {}
    try {
      if (widget.initialToken != null) {
        _tokenCtrl.text = widget.initialToken!;
        _isForgotMode = true;
      }
    } catch (_) {}
    try {
      if (widget.initialOtp != null) _otpCtrl.text = widget.initialOtp!;
    } catch (_) {}
  }

  Future<void> _onSubmit() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _loading = true);

  try {
    final currentText = _currentCtrl.text.trim();
    final newPasswordText = _newCtrl.text.trim();
    final otpText = _otpCtrl.text.trim();

    // Decide flow by mode flag
    final isForgot = _isForgotMode;

    // Quick client-side guard: if normal mode and user provided a real current password
    // and it's the same as the new password, reject early.
    if (!isForgot && currentText == newPasswordText) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('รหัสผ่านใหม่ต้องไม่ซ้ำกับรหัสผ่านปัจจุบัน')),
      );
      return;
    }

    Map<String, dynamic> result;
    if (isForgot) {
      // Forgot-password flow: require OTP + email
      final tokenText = _tokenCtrl.text.trim();
      if (tokenText.isEmpty) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณากรอก Token')),
        );
        return;
      }

      if (otpText.isEmpty) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณากรอก OTP')),
        );
        return;
      }
      result = await AuthService().resetPasswordWithOtp(
        resetToken: tokenText,
        otp: otpText,
        newPassword: newPasswordText,
        username: _userCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
      );
    } else {
      // Authenticated flow
      result = await AuthService().changePassword(
        username: _userCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        oldPassword: currentText,
        newPassword: newPasswordText,
      );
    }

    if (!mounted) return;
    setState(() => _loading = false);

    if (result['statusCode'] == 200 || result['statusCode'] == 201) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('สำเร็จ'),
          content: const Text('รหัสผ่านถูกเปลี่ยนเรียบร้อยแล้ว'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const LoginPage(),
                  ),
                );
              },
              child: const Text('ตกลง'),
            ),
          ],
        ),
      );
    } else {
      // Map backend errors to user-friendly Thai messages depending on flow
      String msg = 'ไม่สามารถเปลี่ยนรหัสผ่านได้';

      final err = (result['error'] ?? result['message'] ?? '').toString();

      if (isForgot) {
        if (err.contains('invalid token')) {
          msg = 'ไม่พบ token กรุณาเข้าสู่ระบบใหม่';
        } else if (err.contains('token expired')) {
          msg = 'token หมดอายุ กรุณาขอกำหนดรหัสผ่านใหม่';
        } else {
          msg = err.isNotEmpty ? err : msg;
        }
      } else {
        if (result['statusCode'] == 401) {
          // Distinguish between not-logged-in vs wrong current password
          if (err.contains('กรุณาเข้าสู่ระบบ') || err.toLowerCase().contains('authorization') || err.toLowerCase().contains('token')) {
            msg = 'กรุณาเข้าสู่ระบบใหม่';
          } else {
            msg = 'รหัสผ่านเดิมหรือ token ไม่ถูกต้อง';
          }
        } else {
          msg = err.isNotEmpty ? err : msg;
        }
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  } catch (e) {
    if (!mounted) return;
    setState(() => _loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('เกิดข้อผิดพลาด')),
    );
  }
}

  Widget _roundedField({required Widget child}) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const RegisterLoginPage(),
            ),
          ),
          icon: Icon(Icons.arrow_back, color: primaryGreen),
        ),
        title: Text(
          'เปลี่ยนรหัสผ่าน',
          style: TextStyle(color: primaryGreen),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Text(
              'เปลี่ยนรหัสผ่าน',
              style: TextStyle(
                color: primaryGreen,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _roundedField(
                    child: TextFormField(
                      controller: _userCtrl,
                      readOnly: _isForgotMode,
                      decoration: const InputDecoration.collapsed(
                          hintText: 'ชื่อผู้ใช้งาน'),
                      validator: (v) {
                        final s = (v ?? '').trim();
                        if (s.isEmpty) return 'กรุณากรอกชื่อผู้ใช้งาน';

                        final usernameRegex = RegExp(r'^[a-zA-Z0-9_]{4,}$');
                        if (!usernameRegex.hasMatch(s)) {
                          return 'ชื่อผู้ใช้งานต้องมีอย่างน้อย 4 ตัว และมีเฉพาะ a-z, A-Z, 0-9 หรือ _';
                        }

                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  _roundedField(
                    child: TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      readOnly: _isForgotMode,
                      decoration: const InputDecoration.collapsed(
                          hintText: 'อีเมล์'),
                      validator: (v) {
                        final s = (v ?? '').trim();
                        if (s.isEmpty) return 'กรุณากรอกอีเมล์';
                        final emailRegex =
                            RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$");
                        if (!emailRegex.hasMatch(s)) {
                          return 'รูปแบบอีเมล์ไม่ถูกต้อง';
                        }
                        return null;
                      },
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _isForgotMode = !_isForgotMode;
                        });
                      },
                      child: Text(
                        _isForgotMode ? 'กลับไปโหมดปกติ' : 'ลืมรหัสผ่าน?',
                        style: TextStyle(color: primaryGreen),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 12),
                  // Old password: show only in normal mode
                  if (!_isForgotMode)
                    const SizedBox(height: 12),
                  if (!_isForgotMode)
                    _roundedField(
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _currentCtrl,
                              obscureText: _obscureCurrent,
                              decoration: const InputDecoration.collapsed(
                                  hintText: 'รหัสผ่านเดิม'),
                              validator: (v) {
                                if ((v ?? '').isEmpty) {
                                  return 'กรุณากรอกรหัสผ่านเดิม';
                                }
                                return null;
                              },
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(
                                () => _obscureCurrent = !_obscureCurrent),
                            icon: Icon(
                              _obscureCurrent
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey[700],
                            ),
                          )
                        ],
                      ),
                    ),

                  // Token + OTP fields: show only in forgot mode
                  if (_isForgotMode) ...[
                    const SizedBox(height: 12),
                    _roundedField(
                      child: TextFormField(
                        controller: _tokenCtrl,
                        decoration: const InputDecoration.collapsed(
                          hintText: 'Token',
                        ),
                        validator: (v) {
                          if ((v ?? '').isEmpty) {
                            return 'กรุณากรอก Token';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    _roundedField(
                      child: TextFormField(
                        controller: _otpCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration.collapsed(
                          hintText: 'OTP',
                        ),
                        validator: (v) {
                          if ((v ?? '').isEmpty) {
                            return 'กรุณากรอก OTP';
                          }
                          if (v!.length != 6) {
                            return 'OTP ต้องมี 6 หลัก';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _roundedField(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _newCtrl,
                            obscureText: _obscureNew,
                            decoration: const InputDecoration.collapsed(
                                hintText: 'รหัสผ่านใหม่'),
                            validator: (v) {
                              final s = v ?? '';
                              if (s.isEmpty) {
                                return 'กรุณากรอกรหัสผ่านใหม่';
                              }
                              if (s.length < 8) {
                                return 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร';
                              }
                              final policy = RegExp(
                                  r'(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[^A-Za-z0-9])');
                              if (!policy.hasMatch(s)) {
                                return 'รหัสผ่านต้องมีตัวพิมพ์ใหญ่ พิมพ์เล็ก ตัวเลข และอักขระพิเศษ';
                              }
                              // Additional: new password must not equal old password in normal mode
                              if (!_isForgotMode) {
                                final old = _currentCtrl.text.trim();
                                if (old.isNotEmpty && old == s) {
                                  return 'ห้ามใช้รหัสผ่านซ้ำกับรหัสเดิม';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              setState(() => _obscureNew = !_obscureNew),
                          icon: Icon(
                            _obscureNew
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey[700],
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Spacer(),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _loading
                    ? null
                    : () {
                        if (_formKey.currentState?.validate() ?? false) {
                          _onSubmit();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'ตกลง',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
