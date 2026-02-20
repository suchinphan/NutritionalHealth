import 'package:flutter/material.dart';
import 'calculate3_page.dart';
// AuthService import removed: do not use temporary global selections here

class Calculate2Page extends StatelessWidget {
  final String selectedType;
  final String selectedCategory;
  final String selectedMenu;
  final String selectedDessert;
  final String selectedDrinkType;
  final String selectedDrinkMenu;
  final String totalCalories;
  final String meal;
  final int duration;

  const Calculate2Page({
    super.key,
    this.selectedType = '',
    this.selectedCategory = '',
    this.selectedMenu = '',
    this.selectedDessert = '',
    this.selectedDrinkType = '',
    this.selectedDrinkMenu = '',
    this.totalCalories = '-',
    required this.meal,
    required this.duration,
  });

  Widget _label(String text, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 6.0),
        child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      );

  Widget _greyBox(String text) {
    return Container(
      height: 48,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
      alignment: Alignment.centerLeft,
      child: Text(text.isNotEmpty ? text : '-', style: TextStyle(color: Colors.grey[800])),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF00C700);

    final List<String> items = [];
    if (selectedMenu.isNotEmpty) items.add(selectedMenu);
    if (selectedDessert.isNotEmpty) items.add(selectedDessert);
    if (selectedDrinkMenu.isNotEmpty) items.add(selectedDrinkMenu);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(onTap: () => Navigator.of(context).maybePop(), child: const Icon(Icons.arrow_back, color: primaryGreen)),
        centerTitle: true,
        title: const Text('คำนวณ', style: TextStyle(color: primaryGreen, fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Text('ข้อมูลที่ได้รับ', style: TextStyle(color: primaryGreen, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),

            _label('ประเภทอาหารที่เลือก', primaryGreen),
            _greyBox(selectedType),
            const SizedBox(height: 12),

            _label('ค้นหาเมนูอาหารตามหมวดหมู่', primaryGreen),
            _greyBox(selectedCategory),
            const SizedBox(height: 12),

            _label('เมนูอาหาร', primaryGreen),
            _greyBox(selectedMenu),
            const SizedBox(height: 12),

            _label('เมนูของหวาน', primaryGreen),
            _greyBox(selectedDessert),
            const SizedBox(height: 12),

            _label('เลือกประเภทเมนูเครื่องดื่ม', primaryGreen),
            _greyBox(selectedDrinkType),
            const SizedBox(height: 12),

            _label('เมนูเครื่องดื่ม', primaryGreen),
            _greyBox(selectedDrinkMenu),

            const SizedBox(height: 20),

            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Calculate3Page(
                        meal: meal,
                        foodName: [
                          selectedMenu,
                          selectedDessert,
                          selectedDrinkMenu,
                        ].where((e) => e.isNotEmpty).join(' + '),

                        duration: duration.toString(),
                        foodType: selectedType,

                        caloriesPerDay: totalCalories,

                        description: 'ประเภท: $selectedType\nหมวดหมู่: $selectedCategory',
                        selectedCategory: selectedCategory,
                        selectedMenu: selectedMenu,
                        selectedDessert: selectedDessert,
                        selectedDrinkType: selectedDrinkType,
                        selectedDrinkMenu: selectedDrinkMenu,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
                child: const Text('หน้าถัดไป', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
