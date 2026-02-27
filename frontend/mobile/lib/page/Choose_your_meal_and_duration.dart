import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'calculate1_page.dart';

class ChooseYourMealAndDurationPage extends StatefulWidget {
  final String selectedType;
  final String selectedCategory;
  final String selectedMenu;
  final String selectedDessert;
  final String selectedDrinkType;
  final String selectedDrinkMenu;

  const ChooseYourMealAndDurationPage({
    Key? key,
    required this.selectedType,
    required this.selectedCategory,
    required this.selectedMenu,
    required this.selectedDessert,
    required this.selectedDrinkType,
    required this.selectedDrinkMenu,
  }) : super(key: key);

  @override
  State<ChooseYourMealAndDurationPage> createState() =>
      _ChooseYourMealAndDurationPageState();
}

class _ChooseYourMealAndDurationPageState
    extends State<ChooseYourMealAndDurationPage> {
  final Color primaryGreen = const Color(0xFF00C700);

  late final AuthService _auth;

  bool _saving = false;
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
  }

  Future<void> _saveAndCalculate() async {
    if (_saving) return;

    if (selectedMeal == null || selectedDuration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกมื้ออาหารและระยะเวลา')),
      );
      return;
    }

   

    setState(() => _saving = true);

    try {
      final data = {
        "selectedType": widget.selectedType,
        "selectedCategory": widget.selectedCategory,
        "selectedMenu": widget.selectedMenu,
        "selectedDessert": widget.selectedDessert,
        "selectedDrinkType": widget.selectedDrinkType,
        "selectedDrinkMenu": widget.selectedDrinkMenu,
        "meal": selectedMeal!,
        "duration": selectedDuration!,
      };

      /// 🔥 เรียก saveSelection
      final result = await _auth.saveSelection(data);

      /// รองรับทั้งกรณี return bool และ void
      final success = result is bool ? result : true;

      if (!mounted) return;

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกข้อมูลไม่สำเร็จ')),
        );
        setState(() => _saving = false);
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CalculatePage(
            selectedType: widget.selectedType,
            selectedCategory: widget.selectedCategory,
            selectedMenu: widget.selectedMenu,
            selectedDessert: widget.selectedDessert,
            selectedDrinkType: widget.selectedDrinkType,
            selectedDrinkMenu: widget.selectedDrinkMenu,
            meal: selectedMeal!,
            duration: selectedDuration!,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึก')),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String idText = '';

    if (_auth.isLoggedIn && _auth.user != null) {
      idText = _auth.user!['username'] ??
          _auth.user!['name'] ??
          _auth.user!['id']?.toString() ??
          '';
    } else if (_auth.isGuest) {
      idText = 'Guest';
    }

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
              fontWeight: FontWeight.w700),
        ),
        actions: [
          if (idText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Center(
                child: Text(
                  idText,
                  style: TextStyle(color: primaryGreen),
                ),
              ),
            )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),

            /// มื้ออาหาร
            Text(
              'มื้ออาหาร',
              style: TextStyle(
                  color: primaryGreen, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: selectedMeal,
              items: mealOptions
                  .map((meal) =>
                      DropdownMenuItem(value: meal, child: Text(meal)))
                  .toList(),
              onChanged: (value) =>
                  setState(() => selectedMeal = value),
              decoration: _inputDecoration('เลือกมื้ออาหาร'),
            ),

            const SizedBox(height: 20),

            /// ระยะเวลา
            Text(
              'ระยะเวลา',
              style: TextStyle(
                  color: primaryGreen, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              isExpanded: true,
              value: selectedDuration,
              items: List.generate(
                7,
                (index) => DropdownMenuItem(
                  value: index + 1,
                  child: Text('${index + 1} วัน'),
                ),
              ),
              onChanged: (value) =>
                  setState(() => selectedDuration = value),
              decoration: _inputDecoration('เลือกระยะเวลา'),
            ),

            const Spacer(),

            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveAndCalculate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'บันทึกและคำนวณ',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
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
}
