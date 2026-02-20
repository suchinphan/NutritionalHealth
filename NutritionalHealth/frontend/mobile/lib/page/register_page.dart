import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import '../services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final Color primaryGreen = const Color(0xFF00C700);

  final TextEditingController _userController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  final String apiBase = kIsWeb
      ? 'http://127.0.0.1:5000'
      : (defaultTargetPlatform == TargetPlatform.android
          ? 'http://10.0.2.2:5000'
          : 'http://127.0.0.1:5000');

  @override
  void dispose() {
    _userController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String hint, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[500]),
      filled: true,
      fillColor: Colors.grey[200],
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide.none,
      ),
      suffixIcon: suffix,
    );
  }

  void _onRegister() async {
    if (_loading) return;

    final user = _userController.text.trim();
    final email = _emailController.text.trim();
    final pass = _passController.text;
    final confirm = _confirmController.text;

    if (user.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ชื่อผู้ใช้อย่างน้อย 4 ตัวอักษร')));
      return;
    }

    final emailReg = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailReg.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณากรอกอีเมลให้ถูกต้อง')));
      return;
    }

    if (pass.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร')));
      return;
    }

    final reg =
        RegExp(r'(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[^A-Za-z0-9])');
    if (!reg.hasMatch(pass)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'รหัสผ่านต้องมีตัวพิมพ์ใหญ่, พิมพ์เล็ก, ตัวเลข และอักขระพิเศษ')));
      return;
    }

    if (pass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณายืนยันรหัสผ่านให้ตรงกัน')));
      return;
    }

    setState(() => _loading = true);

    final url = Uri.parse('$apiBase/register/');

    try {
      final resp = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': user,
              'email': email,
              'password': pass,
              'confirm_password': confirm
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode >= 200 &&
          resp.statusCode < 300 &&
          resp.body.isNotEmpty) {
        final j = jsonDecode(resp.body);

        final token = j['token'] ??
            j['authToken'] ??
            j['password_token'] ??
            (j['data'] != null ? j['data']['authToken'] : null);

        final id = j['user_id'] ??
            j['id'] ??
            (j['data'] != null ? j['data']['userid'] : null);

        if (token != null && id != null) {
          await AuthService().handleAuthSuccess(
            token,
            {
              'id': id,
              'username': j['username'] ?? user,
              'email': j['email'] ?? email,
            },
          );
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('สมัครสมาชิกเรียบร้อย')));

        Navigator.of(context).maybePop();
      } else {
        String msg = 'สมัครสมาชิกไม่สำเร็จ';
        try {
          if (resp.body.isNotEmpty) {
            final j = jsonDecode(resp.body);
            if (j is Map && j['error'] != null) {
              msg = j['error'].toString();
            }
          }
        } catch (_) {}

        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่สามารถติดต่อเซิร์ฟเวอร์ได้')));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(18, 12, 18, 90),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () =>
                            Navigator.of(context).maybePop(),
                        child: Icon(Icons.arrow_back,
                            color: primaryGreen),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'สมัครสมาชิก',
                            style: TextStyle(
                                color: primaryGreen,
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _userController,
                    textInputAction: TextInputAction.next,
                    decoration:
                        _inputDecoration('ชื่อผู้ใช้งาน'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    keyboardType:
                        TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration:
                        _inputDecoration('อีเมล'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passController,
                    obscureText: _obscurePass,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration(
                      'รหัสผ่าน',
                      suffix: GestureDetector(
                        onTap: () => setState(() =>
                            _obscurePass =
                                !_obscurePass),
                        child: Icon(
                          _obscurePass
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmController,
                    obscureText: _obscureConfirm,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _onRegister(),
                    decoration: _inputDecoration(
                      'ยืนยันรหัสผ่าน',
                      suffix: GestureDetector(
                        onTap: () => setState(() =>
                            _obscureConfirm =
                                !_obscureConfirm),
                        child: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: _loading ? null : _onRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                      : const Text(
                          'สมัครสมาชิก',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16),
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
