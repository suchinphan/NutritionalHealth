import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'page/class_food_page.dart';
import 'page/menu_food_page.dart';
import 'page/personal_information_page.dart';
import 'page/history_page.dart';
import 'page/report_problem_page.dart';
// unused page imports removed (analyzer flagged unused_import)
import 'page/register_login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthService();
  await auth.loadToken();
  runApp(ChangeNotifierProvider.value(value: auth, child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        return MaterialApp(
          title: 'Nutrition App',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.green,
          ),
          home: _decideStartPage(auth),
        );
      },
    );
  }

  Widget _decideStartPage(AuthService auth) {
    if (auth.isGuest) {
      return const MainScreen();
    }

    if (auth.token != null && auth.token!.isNotEmpty) {
      return const MainScreen();
    }

    return RegisterLoginPage();
  }
}



class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final Color accentGreen = const Color(0xFF00C700);
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<Map<String, dynamic>> _suggestions = [];

  // รายการหมวดหมู่สำหรับค้นหา (label ต้องตรงกับคำที่ผู้ใช้จะพิมพ์)
    final List<Map<String, dynamic>> _categories = [
    {'label': 'คลาสอาหาร', 'page': ClassFoodPage(), 'asset': 'assets/images/คลาสอาหาร.jpg'},
    {'label': 'เมนูอาหาร', 'page': MenuFoodPage(), 'asset': 'assets/images/เมนูอาหาร.jpg'},
    {'label': 'กรอกข้อมูลส่วนบุคคล', 'page': PersonalInformationPage(), 'asset': 'assets/images/การกรอกข้อมูล.jpg'},
    {'label': 'ประวัติการกรอกข้อมูล', 'page': HistoryPage(), 'asset': 'assets/images/ประวัติการกรอกข้อมูล.png'},
    {'label': 'รายงานปัญหา', 'page': ReportProblemPage(), 'asset': 'assets/images/รายงานปัญหา.png'},
    // 'อื่นๆ' category removed
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาพิมพ์คำที่ต้องการค้นหา')));
      return;
    }
    final matches = _categories.where((c) => (c['label'] as String).toLowerCase().contains(q)).toList();
    if (matches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ไม่พบผลการค้นหา')));
      setState(() => _suggestions = []);
      return;
    }
    // If exactly one match, navigate directly
    if (matches.length == 1) {
      final page = matches.first['page'];
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
      setState(() => _suggestions = []);
      return;
    }
    // Multiple matches -> show choices in a bottom sheet
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView.separated(
        padding: const EdgeInsets.all(8),
        itemBuilder: (_, i) {
          final c = matches[i];
          final label = c['label'] as String;
          final asset = c['asset'] as String?;
          return ListTile(
            leading: asset != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(asset, width: 44, height: 44, fit: BoxFit.cover, errorBuilder: (ctx, err, st) => Icon(Icons.image, color: accentGreen)),
                  )
                : Icon(Icons.folder, color: accentGreen),
            title: Text(label),
              onTap: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => c['page']));
            },
          );
        },
        separatorBuilder: (_, __) => const Divider(),
        itemCount: matches.length,
      ),
    );
    setState(() => _suggestions = matches.take(5).toList());
  }

  void _updateSuggestions(String input) {
    final q = input.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    final matches = _categories.where((c) => (c['label'] as String).toLowerCase().contains(q)).toList();
    setState(() => _suggestions = matches.take(5).toList());
  }

  Widget categoryItem(IconData icon, String label, {String? assetPath, VoidCallback? onTap}) {
    // Responsive image + label that shrinks on narrow cells to avoid overflow
    return LayoutBuilder(builder: (ctx, constraints) {
      final maxW = constraints.maxWidth.isFinite && constraints.maxWidth > 0 ? constraints.maxWidth : MediaQuery.of(ctx).size.width / 2;
      // Ensure image fits within the available tile height to avoid vertical overflow
      final availH = constraints.maxHeight.isFinite && constraints.maxHeight > 0 ? constraints.maxHeight : double.infinity;
      final baseImg = (maxW * 0.5).clamp(24.0, 56.0);
      final maxImgByHeight = (availH - 22.0).clamp(24.0, 56.0);
      final imgSize = math.min(baseImg, maxImgByHeight);

      final imageBox = Container(
        width: imgSize,
        height: imgSize,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: assetPath != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    assetPath,
                    fit: BoxFit.cover,
                    width: imgSize,
                    height: imgSize,
                    errorBuilder: (c, e, s) => Icon(icon, size: imgSize * 0.5, color: accentGreen),
                  ),
                )
              : Icon(icon, size: imgSize * 0.5, color: accentGreen),
        ),
      );

      final imageWidget = onTap != null
          ? InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8), child: imageBox)
          : imageBox;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: imgSize, height: imgSize, child: imageWidget),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: SizedBox(
              width: double.infinity,
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF00C700), fontSize: 12),
              ),
            ),
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    // If user is not a guest and not logged in, force return to login screen
    if (!auth.isGuest && (auth.token == null || auth.token!.isEmpty)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => RegisterLoginPage()),
          (route) => false,
        );
      });
      return const SizedBox.shrink();
    }
    return Scaffold(
      // background to match screenshot (mostly white)
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top row with optional spacer and User ID on right (tappable -> Login)
              Row(
                children: [
                  const Spacer(),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      final auth = Provider.of<AuthService>(context, listen: false);
                      if (value == 'logout') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('ยืนยัน'),
                            content: const Text('คุณต้องการออกจากระบบหรือไม่?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('ไม่')), 
                              TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('ใช่')),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await auth.clearToken(force: true);
                          if (!context.mounted) return;
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => RegisterLoginPage()),
                            (route) => false,
                          );
                        }
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'logout', child: Text('ออกจากระบบ')),
                    ],
                    child: Consumer<AuthService>(
                      builder: (ctx, auth, _) {
                        final style = TextStyle(color: accentGreen, fontWeight: FontWeight.bold);
                        if (auth.isGuest) return Text('Guest', style: style);
                        final u = auth.user;
                        if (u != null) {
                          final username = u['username'] ?? u['user'] ?? u['name'] ?? u['email'];
                          if (username != null && username.toString().isNotEmpty) {
                            return Text(username.toString(), style: style);
                          }
                          final id = u['id'] ?? u['user_id'];
                          if (id != null) return Text('User $id', style: style);
                        }
                        return Text('User ID', style: style);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Search box (controller + onSubmitted)
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        focusNode: _searchFocus,
                          enabled: !auth.isGuestLocked,
                        decoration: const InputDecoration(
                          hintText: 'ค้นหา....',
                          border: InputBorder.none,
                          isCollapsed: true,
                        ),
                        onSubmitted: _performSearch,
                        onChanged: _updateSuggestions,
                      ),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.search, size: 20),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              // Suggestions list shown while typing (constrained height to avoid overflow)
              if (_suggestions.isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)]),
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      children: _suggestions.map((c) {
                        final label = c['label'] as String;
                        final asset = c['asset'] as String?;
                        return ListTile(
                          leading: asset != null
                              ? ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.asset(asset, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (ctx, err, st) => Icon(Icons.image, color: accentGreen)))
                              : Icon(Icons.folder, color: accentGreen),
                          title: Text(label, style: const TextStyle(fontSize: 14)),
                          onTap: () {
                            FocusScope.of(context).unfocus();
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => c['page']));
                            setState(() => _suggestions = []);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
              // Title
              Center(
                child: Text(
                  'หมวดหมู่ทั้งหมด',
                  style: TextStyle(color: accentGreen, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 6),
              // (removed top thumbnail strip; images are shown inside each category tile)
              const SizedBox(height: 12),
              // Grid of categories (responsive columns) -- expanded to fill remaining space
              Expanded(
                child: LayoutBuilder(builder: (ctx, constraints) {
                  final maxWidth = constraints.maxWidth;
                  // Desired approximate tile width (adjust to taste)
                  const double desiredTileW = 160.0;
                  // Use simple breakpoints so the grid doesn't spread too wide on large screens.
                  // - phone / narrow: 2 columns
                  // - tablet / medium: 3 columns
                  // - large desktop: also 3 columns (kept intentionally limited)
                  int crossAxis;
                  if (maxWidth <= 420) {
                    crossAxis = 2;
                  } else if (maxWidth <= 900) {
                    crossAxis = 3;
                  } else {
                    crossAxis = 3; // cap to 3 to avoid full-width spreading
                  }

                  // Build category widgets list
                  final categoryWidgets = [
                    categoryItem(
                      Icons.restaurant_menu,
                      'คลาสอาหาร',
                      assetPath: 'assets/images/คลาสอาหาร.jpg',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ClassFoodPage())),
                    ),
                    categoryItem(
                      Icons.menu_book,
                      'เมนูอาหาร',
                      assetPath: 'assets/images/เมนูอาหาร.jpg',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MenuFoodPage())),
                    ),
                    categoryItem(
                      Icons.assignment_ind,
                      'กรอกข้อมูลส่วนบุคคล',
                      assetPath: 'assets/images/การกรอกข้อมูล.jpg',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PersonalInformationPage())),
                    ),
                    categoryItem(
                      Icons.receipt_long,
                      'ประวัติการกรอกข้อมูล',
                      assetPath: 'assets/images/ประวัติการกรอกข้อมูล.png',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => HistoryPage())),
                    ),
                    categoryItem(
                      Icons.report_problem,
                      'รายงานปัญหา',
                      assetPath: 'assets/images/รายงานปัญหา.png',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReportProblemPage())),
                    ),
                  ];

                  // Constrain the grid's maximum width so tiles don't spread too far on very large screens
                  final gridMaxWidth = (crossAxis * desiredTileW) + ((crossAxis - 1) * 12) + 32;

                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: gridMaxWidth),
                      child: GridView.count(
                        shrinkWrap: false,
                        crossAxisCount: crossAxis,
                        childAspectRatio: 1.0,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        padding: const EdgeInsets.only(bottom: 80, left: 6, right: 6),
                        children: categoryWidgets,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 64,
        color: accentGreen,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.home, '', onTap: () {
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => MainScreen()));
            }),
            _navItem(Icons.search, '', onTap: () {
              FocusScope.of(context).requestFocus(_searchFocus);
            }),
            _navItem(Icons.menu, '', onTap: () {
              _showAllCategories();
            }),
          ],
        ),
      ),
    );
  }

  void _showAllCategories() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.25,
        maxChildSize: 0.9,
        builder: (sheetCtx, scrollController) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Text('หมวดหมู่ทั้งหมด', style: TextStyle(color: accentGreen, fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: GridView.count(
                      controller: scrollController,
                      crossAxisCount: 2,
                      childAspectRatio: 2.2,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      children: _categories.map((c) {
                        final label = c['label'] as String;
                        final asset = c['asset'] as String?;
                        final page = c['page'];
                        return categoryItem(
                          Icons.category,
                          label,
                          assetPath: asset,
                          onTap: () {
                            Navigator.of(ctx).pop();
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Removed unused helper thumbnail to reduce unused_element warning.

  Widget _navItem(IconData icon, String label, {VoidCallback? onTap}) {
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white, size: 26),
        if (label.isNotEmpty)
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
      ],
    );

    if (onTap != null) {
      return InkWell(onTap: onTap, child: content);
    }
    return content;
  }
}
