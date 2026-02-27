import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api_client.dart';
import '../services/auth_service.dart';
// using persistent guest lock from AuthService (no session-only locks)
import 'choose_your_meal_and_duration.dart';

class ChooseFoodTypePage extends StatefulWidget {
  const ChooseFoodTypePage({super.key});

  @override
  State<ChooseFoodTypePage> createState() => _ChooseFoodTypePageState();
}

class _ChooseFoodTypePageState extends State<ChooseFoodTypePage> {
  final Color primaryGreen = const Color(0xFF00C700);

  late final ApiClient api;
  late final AuthService _auth;

  bool _authLoaded = false;
  // guest lock is controlled by AuthService (persistent, like Personal page)

  // ===== selections (id) =====
  int? selectedFoodTypeId;
  int? selectedCategoryId;
  int? selectedFoodMenuId;
  int? selectedDrinkTypeId;
  int? selectedDrinkMenuId;
  int? selectedDessertId;

  // ===== data from API =====
  List<Map<String, dynamic>> foodTypes = [];
  List<Map<String, dynamic>> foodCategories = [];
  List<Map<String, dynamic>> foodMenus = [];
  List<Map<String, dynamic>> drinkTypes = [];
  List<Map<String, dynamic>> drinkMenus = [];
  List<Map<String, dynamic>> desserts = [];

  @override
  void initState() {
    super.initState();
    api = ApiClient("http://127.0.0.1:5000");
    _auth = AuthService();

    Future.microtask(() async {
      await _auth.loadToken();
      await _loadFoodTypes();
      await _loadDrinkTypes();
      // If guest is locked or there are persisted temp/guest selections, preload them
      await _loadSavedSelections();
      if (mounted) setState(() => _authLoaded = true);
    });
  }

  Future<void> _loadSavedSelections() async {
    try {
      final sels = _auth.tempSelections ?? _auth.guestSelections ?? {};
      if (sels.isEmpty) return;

      setState(() {
        selectedFoodTypeId = sels['food_type_id'] is int
            ? sels['food_type_id'] as int
            : int.tryParse(sels['food_type_id']?.toString() ?? '');
        selectedCategoryId = sels['category_id'] is int
            ? sels['category_id'] as int
            : int.tryParse(sels['category_id']?.toString() ?? '');
        selectedFoodMenuId = sels['food_menu_id'] is int
            ? sels['food_menu_id'] as int
            : int.tryParse(sels['food_menu_id']?.toString() ?? '');
        selectedDrinkTypeId = sels['drink_type_id'] is int
            ? sels['drink_type_id'] as int
            : int.tryParse(sels['drink_type_id']?.toString() ?? '');
        selectedDrinkMenuId = sels['drink_menu_id'] is int
            ? sels['drink_menu_id'] as int
            : int.tryParse(sels['drink_menu_id']?.toString() ?? '');
        selectedDessertId = sels['dessert_id'] is int
            ? sels['dessert_id'] as int
            : int.tryParse(sels['dessert_id']?.toString() ?? '');
      });

      // If we have a food type and category, try loading categories/menus so names are available
      if (selectedFoodTypeId != null)
        await _loadFoodCategories(selectedFoodTypeId!);
      if (selectedCategoryId != null) await _loadFoodMenus(selectedCategoryId!);
      if (selectedDrinkTypeId != null)
        await _loadDrinkMenus(selectedDrinkTypeId!);
      if (selectedFoodTypeId == 3) await _loadDesserts();
    } catch (e) {
      debugPrint('Failed to load saved selections: $e');
    }
  }

  // ================= SAFE JSON HELPER =================
  List<Map<String, dynamic>> _safeList(dynamic res, String label) {
    if (res == null || res.body == null) {
      debugPrint("❌ $label response is null");
      return [];
    }

    if (res.statusCode != 200) {
      debugPrint("❌ $label status=${res.statusCode}");
      debugPrint(res.body.toString());
      return [];
    }

    try {
      final decoded = jsonDecode(res.body);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
      debugPrint("❌ $label is not List");
    } catch (e) {
      debugPrint("❌ $label jsonDecode error: $e");
      debugPrint(res.body.toString());
    }
    return [];
  }

  // Remove duplicates by `name` (case-insensitive) and preserve order
  List<Map<String, dynamic>> _uniqueByName(List<Map<String, dynamic>> list) {
    final seen = <String>{};
    final out = <Map<String, dynamic>>[];
    for (final item in list) {
      final name = (item["name"] ?? '').toString().trim().toLowerCase();
      if (name.isEmpty) continue;
      if (!seen.contains(name)) {
        seen.add(name);
        out.add(item);
      }
    }
    return out;
  }

  // Return a new list sorted by `name` (case-insensitive)
  List<Map<String, dynamic>> _sortByName(List<Map<String, dynamic>> list) {
    final copy = List<Map<String, dynamic>>.from(list);
    copy.sort((a, b) {
      final an = (a['name'] ?? '').toString().toLowerCase();
      final bn = (b['name'] ?? '').toString().toLowerCase();
      return an.compareTo(bn);
    });
    return copy;
  }

  // Order food types in the app-specific preferred order
  List<Map<String, dynamic>> _orderFoodTypes(List<Map<String, dynamic>> list) {
    // preferred order by id if available: 1=โปรตีน, 2=ผักและผลไม้, 3=คาร์โบไฮเดรต
    final desired = [1, 2, 3];
    final copy = List<Map<String, dynamic>>.from(list);
    copy.sort((a, b) {
      final ai = a['id'] is int
          ? a['id'] as int
          : int.tryParse(a['id'].toString()) ?? 999;
      final bi = b['id'] is int
          ? b['id'] as int
          : int.tryParse(b['id'].toString()) ?? 999;
      final aiIdx = desired.contains(ai)
          ? desired.indexOf(ai)
          : desired.length + ai;
      final biIdx = desired.contains(bi)
          ? desired.indexOf(bi)
          : desired.length + bi;
      return aiIdx.compareTo(biIdx);
    });
    return copy;
  }

  // Order categories for a given food type. For food_type_id==2 (ผักและผลไม้)
  // enforce: อาหารครบ5หมู่, อาหารลดน้ำหนัก, อาหารบำรุงสุขภาพ
  List<Map<String, dynamic>> _orderFoodCategories(
    int foodTypeId,
    List<Map<String, dynamic>> list,
  ) {
    if (foodTypeId != 2) return _sortByName(list);

    final preferred = ['อาหารครบ5หมู่', 'อาหารลดน้ำหนัก', 'อาหารบำรุงสุขภาพ'];

    final copy = List<Map<String, dynamic>>.from(list);
    copy.sort((a, b) {
      final an = (a['name'] ?? '').toString().trim();
      final bn = (b['name'] ?? '').toString().trim();
      final ai = preferred.indexWhere((p) => p == an);
      final bi = preferred.indexWhere((p) => p == bn);
      if (ai >= 0 && bi >= 0) return ai.compareTo(bi);
      if (ai >= 0) return -1;
      if (bi >= 0) return 1;
      return an.toLowerCase().compareTo(bn.toLowerCase());
    });
    return copy;
  }

  // Ensure desserts are actually desserts (if backend provides an `is_dessert`
  // flag) and remove duplicates.
  List<Map<String, dynamic>> _filterDesserts(List<Map<String, dynamic>> list) {
    final filtered = list.where((e) {
      if (e.containsKey('is_dessert')) {
        final v = e['is_dessert'];
        if (v is int) return v == 1;
        if (v is bool) return v;
      }
      // fallback: if category field exists and equals 'dessert'
      if (e.containsKey('category')) {
        final c = e['category']?.toString().toLowerCase() ?? '';
        if (c == 'dessert' || c == 'ของหวาน') return true;
      }
      // otherwise keep it (best-effort) — but we'll still dedupe
      return true;
    }).toList();

    return _uniqueByName(filtered);
  }

  // ================= API LOADERS =================

  Future<void> _loadFoodTypes() async {
    final res = await api.get("/api/food-types");
    setState(() {
      foodTypes = _orderFoodTypes(
        _sortByName(_uniqueByName(_safeList(res, "food-types"))),
      );
    });
  }

  Future<void> _loadFoodCategories(int foodTypeId) async {
    final res = await api.get("/api/food-categories?food_type_id=$foodTypeId");
    setState(() {
      final raw = _sortByName(_uniqueByName(_safeList(res, "food-categories")));
      foodCategories = _orderFoodCategories(foodTypeId, raw);
      // If the caller cleared `selectedCategoryId` before calling (user
      // actively changed food type), keep the clearing behavior. But when
      // loading during init from persisted selections, preserving the
      // existing `selectedCategoryId` helps show the saved value inside
      // the dropdown instead of wiping it.
      if (selectedCategoryId == null) {
        foodMenus = [];
        selectedFoodMenuId = null;
      }
    });
  }

  Future<void> _loadFoodMenus(int categoryId) async {
    final res = await api.get("/api/food-menus-simple?category_id=$categoryId");
    setState(() {
      // Ensure food menus are unique and exclude desserts (they have their own list)
      final raw = _safeList(res, "food-menus");
      final nonDessert = raw.where((e) {
        if (e.containsKey('is_dessert')) {
          final v = e['is_dessert'];
          if (v is int) return v == 0;
          if (v is bool) return !v;
        }
        return true;
      }).toList();

      foodMenus = _sortByName(_uniqueByName(nonDessert));
      // Preserve a previously-restored selectedFoodMenuId if it exists in
      // the newly-loaded list; otherwise clear it.
      if (selectedFoodMenuId != null) {
        final exists = foodMenus.any((e) {
          final id = e['id'] is int
              ? e['id'] as int
              : int.tryParse(e['id'].toString() ?? '');
          return id == selectedFoodMenuId;
        });
        if (!exists) selectedFoodMenuId = null;
      }
    });
  }

  Future<void> _loadDrinkTypes() async {
    final res = await api.get("/api/drink-types");
    setState(() {
      drinkTypes = _sortByName(_uniqueByName(_safeList(res, "drink-types")));
    });
  }

  Future<void> _loadDrinkMenus(int drinkTypeId) async {
    final res = await api.get("/api/drink-menus?drink_type_id=$drinkTypeId");
    setState(() {
      // Only keep unique drink names (filtering duplicates)
      drinkMenus = _sortByName(_uniqueByName(_safeList(res, "drink-menus")));
      if (selectedDrinkMenuId != null) {
        final exists = drinkMenus.any((e) {
          final id = e['id'] is int
              ? e['id'] as int
              : int.tryParse(e['id'].toString() ?? '');
          return id == selectedDrinkMenuId;
        });
        if (!exists) selectedDrinkMenuId = null;
      }
    });
  }

  Future<void> _loadDesserts() async {
    final res = await api.get("/api/dessert-menus");
    setState(() {
      // Filter to actual desserts and dedupe by name
      desserts = _sortByName(_filterDesserts(_safeList(res, "desserts")));
      if (selectedDessertId != null) {
        final exists = desserts.any((e) {
          final id = e['id'] is int
              ? e['id'] as int
              : int.tryParse(e['id'].toString() ?? '');
          return id == selectedDessertId;
        });
        if (!exists) selectedDessertId = null;
      }
    });
  }

  // ================= UI HELPERS =================

  Widget _dropdown({
    required String hint,
    required int? value,
    required List<Map<String, dynamic>> items,
    ValueChanged<int?>? onChanged,
    bool enabled = true,
  }) {
    final uniq = items.toList();
    return IgnorePointer(
      ignoring: !enabled,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.7,
        child: DropdownButtonFormField<int>(
          value: value,
          isExpanded: true,
          items: uniq
              .map(
                (e) => DropdownMenuItem<int>(
                  value: e["id"],
                  child: Text(e["name"].toString()),
                ),
              )
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  String _nameForId(List<Map<String, dynamic>> list, int? id) {
    if (id == null) return '';
    try {
      final found = list.firstWhere(
        (e) =>
            (e['id'] is int
                ? e['id'] as int
                : int.tryParse(e['id'].toString() ?? '')) ==
            id,
        orElse: () => {},
      );
      return (found['name'] ?? '').toString();
    } catch (_) {
      return '';
    }
  }

  bool get isFormComplete =>
      selectedFoodTypeId != null &&
      selectedCategoryId != null &&
      selectedFoodMenuId != null &&
      selectedDrinkTypeId != null &&
      selectedDrinkMenuId != null;

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    if (!_authLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final auth = _auth;
    // Inputs are always editable on this page; finalization happens after
    // the user proceeds to the next page. Do not depend on guest lock here.
    final bool canEdit = true;

    final Map<String, dynamic>? persisted =
        auth.tempSelections ?? auth.guestSelections;
    // Next button enabled when required fields are selected.
    final bool nextEnabled = isFormComplete;

    return Scaffold(
      appBar: AppBar(
        title: const Text("เลือกประเภทอาหาร"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icon(Icons.arrow_back, color: primaryGreen),
        ),
        titleTextStyle: TextStyle(
          color: primaryGreen,
          fontSize: 18,
          fontWeight: FontWeight.w700,
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
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              _dropdown(
                hint: "ประเภทอาหาร",
                value: selectedFoodTypeId,
                items: foodTypes,
                enabled: canEdit,
                onChanged: canEdit
                    ? (v) async {
                        setState(() {
                          selectedFoodTypeId = v;
                          selectedCategoryId = null;
                          foodMenus = [];
                          selectedFoodMenuId = null;
                          desserts = [];
                          selectedDessertId = null;
                        });
                        if (v != null) await _loadFoodCategories(v);
                      }
                    : null,
              ),
              const SizedBox(height: 12),

              if (foodCategories.isNotEmpty)
                _dropdown(
                  hint: "หมวดหมู่",
                  value: selectedCategoryId,
                  items: foodCategories,
                  enabled: canEdit,
                  onChanged: canEdit
                      ? (v) async {
                          setState(() {
                            selectedCategoryId = v;
                          });
                          if (v != null) await _loadFoodMenus(v);
                          if (selectedFoodTypeId == 3) {
                            await _loadDesserts();
                          }
                        }
                      : null,
                ),
              const SizedBox(height: 12),

              if (foodMenus.isNotEmpty)
                _dropdown(
                  hint: "เมนูอาหาร",
                  value: selectedFoodMenuId,
                  items: foodMenus,
                  enabled: canEdit,
                  onChanged: canEdit
                      ? (v) => setState(() {
                          selectedFoodMenuId = v;
                        })
                      : null,
                ),
              const SizedBox(height: 12),

              if (desserts.isNotEmpty)
                _dropdown(
                  hint: "ของหวาน",
                  value: selectedDessertId,
                  items: desserts,
                  enabled: canEdit,
                  onChanged: canEdit
                      ? (v) => setState(() {
                          selectedDessertId = v;
                        })
                      : null,
                ),
              const SizedBox(height: 12),

              _dropdown(
                hint: "ประเภทเครื่องดื่ม",
                value: selectedDrinkTypeId,
                items: drinkTypes,
                enabled: canEdit,
                onChanged: canEdit
                    ? (v) async {
                        setState(() {
                          selectedDrinkTypeId = v;
                        });
                        if (v != null) await _loadDrinkMenus(v);
                      }
                    : null,
              ),
              const SizedBox(height: 12),

              if (drinkMenus.isNotEmpty)
                _dropdown(
                  hint: "เมนูเครื่องดื่ม",
                  value: selectedDrinkMenuId,
                  items: drinkMenus,
                  enabled: canEdit,
                  onChanged: canEdit
                      ? (v) => setState(() {
                          selectedDrinkMenuId = v;
                        })
                      : null,
                ),

              const SizedBox(height: 24),

              // Show read-only banner when guest is locked for the session
              // or permanently (auth.guestUsed).
              // No read-only banner here; this page remains editable and
              // finalization is done by replacing the route when proceeding.
              ElevatedButton(
                onPressed: nextEnabled
                    ? () async {
                        final sels = {
                          'food_type_id': selectedFoodTypeId,
                          'category_id': selectedCategoryId,
                          'food_menu_id': selectedFoodMenuId,
                          'dessert_id': selectedDessertId,
                          'drink_type_id': selectedDrinkTypeId,
                          'drink_menu_id': selectedDrinkMenuId,
                          // store human-readable names so read-only views can
                          // display them even if id->name resolution isn't ready
                          'selectedType': selectedFoodTypeId != null
                              ? _nameForId(foodTypes, selectedFoodTypeId)
                              : null,
                          'selectedCategory': selectedCategoryId != null
                              ? _nameForId(foodCategories, selectedCategoryId)
                              : null,
                          'selectedMenu': selectedFoodMenuId != null
                              ? _nameForId(foodMenus, selectedFoodMenuId)
                              : null,
                          'selectedDessert': selectedDessertId != null
                              ? _nameForId(desserts, selectedDessertId)
                              : null,
                          'selectedDrinkType': selectedDrinkTypeId != null
                              ? _nameForId(drinkTypes, selectedDrinkTypeId)
                              : null,
                          'selectedDrinkMenu': selectedDrinkMenuId != null
                              ? _nameForId(drinkMenus, selectedDrinkMenuId)
                              : null,
                        };
                        if (auth.isGuest) {
                          try {
                            // Persist selections as temp so the next page can use them.
                            auth.setTempSelections(sels);
                            setState(() {});
                          } catch (_) {}
                        }

                        // Navigate forward using available ids and replace this
                        // page so the user cannot go back to change selections
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChooseYourMealAndDurationPage(
                              foodTypeId: selectedFoodTypeId ?? 0,
                              categoryId: selectedCategoryId ?? 0,
                              foodMenuId: selectedFoodMenuId ?? 0,
                              drinkTypeId: selectedDrinkTypeId ?? 0,
                              drinkMenuId: selectedDrinkMenuId ?? 0,
                              dessertId: selectedDessertId,
                            ),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: nextEnabled ? primaryGreen : Colors.grey,
                  foregroundColor: Colors.white,
                ),
                child: const Text("หน้าถัดไป"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
