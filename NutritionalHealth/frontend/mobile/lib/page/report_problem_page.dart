import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

class ReportProblemPage extends StatefulWidget {
  const ReportProblemPage({super.key});

  @override
  State<ReportProblemPage> createState() => _ReportProblemPageState();
}

class _ReportProblemPageState extends State<ReportProblemPage> {
  final Color primaryGreen = const Color(0xFF00C700);
  bool _systemIssue = false;
  bool _userIssue = false;
  final TextEditingController _detailController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
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
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).maybePop(),
                        child: Icon(Icons.arrow_back, color: primaryGreen, size: 30),
                      ),
                      const Expanded(child: SizedBox()),
                      Text('รายงานปัญหา',
                          style: TextStyle(color: primaryGreen, fontSize: 18, fontWeight: FontWeight.w700)),
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
                    children: [
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Checkbox(
                            value: _systemIssue,
                            onChanged: AuthService().isGuestLocked ? null : (v) => setState(() => _systemIssue = v ?? false),
                          ),
                          const SizedBox(width: 8),
                          Text('ปัญหาระบบ', style: TextStyle(color: primaryGreen, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Checkbox(
                            value: _userIssue,
                            onChanged: AuthService().isGuestLocked ? null : (v) => setState(() => _userIssue = v ?? false),
                          ),
                          const SizedBox(width: 8),
                          Text('ปัญหาผู้ใช้', style: TextStyle(color: primaryGreen, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 18),
                      // Detail box
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.black45, width: 1),
                        ),
                        padding: const EdgeInsets.all(8),
                          child: TextField(
                          controller: _detailController,
                          enabled: !AuthService().isGuestLocked,
                          maxLines: 6,
                          decoration: InputDecoration(
                            hintText: 'กรอกข้อมูลปัญหา',
                            hintStyle: TextStyle(color: Colors.grey[700]),
                            border: InputBorder.none,
                            isCollapsed: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Center(
                        child: SizedBox(
                          width: 160,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: _sending || AuthService().isGuest
                              ? null
                              : () async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    final navigator = Navigator.of(context);
                                    final auth = AuthService();
                                    await auth.loadToken();
                                    final detail = _detailController.text.trim();
                                    if (!_systemIssue && !_userIssue && detail.isEmpty) {
                                      if (!mounted) return;
                                      messenger.showSnackBar(const SnackBar(content: Text('กรุณาเลือกประเภทหรือกรอกรายละเอียด')));
                                      return;
                                    }
                                    setState(() => _sending = true);
                                    final type = _systemIssue ? 'system' : (_userIssue ? 'user' : 'other');
                                    final String apiBase = kIsWeb
                                        ? 'http://127.0.0.1:5000'
                                        : (defaultTargetPlatform == TargetPlatform.android ? 'http://10.0.2.2:5000' : 'http://127.0.0.1:5000');
                                    final url = Uri.parse('$apiBase/report');
                                    final payload = <String, dynamic>{'type': type, 'detail': detail};
                                    // attach user id if logged in
                                    Map<String, String> headers = {'Content-Type': 'application/json'};
                                    if (auth.isLoggedIn && auth.user != null) {
                                      final uid = auth.user!['id'] ?? auth.user!['user_id'];
                                      payload['user_id'] = uid;
                                      if (auth.token != null) headers['Authorization'] = 'Bearer ${auth.token}';
                                    } else if (auth.isGuest) {
                                      // include anon id in detail to help admin trace
                                      await auth.ensureAnonId();
                                      final a = auth.anonId;
                                      if (a != null && a.isNotEmpty) payload['detail'] = 'Anon:$a\n' + payload['detail'];
                                    }

                                    try {
                                      final resp = await http.post(url, headers: headers, body: jsonEncode(payload));
                                      if (resp.statusCode >= 200 && resp.statusCode < 300) {
                                        if (!mounted) return;
                                        messenger.showSnackBar(const SnackBar(content: Text('รายงานเรียบร้อย')));
                                        navigator.maybePop();
                                      } else if (resp.statusCode == 401) {
                                        if (!mounted) return;
                                        messenger.showSnackBar(const SnackBar(content: Text('ต้องเข้าสู่ระบบก่อนส่งรายงาน')));
                                      } else {
                                        String msg = 'เกิดข้อผิดพลาด';
                                        try {
                                          final j = jsonDecode(resp.body);
                                          if (j is Map && j['error'] != null) msg = j['error'].toString();
                                        } catch (_) {}
                                        if (!mounted) return;
                                        messenger.showSnackBar(SnackBar(content: Text('ไม่สามารถส่งรายงาน: $msg')));
                                      }
                                    } catch (e) {
                                      if (!mounted) return;
                                      messenger.showSnackBar(const SnackBar(content: Text('ไม่สามารถติดต่อเซิร์ฟเวอร์')));
                                    } finally {
                                      setState(() => _sending = false);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              elevation: 0,
                            ),
                            child: _sending ? const CircularProgressIndicator(color: Colors.white) : const Text('รายงาน', style: TextStyle(color: Colors.white)),
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
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.home, color: Colors.white),
            ),
            IconButton(onPressed: () {}, icon: const Icon(Icons.search, color: Colors.white)),
            IconButton(onPressed: () {}, icon: const Icon(Icons.list_alt, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
