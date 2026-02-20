import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart'
  show kIsWeb, defaultTargetPlatform, TargetPlatform;
import '../services/app_config.dart';
import 'login_page.dart';
import 'register_login_page.dart';
import 'package:flutter/services.dart';
import 'Change_Password_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  final String? initialUsername;
  final String? initialEmail;

  const ForgotPasswordPage({
    super.key,
    this.initialUsername,
    this.initialEmail,
  });

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _loading = false;

  final Color primaryGreen = const Color(0xFF00C700);

  @override
  void dispose() {
    _userCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialUsername != null) {
      _userCtrl.text = widget.initialUsername!;
    }
    if (widget.initialEmail != null) {
      _emailCtrl.text = widget.initialEmail!;
    }
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final String apiBase = getApiBase();
    final url = Uri.parse('$apiBase/forgot-password');

    final payload = jsonEncode({
      'username': _userCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
    });

    try {
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: payload,
      );

      if (!mounted) return;
      setState(() => _loading = false);

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        // DEBUG: print full response body to help debugging token issues
        try {
          debugPrint('forgot-password response body: ${resp.body}');
        } catch (_) {}

        final data = jsonDecode(resp.body) as Map<String, dynamic>?;
        final token = data == null ? null : (data['reset_token'] as String?);
        final otp = data == null ? null : (data['otp'] as String?);
        final respUsername = data == null ? null : (data['username'] as String?);
        final respEmail = data == null ? null : (data['email'] as String?);

        if (token == null || token.isEmpty) {
          // Token missing — show error instead of empty popup
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่พบโทเค่นจากเซิร์ฟเวอร์')),
          );
          return;
        }
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Center(
              child: Text(
                'ข้อมูลสำหรับรีเซ็ตรหัสผ่าน',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    'Token: $token',
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                if (otp != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      'OTP: $otp',
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(
                          ClipboardData(text: token));
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('คัดลอกแล้ว')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('คัดลอก'),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => ChangePasswordPage(
                            initialUsername: respUsername ?? _userCtrl.text.trim(),
                            initialEmail: respEmail ?? _emailCtrl.text.trim(),
                            initialToken: token,
                            initialOtp: otp,
                          ),
                        ),
                      );
                    },
                    child: const Text('ตกลง'),
                  ),
                ],
              ),
            ],
          ),
        );
      } else {
        String msg = 'ไม่สามารถดำเนินการลืมรหัสผ่านได้';
        try {
          final j = jsonDecode(resp.body);
          if (j is Map && j['error'] != null) {
            msg = j['error'].toString();
          }
        } catch (_) {}

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถติดต่อเซิร์ฟเวอร์ได้')),
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
          'ลืมรหัสผ่าน',
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
              'ลืมรหัสผ่าน',
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
                      decoration: const InputDecoration.collapsed(
                          hintText: 'ชื่อผู้ใช้งาน'),
                      validator: (v) {
                        final s = (v ?? '').trim();
                        if (s.isEmpty) {
                          return 'กรุณากรอกชื่อผู้ใช้งาน';
                        }
                        if (s.length < 4) {
                          return 'ชื่อผู้ใช้งานต้องมีอย่างน้อย 4 ตัวอักษร';
                        }
                        final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
                        if (!usernameRegex.hasMatch(s)) {
                          return 'รูปแบบชื่อผู้ใช้งานไม่ถูกต้อง';
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
                        if (_formKey.currentState?.validate() ??
                            false) {
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
