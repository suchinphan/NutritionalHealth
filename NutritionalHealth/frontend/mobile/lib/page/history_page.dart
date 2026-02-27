import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform, debugPrint;

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

    // Deny access to history for guests or when not logged in.
    if (!auth.isLoggedIn || auth.isGuest) {
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

    final userMap = auth.user ?? {};
    final uid =
        userMap['id'] ??
        userMap['user_id'] ??
        userMap['uid'] ??
        userMap['userId'];

    // If we don't have a uid, clear loading and show owner label
    if (uid == null) {
      if (!mounted) return;
      setState(() {
        _entries = [];
        _loading = false;
        _ownerLabel =
            (userMap['username']?.toString().trim().isNotEmpty == true)
            ? userMap['username'].toString()
            : (userMap['email'] != null &&
                      userMap['email'].toString().contains('@')
                  ? userMap['email'].toString().split('@').first
                  : 'User');
      });
      return;
    }

    try {
      final url = Uri.parse('$apiBase/history/$uid');

      final headers = {'Content-Type': 'application/json'};
      if (auth.token != null && auth.token!.isNotEmpty) {
        headers['Authorization'] = 'Bearer ${auth.token}';
      }

      final resp = await http.get(url, headers: headers);
      debugPrint('History GET: $url -> ${resp.statusCode}');
      debugPrint('History response body: ${resp.body}');

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        dynamic j;
        try {
          j = jsonDecode(resp.body);
        } catch (_) {
          j = null;
        }

        List<dynamic> raw = [];

        if (j is List) {
          raw = j;
        } else if (j is Map) {
          // Accept multiple possible shapes and normalize to a list.
          final historyNode = j['history'];
          final dataNode = j['data'];
          final resultsNode = j['results'];

          if (historyNode is List) {
            raw = historyNode;
          } else if (historyNode is Map) {
            raw = [historyNode];
          } else if (dataNode is List) {
            raw = dataNode;
          } else if (dataNode is Map) {
            raw = [dataNode];
          } else if (resultsNode is List) {
            raw = resultsNode;
          } else if (resultsNode is Map) {
            raw = [resultsNode];
          } else {
            // Fallback: if the top-level map looks like a single entry, include it.
            raw = [j];
          }
        }

        debugPrint('History parsed raw length: ${raw.length}');
        // Temporary debug: log keys and shapes of parsed entries for regression safety
        try {
          debugPrint(
            'History raw sample keys: ${raw.isNotEmpty && raw.first is Map ? (raw.first as Map).keys.toList() : 'n/a'}',
          );
        } catch (_) {}
        for (var r in raw) {
          dynamic rawData = r is Map && r.containsKey('data') ? r['data'] : r;
          Map<String, dynamic> parsedData = {};

          if (rawData is String) {
            try {
              final dec = jsonDecode(rawData);
              if (dec is Map) {
                parsedData = Map<String, dynamic>.from(dec);
              } else {
                // Non-map JSON (string/number) — keep raw string
                parsedData = {'raw_data': rawData};
              }
            } catch (_) {
              // Not JSON — preserve the raw string so it's visible in UI
              parsedData = {'raw_data': rawData};
            }
          } else if (rawData is Map) {
            parsedData = Map<String, dynamic>.from(rawData);
          }

          // Fallback: if parsedData is empty, try alternative locations
          // that some backends use (top-level r, r['result'], r['payload'], etc.)
          if (parsedData.isEmpty && r is Map) {
            // Common alternative keys that might contain the submission
            final altKeys = [
              'data',
              'result',
              'payload',
              'selection',
              'recommendation',
              'calories',
              'personal',
            ];
            bool found = false;
            for (var k in altKeys) {
              if (r.containsKey(k) && r[k] != null) {
                final candidate = r[k];
                if (candidate is Map) {
                  parsedData = Map<String, dynamic>.from(candidate);
                  found = true;
                  break;
                } else if (candidate is String) {
                  try {
                    final decoded = jsonDecode(candidate);
                    if (decoded is Map) {
                      parsedData = Map<String, dynamic>.from(decoded);
                      found = true;
                      break;
                    }
                  } catch (_) {}
                }
              }
            }

            // As a last resort, if r itself contains useful-looking keys, use r.
            if (!found) {
              final candidates = [
                'personal',
                'calories',
                'recommendation',
                'menus',
                'selected_menus',
              ];
              for (var k in candidates) {
                if (r.containsKey(k)) {
                  parsedData = Map<String, dynamic>.from(r);
                  break;
                }
              }
              // If still empty but r has a non-empty 'data' string, preserve it
              if (parsedData.isEmpty &&
                  r.containsKey('data') &&
                  r['data'] is String &&
                  (r['data'] as String).trim().isNotEmpty) {
                parsedData = {'raw_data': r['data']};
              }
            }
          }

          items.add({
            'id': (r is Map) ? r['id'] : null,
            'data': parsedData,
            'created_at': (r is Map) ? r['created_at'] : null,
          });
        }

        // sort oldest first (chronological)
        items.sort((a, b) {
          final aDate = DateTime.tryParse(a['created_at'] ?? '');
          final bDate = DateTime.tryParse(b['created_at'] ?? '');
          if (aDate == null || bDate == null) return 0;
          return aDate.compareTo(bDate);
        });
        debugPrint('History items after parsing: ${items.length}');
        // Log keys for each parsed `data` map to help catch key/name regressions
        for (var i = 0; i < items.length; i++) {
          try {
            final d = items[i]['data'];
            if (d is Map)
              debugPrint('History item[$i] data.keys: ${d.keys.toList()}');
          } catch (_) {}
        }
        // Temporary assertion (debug-only) to ensure each entry has a data field
        assert(items.every((e) => e.containsKey('data')));
      } else if (resp.statusCode == 401) {
        await auth.clearToken(force: true);
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('โหลดประวัติไม่สำเร็จ')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล')),
      );
    }

    if (!mounted) return;

    setState(() {
      _entries = items;
      _loading = false;

      _ownerLabel = (userMap['username']?.toString().trim().isNotEmpty == true)
          ? userMap['username'].toString()
          : (userMap['email'] != null &&
                    userMap['email'].toString().contains('@')
                ? userMap['email'].toString().split('@').first
                : (uid?.toString() ?? 'User'));
    });
  }

  Widget buildInfoRow(String label, dynamic value) {
    final displayValue = (value == null || value.toString().isEmpty)
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

  String _getCaloriesForDuration(
    Map<String, dynamic> calories,
    dynamic duration,
  ) {
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
          minimumSize: const Size(double.infinity, 45),
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _entries.isEmpty ? 'ประวัติ' : 'ประวัติ (${_entries.length} ครั้ง)',
          style: TextStyle(color: primaryGreen),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                _ownerLabel,
                style: TextStyle(
                  color: primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      // Only allow viewing history when the user is logged-in and not a guest.
      body: (auth.isLoggedIn && !auth.isGuest)
          ? Column(
              children: [
                Expanded(
                  child: _entries.isEmpty
                      ? Center(
                          child: Text(
                            'ยังไม่มีการกรอกข้อมูล',
                            style: TextStyle(color: primaryGreen),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadHistory,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(18),
                            itemCount: _entries.length,
                            itemBuilder: (ctx, i) {
                              final entry = _entries[i];
                              final data =
                                  entry['data'] as Map<String, dynamic>? ?? {};

                              Map<String, dynamic> personal =
                                  data.containsKey('personal')
                                  ? parseToMap(data['personal'])
                                  : data;

                              Map<String, dynamic> calories =
                                  data.containsKey('calories')
                                  ? parseToMap(data['calories'])
                                  : {};

                              return Card(
                                color: Colors.grey.shade200,
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "ครั้งที่ ${i + 1}",
                                        style: TextStyle(
                                          color: primaryGreen,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // Show human-readable summary if present
                                      if (data.containsKey('summary') &&
                                          data['summary'] is String &&
                                          (data['summary'] as String).trim().isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 8),
                                          child: Text(
                                            data['summary'],
                                            style: TextStyle(color: primaryGreen),
                                          ),
                                        ),
                                      const SizedBox(height: 10),
                                      buildInfoRow("อายุ", personal['age']),
                                      buildInfoRow("เพศ", personal['gender']),
                                      buildInfoRow(
                                        "น้ำหนัก",
                                        personal['weight'],
                                      ),
                                      buildInfoRow(
                                        "ส่วนสูง",
                                        personal['height'],
                                      ),
                                      buildInfoRow(
                                        "รับ/วัน",
                                        calories['intake_per_day'],
                                      ),
                                      buildInfoRow(
                                        "ควรรับ/วัน",
                                        calories['recommended_per_day'],
                                      ),
                                      const SizedBox(height: 6),
                                      // Additional fields
                                      buildInfoRow(
                                        "ประเภทอาหาร",
                                        data.containsKey('selection')
                                            ? (data['selection'] is Map
                                                  ? (data['selection']['food_type'] ??
                                                        data['food_type'])
                                                  : data['food_type'])
                                            : (data['food_type'] ?? '-'),
                                      ),
                                      buildInfoRow(
                                        "หมวดที่เลือก",
                                        data.containsKey('selection')
                                            ? (data['selection'] is Map
                                                  ? (data['selection']['category'] ??
                                                        '-')
                                                  : '-')
                                            : '-',
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 6,
                                        ),
                                        child: Text(
                                          "เมนูตามหมวด: ${_joinList(data['menus'] ?? (data['selection'] is Map ? data['selection']['menu_options'] : null))}",
                                          style: TextStyle(color: primaryGreen),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 6,
                                        ),
                                        child: Text(
                                          "เมนูที่เลือก: ${_joinList(data['selected_menus'] ?? (data['selection'] is Map ? data['selection']['selected_menus'] : null))}",
                                          style: TextStyle(color: primaryGreen),
                                        ),
                                      ),
                                      buildInfoRow(
                                        "เมนูเครื่องดื่ม",
                                        _joinList(
                                          data['drink_options'] ??
                                              (data['selection'] is Map
                                                  ? data['selection']['drink_options']
                                                  : null),
                                        ),
                                      ),
                                      buildInfoRow(
                                        "เครื่องดื่มที่เลือก",
                                        _joinList(
                                          data['selected_drink'] ??
                                              (data['selection'] is Map
                                                  ? data['selection']['selected_drink']
                                                  : null),
                                        ),
                                      ),
                                      buildInfoRow(
                                        "มื้ออาหาร",
                                        data['meal'] ??
                                            (data['selection'] is Map
                                                ? data['selection']['meal']
                                                : '-'),
                                      ),
                                      buildInfoRow(
                                        "ระยะเวลา (วัน)",
                                        data['duration'] ??
                                            (data['selection'] is Map
                                                ? data['selection']['duration']
                                                : '-'),
                                      ),
                                      buildInfoRow(
                                        "สถานะ (BMI)",
                                        _computeBMIStatus(personal),
                                      ),
                                      buildInfoRow(
                                        "แคลอรีรวม (ช่วงที่เลือก)",
                                        _getCaloriesForDuration(
                                          calories,
                                          data['duration'] ??
                                              (data['selection'] is Map
                                                  ? data['selection']['duration']
                                                  : null),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 6,
                                        ),
                                        child: Text(
                                          "คำแนะนำ: ${data['recommendation'] ?? data['advice'] ?? data['notes'] ?? calories['advice'] ?? '-'}",
                                          style: TextStyle(color: primaryGreen),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 6,
                                        ),
                                        child: Text(
                                          "คำอธิบาย: ${data['description'] ?? data['explanation'] ?? '-'}",
                                          style: TextStyle(color: primaryGreen),
                                        ),
                                      ),
                                      // If backend stored a raw string in `data`, show it to the user
                                      if (data.containsKey('raw_data') &&
                                          (data['raw_data'] is String &&
                                              (data['raw_data'] as String)
                                                  .trim()
                                                  .isNotEmpty))
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: Text(
                                            'ข้อมูลที่บันทึก: ${data['raw_data']}',
                                            style: TextStyle(
                                              color: primaryGreen,
                                            ),
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: Text(
                    'ประวัติการใช้งานมีให้เฉพาะผู้ใช้ที่ล็อกอินเท่านั้น',
                    style: TextStyle(color: primaryGreen),
                    textAlign: TextAlign.center,
                  ),
                ),
                buildBackButton(),
              ],
            ),
    );
  }
}
