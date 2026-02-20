import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';
import '../services/csv_loader.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

class ShowFoodItemsPage extends StatefulWidget {
  const ShowFoodItemsPage({super.key, this.items, this.calories});

  final List<String>? items;
  final String? calories;

  @override
  State<ShowFoodItemsPage> createState() => _ShowFoodItemsPageState();
}

class _ShowFoodItemsPageState extends State<ShowFoodItemsPage> {
  final Color primaryGreen = const Color(0xFF00C700);

  List<Map<String, dynamic>> _items = [];
  bool _loading = false;
  int _totalCalories = 0;
  String? _analysisText;

  @override
  void initState() {
    super.initState();

    if (widget.calories != null) {
      _totalCalories = int.tryParse(widget.calories!) ?? 0;
    }

    if (widget.items != null && widget.items!.isNotEmpty) {
      _prepareItems(widget.items!);
    } else {
      _fetchFromBackend(); // ✅ เรียก backend ถ้าไม่มี items
    }
  }

  void _analyzeCalories() {
    const recommendedPerDay = 2000; // ปรับได้ตามระบบคุณ
    final diff = _totalCalories - recommendedPerDay;

    if (diff > 100) {
      _analysisText =
          'คุณได้รับพลังงานมากกว่าที่แนะนำ (${_totalCalories} kcal)\n'
          'ควรออกกำลังกายเพิ่ม เช่น เดินเร็ว วิ่ง หรือปั่นจักรยาน';
    } else if (diff < -100) {
      _analysisText =
          'คุณได้รับพลังงานน้อยกว่าที่แนะนำ (${_totalCalories} kcal)\n'
          'ควรเพิ่มอาหารที่มีประโยชน์ เช่น โปรตีน ผัก และคาร์โบไฮเดรตเชิงซ้อน';
    } else {
      _analysisText =
          'คุณได้รับพลังงานในเกณฑ์เหมาะสม (${_totalCalories} kcal)\n'
          'ควรรักษาพฤติกรรมนี้ต่อไปควบคู่กับการออกกำลังกายสม่ำเสมอ';
    }
  }

  Future<void> _prepareItems(List<String> names) async {
    setState(() => _loading = true);

    final List<Map<String, dynamic>> out = [];
    int total = 0;

    try {
      final files = await CsvLoader.listBackendCsvFiles();

      for (var name in names) {
        int? kcal;

        for (var f in files) {
          try {
            final info = await CsvLoader.loadCsvRows(f);
            final header = info['header'] as String?;
            final rows = info['rows'] as List<List<String>>;

            int nameCol = -1;
            int kcalCol = -1;

            if (header != null) {
              final headers = header
                  .split(',')
                  .map((s) => s.trim().toLowerCase())
                  .toList();

              for (var i = 0; i < headers.length; i++) {
                final h = headers[i];
                if (nameCol < 0 &&
                    (h.contains('name') ||
                        h.contains('food') ||
                        h.contains('th_name') ||
                        h.contains('ชื่อ') ||
                        h.contains('item'))) {
                  nameCol = i;
                }
                if (kcalCol < 0 &&
                    (h.contains('calor') ||
                        h.contains('kcal') ||
                        h.contains('energy'))) {
                  kcalCol = i;
                }
              }
            }

            if (nameCol >= 0) {
              for (var r in rows) {
                if (nameCol >= r.length) continue;

                if (r[nameCol]
                    .toLowerCase()
                    .contains(name.toLowerCase())) {
                  if (kcalCol >= 0 && kcalCol < r.length) {
                    final v = double.tryParse(
                        r[kcalCol].replaceAll('"', '').trim());
                    if (v != null) {
                      kcal = v.round();
                      break;
                    }
                  }
                }
              }
            }

            if (kcal != null) break;
          } catch (_) {}
        }

        out.add({'name': name, 'kcal': kcal});
        if (kcal != null) total += kcal;
      }
    } catch (_) {}

    if (!mounted) return;

    setState(() {
      _items = out;
      _totalCalories = total;
      _analyzeCalories(); // ✅ วิเคราะห์พลังงาน
      _loading = false;
    });
  }

  Future<void> _fetchFromBackend() async {
    if (!mounted) return;

    setState(() => _loading = true);

    final auth = AuthService();
    final user = auth.user;
    final token = auth.token;

    if (user == null || token == null) {
      setState(() => _loading = false);
      return;
    }

    final userId = user['id'] ?? user['user_id'];

    final String apiBase = kIsWeb
        ? 'http://127.0.0.1:5000'
        : (defaultTargetPlatform == TargetPlatform.android
            ? 'http://10.0.2.2:5000'
            : 'http://127.0.0.1:5000');

    final url = Uri.parse('$apiBase/history/$userId');

    try {
      final resp = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final j = jsonDecode(resp.body);
        final history = j['history'] as List<dynamic>?;

        if (history != null && history.isNotEmpty) {
          final latest = history.last;
          String data = latest['data']?.toString() ?? '';

          List<String> recs = [];

          try {
            final parsed = jsonDecode(data);
            if (parsed is Map && parsed['recommendations'] is List) {
              recs = List<String>.from(
                parsed['recommendations'].map((e) => e.toString()),
              );
            }
          } catch (_) {}

          if (recs.isNotEmpty) {
            await _prepareItems(recs);
            return;
          }
        }
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final displayCalories =
        widget.calories ?? _totalCalories.toString();

    final selMenu = (widget.items != null && widget.items!.isNotEmpty)
        ? widget.items!.join(', ')
        : '-';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryGreen),
        title: Text(
          'แสดงรายการอาหาร',
          style: TextStyle(color: primaryGreen),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ผลลัพธ์การคำนวณ',
              style: TextStyle(
                  color: primaryGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text('พลังงานรวมที่คำนวณ: $displayCalories kcal'),
            const SizedBox(height: 6),
            Text('เมนูที่เลือก: $selMenu'),

            if (_analysisText != null) ...[
              const SizedBox(height: 10),
              Text(
                _analysisText!,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],

            const SizedBox(height: 16),
            Text(
              'รายการที่แนะนำ',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                      ? const Center(child: Text('ไม่พบข้อมูล'))
                      : ListView.separated(
                          itemCount: _items.length,
                          separatorBuilder: (_, __) =>
                              const Divider(),
                          itemBuilder: (context, index) {
                            final it = _items[index];
                            final kcal = it['kcal'];
                            return ListTile(
                              title: Text(it['name']),
                              trailing: kcal != null
                                  ? Text('${kcal} kcal')
                                  : const SizedBox.shrink(),
                            );
                          },
                        ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context)
                      .popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  padding:
                      const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'ตกลง',
                  style:
                      TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
