import 'package:flutter/material.dart';
// removed import of main.dart to avoid circular import
import '../services/csv_loader.dart';
import '../services/auth_service.dart';

class ClassFoodPage extends StatefulWidget {
  const ClassFoodPage({super.key});

  @override
  State<ClassFoodPage> createState() => _ClassFoodPageState();
}

class _ClassFoodPageState extends State<ClassFoodPage> {
  final Color primaryGreen = const Color(0xFF00C700);

  // ตัวเลือกสำหรับ dropdown (will be loaded from CSV when available)
  List<String> _typeOptions = ['เมนูโปรตีน', 'เมนูผักและผลไม้', 'เมนูคาร์โบไฮเดรต', 'เครื่องดื่ม'];
  final List<String> _appCategories = ['เครื่องดื่มเพื่อสุขภาพ', 'เครื่องดื่มลดน้ำหนัก', 'เครื่องดื่มบำรุงร่างกาย / เพิ่มพลังงาน'];
  List<String> _menuOptions = ['เมนูแนะนำ A', 'เมนูแนะนำ B', 'เมนูแนะนำ C'];

  // hierarchical map: appCategory -> typeKey -> set(items)
  final Map<String, Map<String, Set<String>>> _hierarchy = {};

  String? _selectedType;
  String? _selectedSearch;
  String? _selectedMenu;

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
      final protein = await CsvLoader.loadProteinMenus();
      final veg = await CsvLoader.loadVegetableMenus();
      final carb = await CsvLoader.loadCarbMenus();
      final desserts = await CsvLoader.loadDessertMenus();
      final healthy = await CsvLoader.loadHealthyDrinks();
      final weightloss = await CsvLoader.loadWeightLossDrinks();
      final energy = await CsvLoader.loadEnergyDrinks();

      final Map<String, Map<String, Set<String>>> h = {};
      h['เมนูหลัก'] = {
        'เมนูโปรตีน': protein.toSet(),
        'เมนูผักและผลไม้': veg.toSet(),
        'เมนูคาร์โบไฮเดรต': carb.toSet(),
      };
      h['ของหวาน'] = {
        'ของหวาน': desserts.toSet(),
      };
      h['เครื่องดื่มเพื่อสุขภาพ'] = {'เครื่องดื่มเพื่อสุขภาพ': healthy.toSet()};
      h['เครื่องดื่มลดน้ำหนัก'] = {'เครื่องดื่มลดน้ำหนัก': weightloss.toSet()};
      h['เครื่องดื่มบำรุงร่างกาย / เพิ่มพลังงาน'] = {'เครื่องดื่มเพิ่มพลังงาน': energy.toSet()};

      setState(() {
        _hierarchy.clear();
        _hierarchy.addAll(h);
        final allTypes = <String>{};
        for (var m in _hierarchy.values) {
          allTypes.addAll(m.keys);
        }
        if (allTypes.isNotEmpty) _typeOptions = allTypes.take(10).toList();
        _examples['โปรตีน'] = protein.isNotEmpty ? protein.first : '';
        _examples['ผักและผลไม้'] = veg.isNotEmpty ? veg.first : '';
        _examples['คาร์โบไฮเดรต'] = carb.isNotEmpty ? carb.first : '';
        _examples['เครื่องดื่ม'] = (healthy.isNotEmpty ? healthy.first : (energy.isNotEmpty ? energy.first : ''));
      });
    } catch (_) {
      // keep defaults on failure
    }

  }

  Widget _dropdownField(String hint, String? value, List<String> items, ValueChanged<String?>? onChanged) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: value,
        hint: Text(hint, style: TextStyle(color: Colors.grey[600]), overflow: TextOverflow.ellipsis, maxLines: 1),
        decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 12)),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(color: primaryGreen), overflow: TextOverflow.ellipsis, maxLines: 1))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _section(String title, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: primaryGreen, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        field,
        const SizedBox(height: 18),
      ],
    );
  }

  Widget _disabledDropdownField(String hint, String? value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        value: (value != null && value.isNotEmpty) ? value : null,
        hint: Text(hint, style: TextStyle(color: Colors.grey[600]), overflow: TextOverflow.ellipsis, maxLines: 1),
        decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 12)),
        items: (value != null && value.isNotEmpty) ? [DropdownMenuItem(value: value, child: Text(value, style: TextStyle(color: primaryGreen), overflow: TextOverflow.ellipsis, maxLines: 1))] : [],
        onChanged: null,
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
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).maybePop(),
                        child: Icon(Icons.arrow_back, color: primaryGreen, size: 30),
                      ),
                      const Expanded(child: SizedBox()),
                      Text('คลาสอาหาร', style: TextStyle(color: primaryGreen, fontSize: 18, fontWeight: FontWeight.w700)),
                      const Expanded(child: SizedBox()),
                      Builder(builder: (_) {
                        final auth = AuthService();
                        String idText = 'Guest';
                        if (auth.isLoggedIn && auth.user != null) {
                          final uname = auth.user!['username'] ?? auth.user!['name'] ?? (auth.user!['id']?.toString() ?? '—');
                          idText = uname.toString();
                        }
                        return Text(idText, style: TextStyle(color: primaryGreen));
                      }),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1, color: Colors.black12),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('คลาสอาหาร — ตัวอย่างการกรอกข้อมูล', style: TextStyle(color: primaryGreen, fontSize: 20, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text('หน้านี้เป็นแค่ "ตัวอย่างให้ดู" ผู้ใช้ไม่สามารถแก้ไขหรือบันทึกข้อมูลจริงได้', style: TextStyle(color: Colors.black54)),
                      const SizedBox(height: 14),

                      _section('ตัวอย่าง เมนูโปรตีน', _disabledDropdownField('ตัวอย่างเมนูโปรตีน', _examples['โปรตีน'])),
                      _section('ตัวอย่าง เมนูผักและผลไม้', _disabledDropdownField('ตัวอย่างผักและผลไม้', _examples['ผักและผลไม้'])),
                      _section('ตัวอย่าง เมนูคาร์โบไฮเดรต', _disabledDropdownField('ตัวอย่างคาร์โบไฮเดรต', _examples['คาร์โบไฮเดรต'])),
                      _section('ตัวอย่าง เมนูเครื่องดื่ม', _disabledDropdownField('ตัวอย่างเครื่องดื่ม', _examples['เครื่องดื่ม'])),

                      const SizedBox(height: 8),
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            elevation: 0,
                          ),
                          child: const Text('กลับหน้าหลัก', style: TextStyle(color: Colors.white)),
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
          children: const [
            Icon(Icons.home, color: Colors.white),
            Icon(Icons.search, color: Colors.white),
            Icon(Icons.list_alt, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
