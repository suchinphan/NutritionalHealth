import 'package:flutter/material.dart';
// removed import of main.dart to avoid circular import
import '../services/api_loader.dart';
import '../services/auth_service.dart';

class MenuFoodPage extends StatefulWidget {
  const MenuFoodPage({super.key});

  @override
  State<MenuFoodPage> createState() => _MenuFoodPageState();
}

class _MenuFoodPageState extends State<MenuFoodPage> {
  final Color primaryGreen = const Color(0xFF00C700);
  // รายการตัวเลือกสำหรับ dropdown (will try to load from CSV)
  List<String> _types = [
    'โปรตีน',
    'ผักและผลไม้',
    'คาร์โบไฮเดรต',
    'เครื่องดื่ม',
  ];
  final List<String> _energies = ['ต่ำ', 'ปานกลาง', 'สูง'];
  // energy ranges (guideline): ต่ำ <200 kcal, ปานกลาง 200-500 kcal, สูง >500 kcal

  // app-level categories used to filter types/menus
  final List<String> _appCategories = [
    'เครื่องดื่มเพื่อสุขภาพ',
    'เครื่องดื่มลดน้ำหนัก',
    'เครื่องดื่มบำรุงร่างกาย / เพิ่มพลังงาน',
  ];
  String? _selectedAppCategory;

  // hierarchy built from CSVs: appCategory -> typeKey -> subCategoryKey -> set(items)
  final Map<String, Map<String, Map<String, Set<String>>>> _hierarchy = {};

  // example items (one per main food category) loaded from CSV
  final Map<String, String> _examples = {
    'โปรตีน': '',
    'ผักและผลไม้': '',
    'คาร์โบไฮเดรต': '',
    'เครื่องดื่ม': '',
  };

  @override
  void initState() {
    super.initState();
    _loadCsvOptions();
  }

  Future<void> _loadCsvOptions() async {
    try {
      final protein = await ApiLoader.loadProteinMenus();
      final veg = await ApiLoader.loadVegetableMenus();
      final carb = await ApiLoader.loadCarbMenus();
      final desserts = await ApiLoader.loadDessertMenus();
      final healthy = await ApiLoader.loadHealthyDrinks();
      final weightloss = await ApiLoader.loadWeightLossDrinks();
      final energy = await ApiLoader.loadEnergyDrinks();
      final Map<String, Map<String, Map<String, Set<String>>>> h = {};
      h['เมนูหลัก'] = {
        'เมนูโปรตีน': protein,
        'เมนูผักและผลไม้': veg,
        'เมนูคาร์โบไฮเดรต': carb,
      };
      h['ของหวาน'] = {
        'ของหวาน': {'รายการของหวาน': desserts.toSet()},
      };
      h['เครื่องดื่ม'] = {
        'เครื่องดื่มเพื่อสุขภาพ': {'รายการ': healthy.toSet()},
        'เครื่องดื่มลดน้ำหนัก': {'รายการ': weightloss.toSet()},
        'เครื่องดื่มเพิ่มพลังงาน': {'รายการ': energy.toSet()},
      };

      String _pickExample(Map<String, Set<String>>? m) {
        if (m == null) return '';
        for (var s in m.values) {
          if (s.isNotEmpty) return s.first;
        }
        return '';
      }

      setState(() {
        _hierarchy.clear();
        _hierarchy.addAll(h);
        final allTypes = <String>{};
        for (var m in _hierarchy.values) {
          allTypes.addAll(m.keys);
        }
        if (allTypes.isNotEmpty) _types = allTypes.take(12).toList();
        _examples['โปรตีน'] = _pickExample(h['เมนูหลัก']?['เมนูโปรตีน']);
        _examples['ผักและผลไม้'] = _pickExample(
          h['เมนูหลัก']?['เมนูผักและผลไม้'],
        );
        _examples['คาร์โบไฮเดรต'] = _pickExample(
          h['เมนูหลัก']?['เมนูคาร์โบไฮเดรต'],
        );
        _examples['เครื่องดื่ม'] =
            _pickExample(h['เครื่องดื่ม']?['เครื่องดื่มเพื่อสุขภาพ']) != ''
            ? _pickExample(h['เครื่องดื่ม']?['เครื่องดื่มเพื่อสุขภาพ'])
            : (_pickExample(h['เครื่องดื่ม']?['เครื่องดื่มเพิ่มพลังงาน']) != ''
                  ? _pickExample(h['เครื่องดื่ม']?['เครื่องดื่มเพิ่มพลังงาน'])
                  : '');
      });
    } catch (_) {
      // keep defaults on failure
    }
  }

  String? _selectedType;
  String? _selectedEnergy;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    // ปล่อยเฉพาะ controller ที่ใช้จริง
    _searchController.dispose();
    super.dispose();
  }

  Widget _label(String text) => Text(
    text,
    style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w600),
  );

  Widget _greyField(TextEditingController ctrl, String hint) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: ctrl,
        enabled: false,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          isCollapsed: true,
        ),
      ),
    );
  }

  Widget _disabledDropdownField(String hint, String? value) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: (value != null && value.isNotEmpty) ? value : null,
        hint: Text(
          hint,
          style: TextStyle(color: Colors.grey[600]),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        items: (value != null && value.isNotEmpty)
            ? [
                DropdownMenuItem(
                  value: value,
                  child: Text(
                    value,
                    style: TextStyle(color: primaryGreen),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ]
            : [],
        onChanged: null,
      ),
    );
  }

  Widget _dropdownField(
    String hint,
    String? value,
    List<String> items,
    ValueChanged<String?>? onChanged,
  ) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: value,
        hint: Text(
          hint,
          style: TextStyle(color: Colors.grey[600]),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        items: items
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(
                  e,
                  style: TextStyle(color: primaryGreen),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            )
            .toList(),
        onChanged: AuthService().isGuestLocked ? null : onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Icon(Icons.arrow_back_ios, color: primaryGreen),
                  ),
                  const Expanded(child: SizedBox()),
                  Text(
                    'เมนูอาหาร',
                    style: TextStyle(
                      color: primaryGreen,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Expanded(child: SizedBox()),
                  Builder(
                    builder: (_) {
                      final auth = AuthService();
                      String idText = 'Guest';
                      if (auth.isLoggedIn && auth.user != null) {
                        final uname =
                            auth.user!['username'] ??
                            auth.user!['name'] ??
                            (auth.user!['id']?.toString() ?? '—');
                        idText = uname.toString();
                      }
                      return Text(
                        idText,
                        style: TextStyle(color: primaryGreen),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.black12),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'เมนูอาหาร — ตัวอย่างการกรอกข้อมูล',
                        style: TextStyle(
                          color: primaryGreen,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'หน้านี้เป็นแค่ "ตัวอย่างให้ดู" ผู้ใช้ไม่สามารถแก้ไขหรือบันทึกข้อมูลจริงได้',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 14),

                      _label('ตัวอย่าง เมนูโปรตีน'),
                      const SizedBox(height: 8),
                      _disabledDropdownField(
                        'ตัวอย่างเมนูโปรตีน',
                        _examples['โปรตีน'],
                      ),
                      const SizedBox(height: 14),

                      _label('ตัวอย่าง เมนูผักและผลไม้'),
                      const SizedBox(height: 8),
                      _disabledDropdownField(
                        'ตัวอย่างผักและผลไม้',
                        _examples['ผักและผลไม้'],
                      ),
                      const SizedBox(height: 14),

                      _label('ตัวอย่าง เมนูคาร์โบไฮเดรต'),
                      const SizedBox(height: 8),
                      _disabledDropdownField(
                        'ตัวอย่างคาร์โบไฮเดรต',
                        _examples['คาร์โบไฮเดรต'],
                      ),
                      const SizedBox(height: 14),

                      _label('ตัวอย่าง เมนูเครื่องดื่ม'),
                      const SizedBox(height: 8),
                      _disabledDropdownField(
                        'ตัวอย่างเครื่องดื่ม',
                        _examples['เครื่องดื่ม'],
                      ),
                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'ตกลง',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 56,
        color: primaryGreen,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              icon: const Icon(Icons.home, color: Colors.white),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.search, color: Colors.white),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.list_alt, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
