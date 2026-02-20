import 'package:flutter/material.dart';
import 'choose_your_meal_and_duration.dart';
import 'dart:convert';
import '../services/csv_loader.dart';
import '../services/api_client.dart';
import '../services/app_config.dart';
import '../services/auth_service.dart';

class ChooseFoodTypePage extends StatefulWidget {
  const ChooseFoodTypePage({super.key});

  @override
  State<ChooseFoodTypePage> createState() => _ChooseFoodTypePageState();
}

class _ChooseFoodTypePageState extends State<ChooseFoodTypePage> {
  final Color primaryGreen = const Color(0xFF00C700);

  final List<String> _types = [
    'เมนูโปรตีน',
    'เมนูผักและผลไม้',
    'เมนูคาร์โบไฮเดรต'
  ];

  final Map<String, List<String>> _categories = {
    'เมนูโปรตีน': ['อาหารครบ 5 หมู่', 'อาหารลดน้ำหนัก', 'อาหารสร้างกล้ามเนื้อ'],
    'เมนูผักและผลไม้': ['อาหารครบ 5 หมู่', 'อาหารลดน้ำหนัก', 'อาหารบำรุงสุขภาพ'],
    'เมนูคาร์โบไฮเดรต': ['อาหารครบ 5 หมู่', 'อาหารลดน้ำหนัก', 'อาหารให้พลังงานสูง'],
  };

  final List<String> _drinkTypes = [
    'เครื่องดื่มเพื่อสุขภาพ',
    'เครื่องดื่มลดน้ำหนัก',
    'เครื่องดื่มเพิ่มพลังงาน'
  ];

  String? selectedType;
  String? selectedCategory;
  String? selectedMenu;
  String? selectedDrinkType;
  String? selectedDrinkMenu;
  String? selectedDessert;

  List<String> menuOptions = [];
  List<String> drinkMenuOptions = [];
  List<String> dessertOptions = [];
  late final AuthService _auth;
  bool _authLoaded = false;

  @override
  void initState() {
    super.initState();
    _auth = AuthService();
    Future.microtask(() async {
      try {
        await _auth.loadToken();
      } catch (_) {}
      if (mounted) setState(() => _authLoaded = true);
    });
  }

  void _generateMenus() async {
    if (selectedType == null) return;

    List<String> menus = [];

    try {
      // Prefer backend filtered lists; fall back to local CSV loader on failure
      final api = ApiClient(getApiBase());
      if (selectedType == 'เมนูโปรตีน') {
        final cat = selectedCategory ?? '';
        final resp = await api.get('/menus?category=${Uri.encodeComponent(cat)}');
        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          final j = jsonDecode(resp.body);
          menus = List<String>.from(j['items'] ?? []);
        } else {
          menus = await CsvLoader.loadProteinMenus();
        }
      } else if (selectedType == 'เมนูผักและผลไม้') {
        final cat = selectedCategory ?? '';
        final resp = await api.get('/menus?category=${Uri.encodeComponent(cat)}');
        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          final j = jsonDecode(resp.body);
          menus = List<String>.from(j['items'] ?? []);
        } else {
          menus = await CsvLoader.loadVegetableMenus();
        }
      } else if (selectedType == 'เมนูคาร์โบไฮเดรต') {
        final cat = selectedCategory ?? '';
        final resp = await api.get('/menus?category=${Uri.encodeComponent(cat)}');
        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          final j = jsonDecode(resp.body);
          menus = List<String>.from(j['items'] ?? []);
        } else {
          menus = await CsvLoader.loadCarbMenus();
        }
        // desserts
        try {
          final dresp = await api.get('/desserts');
          if (dresp.statusCode >= 200 && dresp.statusCode < 300) {
            final dj = jsonDecode(dresp.body);
            dessertOptions = List<String>.from(dj['items'] ?? []);
          } else {
            dessertOptions = await CsvLoader.loadDessertMenus();
          }
        } catch (_) {
          dessertOptions = await CsvLoader.loadDessertMenus();
        }
      }

      setState(() {
        menuOptions = menus;
      });
    } catch (_) {
      setState(() => menuOptions = []);
    }
  }

  void _generateDrinkMenus() async {
    if (selectedDrinkType == null) return;

    List<String> drinks = [];
    try {
      final api = ApiClient(getApiBase());
      if (selectedDrinkType == 'เครื่องดื่มเพื่อสุขภาพ') {
        // Healthy drinks intentionally come from the smoothie CSV only
        drinks = await CsvLoader.loadHealthyDrinks();
      } else {
        // For other drink types prefer backend filtered lists
        final resp = await api.get('/drink-menus?type=${Uri.encodeComponent(selectedDrinkType!)}');
        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          final j = jsonDecode(resp.body);
          drinks = List<String>.from(j['items'] ?? []);
        } else {
          // fallback to CSV-based loaders
          if (selectedDrinkType == 'เครื่องดื่มลดน้ำหนัก') {
            drinks = await CsvLoader.loadWeightLossDrinks();
          } else if (selectedDrinkType == 'เครื่องดื่มเพิ่มพลังงาน') {
            drinks = await CsvLoader.loadEnergyDrinks();
          }
        }
      }

      setState(() => drinkMenuOptions = drinks);
    } catch (_) {
      setState(() => drinkMenuOptions = []);
    }
  }

  bool get isFormComplete {
    final base = selectedType != null &&
        selectedCategory != null &&
        selectedMenu != null &&
        selectedDrinkType != null &&
        selectedDrinkMenu != null;
    if (selectedType == 'เมนูคาร์โบไฮเดรต') {
      return base && selectedDessert != null;
    }
    return base;
  }

  Widget _dropdown(
      String hint, String? value, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: value,
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis)))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.grey[200],
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // compute user display text
    String idText = '';
    if (_authLoaded) {
      if (_auth.isLoggedIn && _auth.user != null) {
        idText = _auth.user!['username'] ?? _auth.user!['name'] ?? _auth.user!['id']?.toString() ?? '';
      } else if (_auth.isGuest) {
        idText = 'Guest';
      }
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: primaryGreen),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'เลือกประเภทอาหาร',
          style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Center(
              child: Text(idText.isNotEmpty ? idText : '', style: TextStyle(color: primaryGreen)),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('เลือกประเภทอาหาร', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _dropdown('ประเภทอาหาร', selectedType, _types, (v) {
                setState(() {
                  selectedType = v;
                  selectedCategory = null;
                  selectedMenu = null;
                  menuOptions = [];
                  dessertOptions = [];
                  selectedDessert = null;
                });
              }),

              const SizedBox(height: 14),
              if (selectedType != null) ...[
                Text('ค้นหาเมนูอาหารตามหมวดหมู่', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _dropdown('หมวดหมู่', selectedCategory, _categories[selectedType] ?? [], (v) {
                  setState(() {
                    selectedCategory = v;
                    selectedMenu = null;
                  });
                  _generateMenus();
                }),
              ],

              const SizedBox(height: 14),
              if (menuOptions.isNotEmpty) ...[
                Text('เมนูอาหาร (${menuOptions.length} รายการ)', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _dropdown('เมนูอาหาร', selectedMenu, menuOptions, (v) => setState(() => selectedMenu = v)),
              ],

              const SizedBox(height: 14),
              if (selectedType == 'เมนูคาร์โบไฮเดรต') ...[
                Text('เมนูของหวาน', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _dropdown('เมนูของหวาน', selectedDessert, dessertOptions, (v) => setState(() => selectedDessert = v)),
              ],

              const SizedBox(height: 14),
              Text('เลือกประเภทเมนูเครื่องดื่ม', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _dropdown('ประเภทเครื่องดื่ม', selectedDrinkType, _drinkTypes, (v) {
                setState(() {
                  selectedDrinkType = v;
                  selectedDrinkMenu = null;
                });
                _generateDrinkMenus();
              }),

              const SizedBox(height: 14),
              if (drinkMenuOptions.isNotEmpty) ...[
                Text('เมนูเครื่องดื่ม', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _dropdown('เมนูเครื่องดื่ม', selectedDrinkMenu, drinkMenuOptions, (v) => setState(() => selectedDrinkMenu = v)),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isFormComplete
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChooseYourMealAndDurationPage(
                                selectedType: selectedType!,
                                selectedCategory: selectedCategory!,
                                selectedMenu: selectedMenu!,
                                selectedDessert: selectedDessert ?? '',
                                selectedDrinkType: selectedDrinkType!,
                                selectedDrinkMenu: selectedDrinkMenu!,
                              ),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('หน้าถัดไป', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 26),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(onPressed: () {}, icon: Icon(Icons.home, color: primaryGreen)),
              IconButton(onPressed: () {}, icon: Icon(Icons.search, color: primaryGreen)),
              IconButton(onPressed: () {}, icon: Icon(Icons.menu_book, color: primaryGreen)),
            ],
          ),
        ),
      ),
    );
  }
}
