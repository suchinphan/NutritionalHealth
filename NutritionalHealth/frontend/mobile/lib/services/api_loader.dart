import 'dart:convert';
import 'package:http/http.dart' as http;
import 'app_config.dart';
import 'api_client.dart';

class ApiLoader {
  static final ApiClient _client = ApiClient(getApiBase());

  // Helpers
  static Future<List<String>> _getItems(String path) async {
    try {
      final resp = await _client.get(path);
      if (resp.statusCode == 200) {
        final m = json.decode(resp.body) as Map<String, dynamic>;
        final items =
            (m['items'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
            [];
        return items;
      }
    } catch (_) {}
    return [];
  }

  // Desserts come from dedicated endpoint
  static Future<List<String>> loadDessertMenus() async {
    return await _getItems('/desserts');
  }

  // Drinks: use backend drink-menus endpoint
  static Future<List<String>> loadHealthyDrinks() async {
    return await _getItems('/drink-menus?type=เครื่องดื่มเพื่อสุขภาพ');
  }

  static Future<List<String>> loadWeightLossDrinks() async {
    return await _getItems('/drink-menus?type=เครื่องดื่มลดน้ำหนัก');
  }

  static Future<List<String>> loadEnergyDrinks() async {
    return await _getItems('/drink-menus?type=เครื่องดื่มเพิ่มพลังงาน');
  }

  // For protein/veg/carb we request semantic subcategories from backend.
  // Each method returns a map keyed by the app's subcategory labels.
  static Future<Map<String, Set<String>>> loadProteinMenus() async {
    final out = <String, Set<String>>{
      'อาหารครบ5หมู่': <String>{},
      'อาหารลดน้ำหนัก': <String>{},
      'อาหารสร้างกล้ามเนื้อ': <String>{},
    };

    // Query backend with keywords that trigger the grouped logic
    final a = await _getItems('/menus?category=ครบ 5');
    final b = await _getItems('/menus?category=ลดน้ำหนัก');
    final c = await _getItems('/menus?category=สร้างกล้าม');

    out['อาหารครบ5หมู่']!.addAll(a);
    out['อาหารลดน้ำหนัก']!.addAll(b);
    out['อาหารสร้างกล้ามเนื้อ']!.addAll(c);
    return out;
  }

  static Future<Map<String, Set<String>>> loadVegetableMenus() async {
    final out = <String, Set<String>>{
      'อาหารครบ5หมู่': <String>{},
      'อาหารลดน้ำหนัก': <String>{},
      'อาหารบำรุงสุขภาพ': <String>{},
    };
    final a = await _getItems('/menus?category=ครบ 5');
    final b = await _getItems('/menus?category=ลดน้ำหนัก');
    final c = await _getItems('/menus?category=สุขภาพ');
    out['อาหารครบ5หมู่']!.addAll(a);
    out['อาหารลดน้ำหนัก']!.addAll(b);
    out['อาหารบำรุงสุขภาพ']!.addAll(c);
    return out;
  }

  static Future<Map<String, Set<String>>> loadCarbMenus() async {
    final out = <String, Set<String>>{
      'อาหารครบ5หมู่': <String>{},
      'อาหารลดน้ำหนัก': <String>{},
      'อาหารให้พลังงานสูง': <String>{},
    };
    // Use the 'carb' keyword to instruct backend to exclude desserts
    final a = await _getItems('/menus?category=ครบ 5&filter=carb');
    final b = await _getItems('/menus?category=ลดน้ำหนัก&filter=carb');
    final c = await _getItems('/menus?category=พลังงานสูง&filter=carb');
    out['อาหารครบ5หมู่']!.addAll(a);
    out['อาหารลดน้ำหนัก']!.addAll(b);
    out['อาหารให้พลังงานสูง']!.addAll(c);
    return out;
  }
}
