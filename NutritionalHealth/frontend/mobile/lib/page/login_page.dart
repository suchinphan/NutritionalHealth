// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

// นำเข้าหน้า ForgotPasswordPage และ ChangePasswordPage ให้ถูกต้อง
import 'Forgot_your_password_page.dart'; // นำเข้าหน้า ForgotPasswordPage
import 'Change_Password_page.dart'; // นำเข้าหน้า ChangePasswordPage
import '../services/auth_service.dart';
import '../main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final Color primaryGreen = const Color(0xFF00C700);
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  
  final String apiBase = kIsWeb
      ? 'http://127.0.0.1:5000'
      : (defaultTargetPlatform == TargetPlatform.android ? 'http://10.0.2.2:5000' : 'http://127.0.0.1:5000');

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String hint, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[500]),
      filled: true,
      fillColor: Colors.grey[200],
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide.none,
      ),
      suffixIcon: suffix,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 24, 18, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 18),
                  Text('เข้าสู่ระบบ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryGreen)),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _userController,
                    decoration: _inputDecoration('ชื่อผู้ใช้'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passController,
                    obscureText: _obscure,
                    decoration: _inputDecoration(
                      'รหัสผ่าน',
                      suffix: GestureDetector(
                        onTap: () => setState(() => _obscure = !_obscure),
                        child: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Guest login button (mid)
                  Center(
                    child: ElevatedButton(
                      onPressed: _loading
                              ? null
                              : () async {
                          final uname = _userController.text.trim();
                          final pwd = _passController.text;
                          if (uname.isNotEmpty || pwd.isNotEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาล้างช่องชื่อผู้ใช้และรหัสผ่านก่อนเข้าสู่ระบบแบบผู้เยี่ยมชม')));
                            return;
                          }
                          setState(() => _loading = true);
                          try {
                            await AuthService().saveGuest();
                            await AuthService().ensureAnonId();
                            if (!mounted) return;
                            final messenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(context);
                            messenger.showSnackBar(const SnackBar(content: Text('เข้าสู่ระบบแบบผู้เยี่ยมชม')));
                            setState(() => _loading = false);
                            navigator.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const MainScreen()), (route) => false);
                          } catch (e) {
                            if (!mounted) return;
                            setState(() => _loading = false);
                            final messenger = ScaffoldMessenger.of(context);
                            messenger.showSnackBar(const SnackBar(content: Text('เกิดข้อผิดพลาดขณะเปิดใช้งานโหมดผู้เยี่ยมชม')));
                          }
                        },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        elevation: 0,
                      ),
                      child: const Text('เข้าสู่ระบบโดยไม่มีบัญชี', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Forgot / change password - use Wrap so items can wrap to next line on narrow screens
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('จำรหัสผ่านไม่ได้', style: TextStyle(color: Colors.grey[500])),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => ForgotPasswordPage()));
                        },
                        child: Text('ลืมรหัสผ่าน', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w600)),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ChangePasswordPage()));
                        },
                        child: Text('เปลี่ยนรหัสผ่าน', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 120),
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
                  onPressed: _loading
                      ? null
                      : () async {
                      setState(() => _loading = true);
                    final username = _userController.text.trim();
                    final password = _passController.text;
                    if (username.isEmpty || password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณากรอกชื่อผู้ใช้และรหัสผ่าน')));
                      setState(() => _loading = false);
                      return;
                    }
                    final url = Uri.parse('$apiBase/login');
                      try {
                      final resp = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'username': username, 'password': password}));
                      if (resp.statusCode == 200) {
                        final j = jsonDecode(resp.body);
                        final token = j['password_token'] as String? ?? j['authToken'] as String?;
                        if (token != null) {
                          await AuthService().saveToken(token);
                          await AuthService().saveUser({'id': j['id'] ?? j['user_id'], 'username': j['username'], 'email': j['email']});
                        }
                        if (!mounted) return;
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);
                        messenger.showSnackBar(const SnackBar(content: Text('เข้าสู่ระบบเรียบร้อย')));
                        setState(() => _loading = false);
                        navigator.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const MainScreen()), (route) => false);
                      } else {
                        String msg = 'เข้าสู่ระบบไม่สำเร็จ';
                        try {
                          final j = jsonDecode(resp.body);
                          if (j is Map && j['error'] != null) msg = j['error'].toString();
                        } catch (_) {}
                        if (!mounted) return;
                        setState(() => _loading = false);
                        final messenger = ScaffoldMessenger.of(context);
                        messenger.showSnackBar(SnackBar(content: Text(msg)));
                      }
                    } catch (e) {
                      if (!mounted) return;
                      setState(() => _loading = false);
                      final messenger = ScaffoldMessenger.of(context);
                      messenger.showSnackBar(const SnackBar(content: Text('ไม่สามารถติดต่อเซิร์ฟเวอร์ได้')));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    elevation: 0,
                  ),
                  child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('เข้าสู่ระบบ', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
