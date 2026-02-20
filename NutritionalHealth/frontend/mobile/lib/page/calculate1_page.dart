import 'package:flutter/material.dart';
// removed import of main.dart to avoid circular import
import '../services/auth_service.dart';
// navigation now goes to Calculate2Page instead of ShowFoodItemsPage
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'calculate2_page.dart';

// guest data is stored in-memory via AuthService
// removed unused import: history_page.dart (analyzer flagged unused_import)

class CalculatePage extends StatefulWidget {
  // fields including optional selections passed from previous pages
  final String gender;
  final String age;
  final String weight;
  final String height;
  final String selectedType;
  final String selectedCategory;
  final String selectedMenu;
  final String selectedDessert;
  final String selectedDrinkType;
  final String selectedDrinkMenu;
  final String meal;
  final int duration;

  // รับค่าจากหน้าที่ผู้ใช้กรอก (optional)
  const CalculatePage({
    super.key,
    this.gender = 'ไม่ระบุ',
    this.age = '-',
    this.weight = '-',
    this.height = '-',
    this.selectedType = '',
    this.selectedCategory = '',
    this.selectedMenu = '',
    this.selectedDessert = '',
    this.selectedDrinkType = '',
    this.selectedDrinkMenu = '',
    required this.meal,
    required this.duration,
  });

  @override
  State<CalculatePage> createState() => _CalculatePageState();
}

class _CalculatePageState extends State<CalculatePage> {
  final Color primaryGreen = const Color(0xFF00C700);
  bool _authLoaded = false;

  @override
  void initState() {
    super.initState();
    // Ensure persisted auth/user data is loaded so saved personal info is available
    Future.microtask(() async {
      try {
        await AuthService().loadToken();
      } catch (_) {}
      // loaded auth state
      if (mounted) setState(() => _authLoaded = true);
    });
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6.0),
        child: Text(text, style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w600)),
      );

  Widget _greyBox(String text, {double height = 44}) {
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Text(text, style: TextStyle(color: Colors.grey[700])),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_authLoaded) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    // debug prints removed
    // gather values from AuthService if not provided
    final auth = AuthService();
    final saved = auth.user ?? auth.guestPersonal ?? {};
    final displayGender = (widget.gender != 'ไม่ระบุ' && widget.gender.isNotEmpty) ? widget.gender : (saved['gender']?.toString() ?? 'ไม่ระบุ');
    final displayAge = (widget.age != '-' && widget.age.isNotEmpty) ? widget.age : (saved['age']?.toString() ?? '-');
    final displayWeight = (widget.weight != '-' && widget.weight.isNotEmpty) ? widget.weight : (saved['weight']?.toString() ?? '-');
    final displayHeight = (widget.height != '-' && widget.height.isNotEmpty) ? widget.height : (saved['height']?.toString() ?? '-');
    // Only show personal info (no selections passed through this summary page)

    // This page is read-only summary of personal data; no calculations here.
    final savedMap = saved;
    final hasPersonalInfo = savedMap['gender'] != null && savedMap['age'] != null && savedMap['weight'] != null && savedMap['height'] != null;
    final canSubmit = auth.isLoggedIn || (!auth.isGuestLocked && hasPersonalInfo);
    final viewOnly = auth.isGuestLocked; // when true, user can only view results (locked guest)
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 120),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // Header: back, title, User ID
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).maybePop(),
                          child: Icon(Icons.arrow_back, color: primaryGreen, size: 30),
                        ),
                        const Expanded(child: SizedBox()),
                        Text('คำนวณ', style: TextStyle(color: primaryGreen, fontSize: 18, fontWeight: FontWeight.w700)),
                        const Expanded(child: SizedBox()),
                        Builder(builder: (_) {
                          final auth2 = auth; // auth already defined above
                          String idText2 = 'Guest';
                          if (auth2.isLoggedIn && auth2.user != null) {
                            final uname = auth2.user!['username'] ?? auth2.user!['name'] ?? (auth2.user!['id']?.toString() ?? '—');
                            idText2 = uname;
                          } else if (auth2.isGuest) {
                            idText2 = 'Guest';
                          }
                          return Text(idText2, style: TextStyle(color: primaryGreen));
                        }),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1, color: Colors.black12),
                    const SizedBox(height: 12),
                    Text('ข้อมูลที่ได้รับ', style: TextStyle(color: primaryGreen, fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    _label('เพศ'),
                    _greyBox(displayGender),
                    const SizedBox(height: 12),
                    _label('อายุ'),
                    _greyBox(displayAge),
                    const SizedBox(height: 12),
                    _label('น้ำหนัก'),
                    _greyBox(displayWeight),
                    const SizedBox(height: 12),
                    _label('ส่วนสูง'),
                    _greyBox(displayHeight),
                    const SizedBox(height: 12),
                    // Read-only page: only show personal info (no status, no food suggestions)
                  ],
                ),
              ),
            ),
            // Single green navigation button: go to ShowFoodItemsPage
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Center(
                    child: SizedBox(
                  width: 180,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      if (!context.mounted) return;
                      final auth = AuthService();
                      // Save provided personal values to central in-memory storage
                      auth.setTempPersonal({
                        'gender': displayGender,
                        'age': displayAge,
                        'weight': displayWeight,
                        'height': displayHeight,
                      });
                      // compute or fetch totalCalories if available; use placeholder '-' for now
                      final totalCalories = '-';

                      // Determine selections: prefer values passed into this page, fallback to saved user data
                      final saved = auth.user ?? {};
                      final selType = (widget.selectedType.isNotEmpty) ? widget.selectedType : (saved['selectedType']?.toString() ?? '');
                      final selCategory = (widget.selectedCategory.isNotEmpty) ? widget.selectedCategory : (saved['selectedCategory']?.toString() ?? '');
                      final selMenu = (widget.selectedMenu.isNotEmpty) ? widget.selectedMenu : (saved['selectedMenu']?.toString() ?? '');
                      final selDessert = (widget.selectedDessert.isNotEmpty) ? widget.selectedDessert : (saved['selectedDessert']?.toString() ?? '');
                      final selDrinkType = (widget.selectedDrinkType.isNotEmpty) ? widget.selectedDrinkType : (saved['selectedDrinkType']?.toString() ?? '');
                      final selDrinkMenu = (widget.selectedDrinkMenu.isNotEmpty) ? widget.selectedDrinkMenu : (saved['selectedDrinkMenu']?.toString() ?? '');

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Calculate2Page(
                                selectedType: selType,
                                selectedCategory: selCategory,
                                selectedMenu: selMenu,
                                selectedDessert: selDessert,
                                selectedDrinkType: selDrinkType,
                                selectedDrinkMenu: selDrinkMenu,
                                totalCalories: totalCalories,
                                meal: widget.meal,
                                duration: widget.duration,
                              ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
                    child: const Text('หน้าถัดไป', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // No bottom navigation bar on this read-only page
    );
  }
}
