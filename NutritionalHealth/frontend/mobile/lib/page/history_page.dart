import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late AuthService auth;

  final Color primaryGreen = const Color(0xFF00C700);

  List<Map<String, dynamic>> _entries = [];
  bool _loading = true;
  String _ownerLabel = '';

  @override
  void initState() {
    super.initState();
    auth = Provider.of<AuthService>(context, listen: false);
    _init();
  }

  Future<void> _init() async {
    await auth.loadToken();

    if (!auth.isLoggedIn) {
      if (!mounted) return;
      setState(() {
        _ownerLabel = 'Guest';
        _loading = false;
      });
      return;
    }

    await _loadHistory();
  }

  Future<void> _loadHistory() async {
    final String apiBase = kIsWeb
        ? 'http://127.0.0.1:5000'
        : (defaultTargetPlatform == TargetPlatform.android
            ? 'http://10.0.2.2:5000'
            : 'http://127.0.0.1:5000');

    List<Map<String, dynamic>> items = [];

    try {
      if (auth.isLoggedIn && auth.user != null) {
        final uid =
            auth.user?['id'] ?? auth.user?['user_id'];

        if (uid == null) return;

        final url = Uri.parse('$apiBase/history/$uid');

        final headers = {
          'Content-Type': 'application/json',
        };

        if (auth.token != null && auth.token!.isNotEmpty) {
          headers['Authorization'] = 'Bearer ${auth.token}';
        }

        final resp = await http.get(url, headers: headers);

        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          final j = jsonDecode(resp.body);
          final raw = j['history'] as List<dynamic>? ?? [];

          for (var r in raw) {
            dynamic rawData = r['data'];
            Map<String, dynamic> parsedData = {};

            if (rawData is String) {
              try {
                parsedData = jsonDecode(rawData);
              } catch (_) {
                parsedData = {};
              }
            } else if (rawData is Map) {
              parsedData =
                  Map<String, dynamic>.from(rawData);
            }

            items.add({
              'id': r['id'],
              'data': parsedData,
              'created_at': r['created_at'],
            });
          }

          // 🔥 เรียงใหม่สุดก่อน
          items.sort((a, b) {
            final aDate =
                DateTime.tryParse(a['created_at'] ?? '');
            final bDate =
                DateTime.tryParse(b['created_at'] ?? '');
            if (aDate == null || bDate == null) {
              return 0;
            }
            return bDate.compareTo(aDate);
          });
        }

        // 🔥 token หมดอายุ
        else if (resp.statusCode == 401) {
          await auth.clearToken(force: true);
          if (!mounted) return;
          Navigator.of(context)
              .pushReplacementNamed('/login');
          return;
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('โหลดประวัติไม่สำเร็จ')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล')),
      );
    }

    final userMap = auth.user ?? {};
    final uid =
        userMap['id'] ?? userMap['user_id'];

    if (!mounted) return;

    setState(() {
      _entries = items;
      _loading = false;

      _ownerLabel =
          (userMap['username']?.toString().trim()
                      .isNotEmpty ==
                  true)
              ? userMap['username'].toString()
              : (userMap['email'] != null &&
                      userMap['email']
                          .toString()
                          .contains('@')
                  ? userMap['email']
                      .toString()
                      .split('@')
                      .first
                  : (uid?.toString() ?? 'User'));
    });
  }

  Widget buildInfoRow(String label, dynamic value) {
    final displayValue =
        (value == null || value.toString().isEmpty)
            ? '-'
            : value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        "$label : $displayValue",
        style: TextStyle(color: primaryGreen),
      ),
    );
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    try {
      return double.parse(v.toString());
    } catch (_) {
      return null;
    }
  }

  String _computeBMIStatus(Map<String, dynamic> personal) {
    final weight = _toDouble(personal['weight']);
    final height = _toDouble(personal['height']);
    if (weight == null || height == null || height <= 0) return '-';
    // assume height in cm -> convert to meters
    double h = height > 3 ? height / 100.0 : height;
    final bmi = weight / (h * h);
    String status;
    if (bmi < 18.5) {
      status = 'ผอม';
    } else if (bmi < 23) {
      status = 'ปกติ';
    } else if (bmi < 25) {
      status = 'อวบ';
    } else {
      status = 'อ้วน';
    }
    return '${status} (BMI ${bmi.toStringAsFixed(1)})';
  }

  String _joinList(dynamic value) {
    if (value == null) return '-';
    if (value is String) return value.isEmpty ? '-' : value;
    if (value is List) return value.map((e) => e.toString()).join(', ');
    if (value is Map) return value.toString();
    return value.toString();
  }

  String _getCaloriesForDuration(Map<String, dynamic> calories, dynamic duration) {
    if (calories.isEmpty) return '-';
    // check common keys
    final candidates = [
      'total_for_duration',
      'total',
      'received_for_duration',
      'intake_total',
      'calories_for_duration',
      'consumed_total',
    ];
    for (var k in candidates) {
      if (calories.containsKey(k) && calories[k] != null) {
        return calories[k].toString();
      }
    }

    // If we have per-day value and duration, multiply
    final perDay = _toDouble(calories['intake_per_day'] ?? calories['per_day']);
    final days = _toDouble(duration);
    if (perDay != null && days != null) {
      final total = (perDay * days).toStringAsFixed(0);
      return total;
    }

    return '-';
  }

  Map<String, dynamic> parseToMap(dynamic value) {
    if (value is String) {
      try {
        return jsonDecode(value);
      } catch (_) {
        return {};
      }
    } else if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return {};
  }

  Widget buildBackButton() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          minimumSize:
              const Size(double.infinity, 45),
        ),
        onPressed: () {
          Navigator.pop(context);
        },
        child: const Text("กลับหน้าหลัก"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'ประวัติ',
          style: TextStyle(color: primaryGreen),
        ),
        actions: [
          Padding(
            padding:
                const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                _ownerLabel,
                style: TextStyle(
                  color: primaryGreen,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: auth.isLoggedIn
          ? Column(
              children: [
                Expanded(
                  child: _entries.isEmpty
                      ? Center(
                          child: Text(
                            'ยังไม่มีการกรอกข้อมูล',
                            style: TextStyle(
                                color:
                                    primaryGreen),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh:
                              _loadHistory,
                          child:
                              ListView.builder(
                            padding:
                                const EdgeInsets
                                    .all(18),
                            itemCount:
                                _entries.length,
                            itemBuilder:
                                (ctx, i) {
                              final entry =
                                  _entries[i];
                              final data =
                                  entry['data']
                                          as Map<
                                              String,
                                              dynamic>? ??
                                      {};

                              Map<String,
                                      dynamic>
                                  personal =
                                  data.containsKey(
                                          'personal')
                                      ? parseToMap(
                                          data[
                                              'personal'])
                                      : data;

                              Map<String,
                                      dynamic>
                                  calories =
                                  data.containsKey(
                                          'calories')
                                      ? parseToMap(
                                          data[
                                              'calories'])
                                      : {};

                              return Card(
                                color: Colors
                                    .grey
                                    .shade200,
                                margin:
                                    const EdgeInsets
                                            .only(
                                        bottom:
                                            16),
                                child: Padding(
                                  padding:
                                      const EdgeInsets
                                              .all(
                                          16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Text(
                                        "ครั้งที่ ${i + 1}",
                                        style:
                                            TextStyle(
                                          color:
                                              primaryGreen,
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                        ),
                                      ),
                                      const SizedBox(
                                          height:
                                              10),
                                      buildInfoRow(
                                          "อายุ",
                                          personal[
                                              'age']),
                                      buildInfoRow(
                                          "เพศ",
                                          personal[
                                              'gender']),
                                      buildInfoRow(
                                          "น้ำหนัก",
                                          personal[
                                              'weight']),
                                      buildInfoRow(
                                          "ส่วนสูง",
                                          personal[
                                              'height']),
                                      buildInfoRow(
                                          "รับ/วัน",
                                          calories[
                                              'intake_per_day']),
                                      buildInfoRow(
                                          "ควรรับ/วัน",
                                          calories[
                                              'recommended_per_day']),
                                          const SizedBox(height: 6),
                                          // Additional fields
                                          buildInfoRow(
                                            "ประเภทอาหาร",
                                            data.containsKey('selection')
                                              ? (data['selection'] is Map
                                                ? (data['selection']['food_type'] ?? data['food_type'])
                                                : data['food_type'])
                                              : (data['food_type'] ?? '-')),
                                          buildInfoRow(
                                            "หมวดที่เลือก",
                                            data.containsKey('selection')
                                              ? (data['selection'] is Map
                                                ? (data['selection']['category'] ?? '-')
                                                : '-')
                                              : '-'),
                                          Padding(
                                          padding: const EdgeInsets.only(bottom: 6),
                                          child: Text(
                                            "เมนูตามหมวด: ${_joinList(data['menus'] ?? (data['selection'] is Map ? data['selection']['menu_options'] : null))}",
                                            style: TextStyle(color: primaryGreen),
                                          ),
                                          ),
                                          Padding(
                                          padding: const EdgeInsets.only(bottom: 6),
                                          child: Text(
                                            "เมนูที่เลือก: ${_joinList(data['selected_menus'] ?? (data['selection'] is Map ? data['selection']['selected_menus'] : null))}",
                                            style: TextStyle(color: primaryGreen),
                                          ),
                                          ),
                                          buildInfoRow(
                                            "เมนูเครื่องดื่ม",
                                            _joinList(data['drink_options'] ?? (data['selection'] is Map ? data['selection']['drink_options'] : null))),
                                          buildInfoRow(
                                            "เครื่องดื่มที่เลือก",
                                            _joinList(data['selected_drink'] ?? (data['selection'] is Map ? data['selection']['selected_drink'] : null))),
                                          buildInfoRow(
                                            "มื้ออาหาร",
                                            data['meal'] ?? (data['selection'] is Map ? data['selection']['meal'] : '-')),
                                          buildInfoRow(
                                            "ระยะเวลา (วัน)",
                                            data['duration'] ?? (data['selection'] is Map ? data['selection']['duration'] : '-')),
                                          buildInfoRow(
                                            "สถานะ (BMI)",
                                            _computeBMIStatus(personal)),
                                          buildInfoRow(
                                            "แคลอรีรวม (ช่วงที่เลือก)",
                                            _getCaloriesForDuration(calories, data['duration'] ?? (data['selection'] is Map ? data['selection']['duration'] : null))),
                                          Padding(
                                          padding: const EdgeInsets.only(bottom: 6),
                                          child: Text(
                                            "คำแนะนำ: ${data['recommendation'] ?? data['advice'] ?? data['notes'] ?? calories['advice'] ?? '-'}",
                                            style: TextStyle(color: primaryGreen),
                                          ),
                                          ),
                                          Padding(
                                          padding: const EdgeInsets.only(bottom: 6),
                                          child: Text(
                                            "คำอธิบาย: ${data['description'] ?? data['explanation'] ?? '-'}",
                                            style: TextStyle(color: primaryGreen),
                                          ),
                                          ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
                buildBackButton(),
              ],
            )
          : Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Center(
                  child: Text(
                    'ประวัติการใช้งานมีให้เฉพาะผู้ใช้ที่ล็อกอินเท่านั้น',
                    style: TextStyle(
                        color: primaryGreen),
                    textAlign:
                        TextAlign.center,
                  ),
                ),
                buildBackButton(),
              ],
            ),
    );
  }
}
