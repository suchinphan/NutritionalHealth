import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'calculate2_page.dart';

class CalculatePage extends StatefulWidget {
  const CalculatePage({super.key});

  @override
  State<CalculatePage> createState() => _CalculatePageState();
}

class _CalculatePageState extends State<CalculatePage> {
  final Color primaryGreen = const Color(0xFF00C700);
  bool _authLoaded = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      try {
        await AuthService().loadToken();
      } catch (_) {}
      if (mounted) setState(() => _authLoaded = true);
    });
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w600),
    ),
  );

  Widget _greyBox(String text) {
    return Container(
      height: 44,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        text.isNotEmpty ? text : '-',
        style: TextStyle(color: Colors.grey[700]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_authLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final auth = AuthService();

    // ✅ ดึงข้อมูลร่างกายจากที่กรอกไว้ก่อนหน้า
    final personal = auth.tempPersonal ?? auth.guestPersonal ?? auth.user ?? {};

    final gender = personal['gender']?.toString() ?? 'ไม่ระบุ';
    final age = personal['age']?.toString() ?? '-';
    final weight = personal['weight']?.toString() ?? '-';
    final height = personal['height']?.toString() ?? '-';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryGreen),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'ข้อมูลร่างกาย',
          style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Builder(
                builder: (ctx) {
                  final auth = AuthService();
                  final displayName = auth.isGuest
                      ? 'Guest'
                      : (auth.user?['username'] ??
                            auth.user?['name'] ??
                            (auth.user?['email'] != null
                                ? auth.user!['email']
                                      .toString()
                                      .split('@')
                                      .first
                                : '') ??
                            '');
                  return Text(
                    displayName,
                    style: TextStyle(
                      color: primaryGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _label('เพศ'),
            _greyBox(gender),
            const SizedBox(height: 12),

            _label('อายุ'),
            _greyBox(age),
            const SizedBox(height: 12),

            _label('น้ำหนัก (กก.)'),
            _greyBox(weight),
            const SizedBox(height: 12),

            _label('ส่วนสูง (ซม.)'),
            _greyBox(height),

            const Spacer(),

            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  // ✅ เก็บข้อมูลร่างกาย (guest = temp, member = ใช้ต่อได้)
                  auth.setTempPersonal({
                    'gender': gender,
                    'age': age,
                    'weight': weight,
                    'height': height,
                  });

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const Calculate2Page()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'ถัดไป',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
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
