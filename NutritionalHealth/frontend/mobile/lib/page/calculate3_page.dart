import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform, kDebugMode;
import 'show_food_items_page.dart';
import 'history_page.dart';

class Calculate3Page extends StatelessWidget {
  final String foodName;
  final String meal;
  final String duration;
  final String foodType;
  final String caloriesPerDay;
  final String status;
  final String description;
  final String? selectedCategory;
  final String? selectedMenu;
  final String? selectedDessert;
  final String? selectedDrinkType;
  final String? selectedDrinkMenu;

  const Calculate3Page({
    super.key,
    this.foodName = '',
    this.meal = '',
    this.duration = '',
    this.caloriesPerDay = '',
    this.status = '',
    this.description = '',
    this.foodType = '',
    this.selectedCategory,
    this.selectedMenu,
    this.selectedDessert,
    this.selectedDrinkType,
    this.selectedDrinkMenu,
  });

  Widget _label(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _greyBox(String text, {double height = 48}) {
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        child: Text(
          text.isNotEmpty ? text : '-',
          style: TextStyle(color: Colors.grey[800]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF00C700);

    final auth = AuthService();
    final sels = auth.tempSelections ?? auth.guestSelections ?? {};
    if (kDebugMode)
      debugPrint(
        'Calculate3Page: loaded sels=' +
            (sels.isNotEmpty ? jsonEncode(sels) : '{}'),
      );

    final displayedMeal =
        (sels['meal'] != null && sels['meal'].toString().isNotEmpty)
        ? sels['meal'].toString()
        : '-';

    final displayedDuration =
        (sels['duration'] != null && sels['duration'].toString().isNotEmpty)
        ? '${sels['duration']}'
        : '-';

    // =========================
    // 1️⃣ Intake
    // =========================
    int intake = 0;
    try {
      intake = int.parse(caloriesPerDay.replaceAll(RegExp(r'[^0-9]'), ''));
    } catch (_) {
      intake = 0;
    }

    // =========================
    // 2️⃣ Personal Data
    // =========================
    final personal = auth.tempPersonal ?? auth.guestPersonal ?? auth.user ?? {};

    final gender = personal['gender']?.toString().toLowerCase() ?? '';
    final age = int.tryParse(personal['age']?.toString() ?? '');
    final weight = double.tryParse(personal['weight']?.toString() ?? '');
    final height = double.tryParse(personal['height']?.toString() ?? '');

    // =========================
    // 3️⃣ Calculate Recommended Calories
    // =========================
    int recommendedPerDay = intake;

    if (weight != null && height != null && age != null && height > 0) {
      final isMale =
          gender.contains('male') ||
          gender.contains('m') ||
          gender.contains('ช');

      final bmr = 10 * weight + 6.25 * height - 5 * age + (isMale ? 5 : -161);

      recommendedPerDay = (bmr * 1.2).round();
    }

    // =========================
    // 4️⃣ Duration
    // =========================
    int days = 1;
    final match = RegExp(r'\d+').firstMatch(displayedDuration);
    if (match != null) {
      days = int.tryParse(match.group(0)!) ?? 1;
    }
    days = days.clamp(1, 7);

    final totalIntake = intake * days;
    final totalRecommended = recommendedPerDay * days;
    final diffPerDay = intake - recommendedPerDay;
    final diffTotal = totalIntake - totalRecommended;

    // =========================
    // 5️⃣ BMI Status
    // =========================
    String computedStatus = 'ปกติ';

    if (weight != null && height != null && height > 0) {
      final hMeter = height / 100;
      final bmi = weight / (hMeter * hMeter);

      if (bmi < 18.5) {
        computedStatus = 'ผอม';
      } else if (bmi < 25) {
        computedStatus = 'ปกติ';
      } else if (bmi < 30) {
        computedStatus = 'อวบ';
      } else {
        computedStatus = 'อ้วน';
      }
    }

    final displayedStatus = status.isNotEmpty ? status : computedStatus;

    // =========================
    // 6️⃣ Description
    // =========================
    String generatedDescription;

    if (diffPerDay > 100) {
      generatedDescription =
          'ควรได้รับ $recommendedPerDay kcal/วัน\n'
          'แต่ได้รับ $intake kcal/วัน\n\n'
          'รวม $days วัน ควรได้รับ $totalRecommended kcal\n'
          'แต่ได้รับ $totalIntake kcal\n'
          'เกิน $diffTotal kcal\n\n'
          'แนะนำเพิ่มการออกกำลังกายเพื่อลดพลังงานส่วนเกิน';
    } else if (diffPerDay < -100) {
      generatedDescription =
          'ควรได้รับ $recommendedPerDay kcal/วัน\n'
          'แต่ได้รับเพียง $intake kcal/วัน\n\n'
          'รวม $days วัน ควรได้รับ $totalRecommended kcal\n'
          'แต่ได้รับ $totalIntake kcal\n\n'
          'แนะนำเพิ่มอาหารที่มีประโยชน์เพื่อให้พลังงานเพียงพอ';
    } else {
      generatedDescription =
          'ได้รับพลังงานเหมาะสม\n\n'
          'ควรได้รับ $totalRecommended kcal\n'
          'ได้รับ $totalIntake kcal\n\n'
          'รักษาพฤติกรรมนี้ต่อไป';
    }

    // =========================
    // UI
    // =========================
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryGreen),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
        title: const Text(
          'คำนวณ',
          style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
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
                    style: const TextStyle(
                      color: primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _label('มื้ออาหาร', primaryGreen),
            _greyBox(displayedMeal),
            const SizedBox(height: 12),

            _label('ระยะเวลา', primaryGreen),
            _greyBox(displayedDuration),
            const SizedBox(height: 12),

            _label('พลังงานที่เหมาะสม/วัน', primaryGreen),
            _greyBox('$recommendedPerDay kcal'),
            const SizedBox(height: 12),

            _label('สถานะ', primaryGreen),
            _greyBox(displayedStatus),
            const SizedBox(height: 12),

            _label('คำอธิบาย', primaryGreen),
            _greyBox(generatedDescription, height: 150),
            const SizedBox(height: 20),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  // Debug: mark when user pressed the save button
                  if (kDebugMode) debugPrint('Save button pressed');
                  // Build items list from available selection fields first
                  List<String> items = [];

                  // Prefer explicit selected menu names passed from previous pages
                  if (selectedMenu != null && selectedMenu!.isNotEmpty) {
                    items.addAll(
                      selectedMenu!
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty),
                    );
                  }
                  if (selectedDessert != null && selectedDessert!.isNotEmpty) {
                    items.addAll(
                      selectedDessert!
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty),
                    );
                  }
                  if (selectedDrinkMenu != null &&
                      selectedDrinkMenu!.isNotEmpty) {
                    items.addAll(
                      selectedDrinkMenu!
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty),
                    );
                  }

                  // If no explicit selections, fall back to `foodName` (if provided)
                  if (items.isEmpty && foodName.isNotEmpty) {
                    items = foodName
                        .split('+')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList();
                  }

                  // As last resort, use the `meal` label
                  if (items.isEmpty && meal.isNotEmpty) {
                    items = [meal];
                  }

                  // Prepare payload matching backend expected flat keys
                  final auth = AuthService();
                  final personal =
                      auth.tempPersonal ??
                      auth.guestPersonal ??
                      auth.user ??
                      {};

                  final intDays =
                      (int.tryParse(
                                displayedDuration.toString().replaceAll(
                                  RegExp(r'[^0-9]'),
                                  '',
                                ),
                              ) ??
                              1)
                          .clamp(1, 365);

                  final Map<String, dynamic> payload = {
                    'personal': personal,
                    'selectedType': foodType,
                    'selectedCategory': selectedCategory ?? '',
                    'selectedMenu': selectedMenu ?? '',
                    'selectedDessert': selectedDessert ?? '',
                    'selectedDrinkType': selectedDrinkType ?? '',
                    'selectedDrinkMenu': selectedDrinkMenu ?? '',
                    'meal': displayedMeal,
                    'duration': days,
                    'intake_per_day': intake,
                    'total_intake': totalIntake,
                    'recommended_per_day': recommendedPerDay,
                    'recommended_total': totalRecommended,
                    'status': displayedStatus,
                    'description': generatedDescription,
                    // human-readable summary to store in history for quick review
                    'summary': '''มื้อ: ${displayedMeal}\nระยะเวลา: ${days} วัน\nรับ/วัน: ${intake} kcal\nควรรับ/วัน: ${recommendedPerDay} kcal\nรวมรับ: ${totalIntake} kcal\nรวมควรรับ: ${totalRecommended} kcal\nสถานะ: ${displayedStatus}\nคำอธิบาย: ${generatedDescription}\nเมนูที่เลือก: ${items.join(', ')}''',
                  };

                  // Save: if logged in, send flat payload to backend; if guest -> do NOT call backend, show warning
                  bool saved = false;
                  try {
                    if (kDebugMode) debugPrint('Calling saveSelection with payload: ${jsonEncode(payload)}');
                    if (auth.isLoggedIn) {
                      saved = await auth.saveSelection(payload);
                      if (kDebugMode) debugPrint('saveSelection returned: $saved');
                    } else if (auth.isGuest) {
                      // Persist guest selections locally only
                      if (kDebugMode) debugPrint('Saving guest selections (in-memory)');
                      await auth.saveGuestSelections(payload);
                      if (kDebugMode) debugPrint('saveGuestSelections done');
                      // For Guest: do NOT mark as saved success for DB and do NOT call backend.
                      saved = false;
                    }
                  } catch (e, st) {
                    if (kDebugMode) {
                      debugPrint('saveSelection error: $e');
                      debugPrint('$st');
                    }
                    saved = false;
                  }

                  if (kDebugMode) debugPrint('Save result: $saved (true == persisted to DB)');

                  if (saved) {
                    // Inform the user and navigate to History so they can verify
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('บันทึกสำเร็จ — ไปที่ประวัติ')));
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HistoryPage()),
                      );
                    }
                  } else {
                    // For guests and failed saves: show warning for guests, otherwise generic failure
                    if (context.mounted) {
                      if (auth.isGuest) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ผู้ใช้ Guest ไม่สามารถบันทึกข้อมูลได้')));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('บันทึกไม่สำเร็จ — แสดงผลอย่างเดียว')));
                      }
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ShowFoodItemsPage(
                            items: items,
                            calories: totalIntake.toString(),
                          ),
                        ),
                      );
                    }
                  }
                },
                child: const Text(
                  'คำนวณ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
