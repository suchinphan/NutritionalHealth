import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import 'calculate3_page.dart';

class Calculate2Page extends StatefulWidget {
  const Calculate2Page({super.key});

  static const primaryGreen = Color(0xFF00C700);

  @override
  State<Calculate2Page> createState() => _Calculate2PageState();
}

class _Calculate2PageState extends State<Calculate2Page> {
  String selectedType = '';
  String selectedCategory = '';
  String selectedMenu = '';
  String selectedDessert = '';
  String selectedDrinkType = '';
  String selectedDrinkMenu = '';

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSelectionNames();
  }

  Future<void> _loadSelectionNames() async {
    final auth = AuthService();
    final sels = auth.tempSelections ?? {};

    // default API base used elsewhere in the app
    final api = ApiClient('http://127.0.0.1:5000');

    try {
      // Food type
      final ftId = sels['food_type_id'];
      if (ftId != null) {
        final r = await api.get('/api/food-types');
        if (r.statusCode == 200) {
          try {
            final List decoded = (r.body.isNotEmpty)
                ? (jsonDecode(r.body) as List)
                : [];
            final found = decoded.cast<Map<String, dynamic>>().firstWhere(
              (e) => (e['id']?.toString() ?? '') == ftId.toString(),
              orElse: () => {},
            );
            selectedType = (found['name']?.toString() ?? '');
          } catch (_) {}
        }
      }

      // Category
      final catId = sels['category_id'];
      if (catId != null && ftId != null) {
        final r = await api.get('/api/food-categories?food_type_id=$ftId');
        if (r.statusCode == 200) {
          try {
            final List decoded = (r.body.isNotEmpty)
                ? (jsonDecode(r.body) as List)
                : [];
            final found = decoded.cast<Map<String, dynamic>>().firstWhere(
              (e) => (e['id']?.toString() ?? '') == catId.toString(),
              orElse: () => {},
            );
            selectedCategory = (found['name']?.toString() ?? '');
          } catch (_) {}
        }
      }

      // Food menu
      final menuId = sels['food_menu_id'];
      if (menuId != null && catId != null) {
        final r = await api.get('/api/food-menus-simple?category_id=$catId');
        if (r.statusCode == 200) {
          try {
            final List decoded = (r.body.isNotEmpty)
                ? (jsonDecode(r.body) as List)
                : [];
            final found = decoded.cast<Map<String, dynamic>>().firstWhere(
              (e) => (e['id']?.toString() ?? '') == menuId.toString(),
              orElse: () => {},
            );
            selectedMenu = (found['name']?.toString() ?? '');
          } catch (_) {}
        }
      }

      // Desserts
      final dId = sels['dessert_id'];
      if (dId != null) {
        final r = await api.get('/api/dessert-menus?food_type_id=${ftId ?? 3}');
        if (r.statusCode == 200) {
          try {
            final List decoded = (r.body.isNotEmpty)
                ? (jsonDecode(r.body) as List)
                : [];
            final found = decoded.cast<Map<String, dynamic>>().firstWhere(
              (e) => (e['id']?.toString() ?? '') == dId.toString(),
              orElse: () => {},
            );
            selectedDessert = (found['name']?.toString() ?? '');
          } catch (_) {}
        }
      }

      // Drink type
      final dtId = sels['drink_type_id'];
      if (dtId != null) {
        final r = await api.get('/api/drink-types');
        if (r.statusCode == 200) {
          try {
            final List decoded = (r.body.isNotEmpty)
                ? (jsonDecode(r.body) as List)
                : [];
            final found = decoded.cast<Map<String, dynamic>>().firstWhere(
              (e) => (e['id']?.toString() ?? '') == dtId.toString(),
              orElse: () => {},
            );
            selectedDrinkType = (found['name']?.toString() ?? '');
          } catch (_) {}
        }
      }

      // Drink menu
      final dmId = sels['drink_menu_id'];
      if (dmId != null && dtId != null) {
        final r = await api.get('/api/drink-menus?drink_type_id=$dtId');
        if (r.statusCode == 200) {
          try {
            final List decoded = (r.body.isNotEmpty)
                ? (jsonDecode(r.body) as List)
                : [];
            final found = decoded.cast<Map<String, dynamic>>().firstWhere(
              (e) => (e['id']?.toString() ?? '') == dmId.toString(),
              orElse: () => {},
            );
            selectedDrinkMenu = (found['name']?.toString() ?? '');
          } catch (_) {}
        }
      }
    } catch (e) {
      // ignore errors and show what we have
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      // fallback to '-' if empty
      selectedType = selectedType.isNotEmpty ? selectedType : '-';
      selectedCategory = selectedCategory.isNotEmpty ? selectedCategory : '-';
      selectedMenu = selectedMenu.isNotEmpty ? selectedMenu : '-';
      selectedDessert = selectedDessert.isNotEmpty ? selectedDessert : '-';
      selectedDrinkType = selectedDrinkType.isNotEmpty
          ? selectedDrinkType
          : '-';
      selectedDrinkMenu = selectedDrinkMenu.isNotEmpty
          ? selectedDrinkMenu
          : '-';
    });
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
        color: Calculate2Page.primaryGreen,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _greyBox(String text) {
    return Container(
      height: 48,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        text.isNotEmpty ? text : '-',
        style: TextStyle(color: Colors.grey[800]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final displayName = auth.isGuest
        ? 'Guest'
        : (auth.user?['username'] ??
              auth.user?['name'] ??
              (auth.user?['email'] != null
                  ? auth.user!['email'].toString().split('@').first
                  : '') ??
              '');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          child: const Icon(
            Icons.arrow_back,
            color: Calculate2Page.primaryGreen,
          ),
        ),
        centerTitle: true,
        title: const Text(
          'คำนวณ',
          style: TextStyle(
            color: Calculate2Page.primaryGreen,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                displayName,
                style: const TextStyle(
                  color: Calculate2Page.primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'ข้อมูลที่ได้รับ',
                    style: TextStyle(
                      color: Calculate2Page.primaryGreen,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _label('ประเภทอาหารที่เลือก'),
                  _greyBox(selectedType),
                  const SizedBox(height: 12),

                  _label('ค้นหาเมนูอาหารตามหมวดหมู่'),
                  _greyBox(selectedCategory),
                  const SizedBox(height: 12),

                  _label('เมนูอาหาร'),
                  _greyBox(selectedMenu),
                  const SizedBox(height: 12),

                  _label('เมนูของหวาน'),
                  _greyBox(selectedDessert),
                  const SizedBox(height: 12),

                  _label('เลือกประเภทเมนูเครื่องดื่ม'),
                  _greyBox(selectedDrinkType),
                  const SizedBox(height: 12),

                  _label('เมนูเครื่องดื่ม'),
                  _greyBox(selectedDrinkMenu),
                  const SizedBox(height: 12),

                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Calculate3Page(
                              foodType: selectedType,
                              selectedCategory: selectedCategory,
                              selectedMenu: selectedMenu,
                              selectedDessert: selectedDessert,
                              selectedDrinkType: selectedDrinkType,
                              selectedDrinkMenu: selectedDrinkMenu,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Calculate2Page.primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'หน้าถัดไป',
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
