import 'package:flutter/material.dart';
import 'login_page.dart';
import 'register_page.dart';
// removed import of main.dart to avoid circular import
// removed unused page imports (analyzer flagged unused_import)

class RegisterLoginPage extends StatelessWidget {
  const RegisterLoginPage({super.key});

  final Color primaryGreen = const Color(0xFF00C700);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 12,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // ไปยังหน้าเข้าสู่ระบบ (login_page.dart)
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'เข้าสู่ระบบ',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // ไปยังหน้าสมัครสมาชิก (register_page.dart)
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RegisterPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'สมัครสมาชิก',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            // center vertically
            const Spacer(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 56,
        color: primaryGreen,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            SizedBox(width: 48, child: Icon(Icons.home, color: Colors.white)),
            SizedBox(width: 48, child: Icon(Icons.search, color: Colors.white)),
            SizedBox(width: 48, child: Icon(Icons.menu, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
