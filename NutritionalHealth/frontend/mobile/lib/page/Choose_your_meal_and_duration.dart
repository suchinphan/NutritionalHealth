import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
// Use persistent guest lock from AuthService (match Personal page behavior)
import 'calculate1_page.dart';
import 'choose_food_type_page.dart';

class ChooseYourMealAndDurationPage extends StatefulWidget {
  final int foodTypeId;
  final int categoryId;
  final int foodMenuId;
  final int? dessertId;
  final int drinkTypeId;
  final int drinkMenuId;

  const ChooseYourMealAndDurationPage({
    super.key,
    required this.foodTypeId,
    required this.categoryId,
    required this.foodMenuId,
    required this.drinkTypeId,
    required this.drinkMenuId,
    this.dessertId,
  });

  @override
  State<ChooseYourMealAndDurationPage> createState() =>
      _ChooseYourMealAndDurationPageState();
}

class _ChooseYourMealAndDurationPageState
    extends State<ChooseYourMealAndDurationPage> {
  final Color primaryGreen = const Color(0xFF00C700);
  late final AuthService _auth;

  bool _authLoaded = false;
  bool _saving = false;
  // Guest lock is controlled by AuthService (persistent, like Personal page)
  String? selectedMeal;
  int? selectedDuration;

  final List<String> mealOptions = [
    'เช้า + กลางวัน + เย็น',
    'เช้า + กลางวัน',
    'เช้า + เย็น',
    'กลางวัน + เย็น',
    'เช้า',
    'กลางวัน',
    'เย็น',
  ];

  @override
  void initState() {
    super.initState();
    _auth = AuthService();
    // Refresh UI when auth state (guestUsed/selectionLocked) changes
    _auth.addListener(_authListener);
    // Load persisted auth/guest/temp selections so saved meal/duration appear
    Future.microtask(() async {
      try {
        await _auth.loadToken();
      } catch (_) {}
      final sels = _auth.tempSelections ?? _auth.guestSelections ?? {};
      final m = sels['meal'];
      final d = sels['duration'];
      if (mounted) {
        setState(() {
          if (m != null) selectedMeal = m.toString();
          if (d != null)
            selectedDuration = d is int ? d : int.tryParse(d.toString() ?? '');
          _authLoaded = true;
        });
      }
    });
  }

  void _authListener() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    // Intentionally left empty. Initialization and loading are handled in initState()
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    try {
      _auth.removeListener(_authListener);
    } catch (_) {}
    super.dispose();
  }

  Future<void> _saveAndCalculate() async {
    if (_saving) return;

    final personal =
        _auth.user ?? _auth.tempPersonal ?? _auth.guestPersonal ?? {};

    final hasPersonal =
        (personal['gender'] != null &&
            personal['age'] != null &&
            personal['weight'] != null &&
            personal['height'] != null) ||
        _auth.tempPersonal != null;

    if (!hasPersonal || selectedMeal == null || selectedDuration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบก่อน')),
      );
      return;
    }

    setState(() => _saving = true);

    // ✅ เก็บ meal + duration ไว้ใน AuthService แทน
    final sels = {
      'food_type_id': widget.foodTypeId,
      'category_id': widget.categoryId,
      'food_menu_id': widget.foodMenuId,
      'dessert_id': widget.dessertId,
      'drink_type_id': widget.drinkTypeId,
      'drink_menu_id': widget.drinkMenuId,
      'meal': selectedMeal,
      'duration': selectedDuration,
    };

    // Merge with any existing temp selections so human-readable names
    // previously stored (from the ChooseFoodType page) are preserved.
    final Map<String, dynamic> merged = {};
    if (_auth.tempSelections != null) merged.addAll(_auth.tempSelections!);
    merged.addAll(sels);
    _auth.setTempSelections(merged);
    // Do NOT set any session-only lock here. We persist selections below
    // and the persistent guest lock (`markGuestUsed`) is invoked only
    // after a successful submission (see save flow below).
    setState(() {});

    // If guest or user, persist personal info and save selections.
    // The persistent guest lock (`markGuestUsed`) should be invoked only
    // by the final submission step (mirroring Personal page). We do NOT
    // use session-only locks.
    if (_auth.isGuest || _auth.user != null) {
      try {
        final mergedUser = _auth.user != null
            ? Map<String, dynamic>.from(_auth.user!)
            : null;
        final mergedGuest = _auth.tempPersonal ?? _auth.guestPersonal;
        if (mergedUser != null) {
          await _auth.saveUser(mergedUser);
        } else if (mergedGuest != null) {
          await _auth.saveGuestPersonal(mergedGuest);
        }
      } catch (e) {
        if (kDebugMode) print('Background save error: $e');
      }

      try {
        // Save selections for guest/user. After a successful save we
        // persist the one-time guest lock (markGuestUsed) so inputs become
        // permanently read-only going forward — this mirrors Personal.
        await _auth.saveGuestSelections(merged);
        try {
          await _auth.markGuestUsed();
        } catch (_) {}
      } catch (_) {}
    }

    if (!mounted) return;

    // ✅ เรียก CalculatePage แบบไม่ส่ง parameter
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const CalculatePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ensure auth/temp selections have loaded before rendering UI.
    if (!_authLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    // Determine whether this page should be editable.
    // - logged-in users: always editable
    // - guests: editable if selections aren't locked AND either they haven't
    //   used their one-time submission, or they used it but there is no
    //   saved meal/duration yet (so allow completing the flow).
    final Map<String, dynamic> _persisted =
        _auth.tempSelections ?? _auth.guestSelections ?? {};
    final bool _hasMealDuration =
        _persisted['meal'] != null && _persisted['duration'] != null;
    // We always allow editing on this page; finalization occurs when the
    // user submits (saved selections + markGuestUsed()). Preloaded values
    // are used to populate dropdowns but do not control editability.

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
          'เลือกมื้ออาหารและระยะเวลา',
          style: TextStyle(
            color: primaryGreen,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Builder(
                builder: (ctx) {
                  final auth = _auth;
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
                      fontSize: 14,
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
            const SizedBox(height: 12),

            // Summary of previously saved values (always visible)
            if ((_persisted['meal'] != null) ||
                (_persisted['duration'] != null))
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ข้อมูลที่เคยกรอก',
                      style: TextStyle(
                        color: primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'มื้ออาหาร: ${selectedMeal ?? (_persisted['meal']?.toString() ?? '-')}',
                    ),
                    Text(
                      'ระยะเวลา: ${selectedDuration != null ? '${selectedDuration.toString()} วัน' : (_persisted['duration'] != null ? '${_persisted['duration'].toString()} วัน' : '-')}',
                    ),
                  ],
                ),
              ),

            // Editable meal dropdown (always editable on this page)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'มื้ออาหาร',
                  style: TextStyle(
                    color: primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedMeal,
                  isExpanded: true,
                  items: mealOptions
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) => setState(() => selectedMeal = v),
                  decoration: _inputDecoration('เลือกมื้ออาหาร'),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Editable duration dropdown (always editable on this page)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  'ระยะเวลา',
                  style: TextStyle(
                    color: primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: selectedDuration,
                  isExpanded: true,
                  items: List.generate(
                    7,
                    (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text('${i + 1} วัน'),
                    ),
                  ),
                  onChanged: (v) => setState(() => selectedDuration = v),
                  decoration: _inputDecoration('เลือกระยะเวลา'),
                ),
              ],
            ),

            const Spacer(),
            SizedBox(
              height: 52,
              child: Builder(
                builder: (context) {
                  final sels =
                      _auth.tempSelections ?? _auth.guestSelections ?? {};
                  final bool hasMeal =
                      sels['meal'] != null &&
                      sels['meal'].toString().isNotEmpty;
                  final bool hasDuration =
                      sels['duration'] != null &&
                      sels['duration'].toString().isNotEmpty;
                  final bool persistedHasMealDuration =
                      _hasMealDuration || (hasMeal && hasDuration);
                  final bool buttonEnabled =
                      !_saving && (_canProceed() || persistedHasMealDuration);

                  return ElevatedButton(
                    onPressed: buttonEnabled
                        ? () async {
                            // If persisted selections already include meal+duration,
                            // navigate straight to Calculate (skip re-saving here).
                            if (persistedHasMealDuration && !_canProceed()) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CalculatePage(),
                                ),
                              );
                              return;
                            }
                            // Otherwise perform the normal save-and-calculate flow
                            await _saveAndCalculate();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _saving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'คำนวณ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canProceed() {
    final personal =
        _auth.user ?? _auth.tempPersonal ?? _auth.guestPersonal ?? {};
    final hasPersonal =
        (personal['gender'] != null &&
            personal['age'] != null &&
            personal['weight'] != null &&
            personal['height'] != null) ||
        _auth.tempPersonal != null;
    // Also allow proceeding if persisted selections already include meal+duration
    final sels = _auth.tempSelections ?? _auth.guestSelections ?? {};
    final bool persistedHasMeal =
        sels['meal'] != null && sels['meal'].toString().isNotEmpty;
    final bool persistedHasDuration =
        sels['duration'] != null && sels['duration'].toString().isNotEmpty;

    final bool localHas = selectedMeal != null && selectedDuration != null;

    return hasPersonal &&
        (localHas || (persistedHasMeal && persistedHasDuration));
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[200],
      border: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  void _goNextViewOnly() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'ไม่สามารถแก้ไขข้อมูลได้อีก',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 1),
      ),
    );
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted)
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ChooseFoodTypePage()),
        );
    });
  }
}
