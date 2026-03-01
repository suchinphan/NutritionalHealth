import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import 'choose_food_type_page.dart';
import 'register_login_page.dart';

class PersonalInformationPage extends StatefulWidget {
  const PersonalInformationPage({Key? key}) : super(key: key);

  @override
  State<PersonalInformationPage> createState() =>
      _PersonalInformationPageState();
}

class _PersonalInformationPageState extends State<PersonalInformationPage> {
  final Color primaryGreen = const Color(0xFF00C700);
  // guest personal data stored in-memory via AuthService

  final TextEditingController genderController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController heightController = TextEditingController();

  String? _selectedGender;
  String? _selectedAge;
  String? _selectedWeight;
  String? _selectedHeight;

  // Inline validation error messages
  String? _genderError;
  String? _ageError;
  String? _weightError;
  String? _heightError;
  String? _bmiError;

  bool _saving = false;
  bool _authLoaded = false;

  // `_hasPersonalInfo` is computed from AuthService (single source of truth)
  bool get _hasPersonalInfo {
    final auth = AuthService();
    final Map<String, dynamic> p = auth.isGuest
        ? (auth.guestPersonal ?? <String, dynamic>{})
        : (auth.user ?? <String, dynamic>{});
    final g = (p['gender']?.toString() ?? '').trim();
    final a = (p['age']?.toString() ?? '').trim();
    final w = (p['weight']?.toString() ?? '').trim();
    final h = (p['height']?.toString() ?? '').trim();
    return g.isNotEmpty && a.isNotEmpty && w.isNotEmpty && h.isNotEmpty;
  }

  final List<String> _genderOptions = ['ชาย', 'หญิง'];
  // Options should be numeric-only (no units) so controllers store plain numbers
  final List<String> _ageOptions = List.generate(96, (i) => '${i + 5}');
  final List<String> _weightOptions = List.generate(200, (i) => '${i + 1}');
  final List<String> _heightOptions = List.generate(200, (i) => '${i + 1}');

  bool get guestUsedEffective => AuthService().guestUsed;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await _loadSavedUser();
    });
  }

  Future<void> _loadSavedUser() async {
    try {
      final auth = AuthService();
      await auth.loadToken();
      final u = auth.user;
      // If guest, try to load in-memory guest personal info
      if (auth.isGuest) {
        try {
          final parsed = auth.guestPersonal;
          if (parsed != null) {
            _selectedGender = parsed['gender']?.toString();
            _selectedAge = parsed['age']?.toString();
            _selectedWeight = parsed['weight']?.toString();
            _selectedHeight = parsed['height']?.toString();
            genderController.text = _selectedGender ?? '';
            ageController.text = _selectedAge ?? '';
            weightController.text = _selectedWeight ?? '';
            heightController.text = _selectedHeight ?? '';
          }
        } catch (_) {}
      }

      setState(() {
        if (u != null) {
          _selectedGender = u['gender']?.toString();
          _selectedAge = u['age']?.toString();
          _selectedWeight = u['weight']?.toString();
          _selectedHeight = u['height']?.toString();
          genderController.text = _selectedGender ?? '';
          ageController.text = _selectedAge ?? '';
          weightController.text = _selectedWeight ?? '';
          heightController.text = _selectedHeight ?? '';
          // `_hasPersonalInfo` is computed from AuthService; no manual assignment here.
        }
        _authLoaded = true;
      });
    } catch (_) {
      setState(() {
        _authLoaded = true;
      });
    }
  }

  Widget _dropdownField(
    String hint,
    String? value,
    List<String> items,
    ValueChanged<String?>? onChanged, {
    bool enabled = true,
    String? error,
  }) {
    final uniq = items.toSet().toList();
    String? safeInitial;
    if (value != null && uniq.where((e) => e == value).length == 1)
      safeInitial = value;
    return IgnorePointer(
      ignoring: !enabled,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.6,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            value: safeInitial,
            hint: Text(hint, overflow: TextOverflow.ellipsis, maxLines: 1),
            decoration: InputDecoration(
              border: OutlineInputBorder(borderSide: BorderSide.none),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              filled: true,
              fillColor: Colors.grey[300],
              errorText: error,
            ),
            items: uniq
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
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  bool _validateAll() {
    _genderError = null;
    _ageError = null;
    _weightError = null;
    _heightError = null;
    _bmiError = null;

    final sg = genderController.text.trim();
    final sa = ageController.text.trim();
    final sw = weightController.text.trim();
    final sh = heightController.text.trim();

    if (sg.isEmpty) _genderError = 'กรุณาเลือกเพศ';
    if (sa.isEmpty) _ageError = 'กรุณาเลือกอายุ';
    if (sw.isEmpty) _weightError = 'กรุณาเลือกน้ำหนัก';
    if (sh.isEmpty) _heightError = 'กรุณาเลือกส่วนสูง';

    final age = int.tryParse(sa);
    final weight = int.tryParse(sw);
    final height = int.tryParse(sh);

    if (sa.isNotEmpty && age == null) _ageError = 'ข้อมูลอายุไม่ถูกต้อง';
    if (sw.isNotEmpty && weight == null)
      _weightError = 'ข้อมูลน้ำหนักไม่ถูกต้อง';
    if (sh.isNotEmpty && height == null)
      _heightError = 'ข้อมูลส่วนสูงไม่ถูกต้อง';

    if (age != null) {
      if (age < 5 || age > 100) _ageError = 'อายุต้องอยู่ระหว่าง 5 - 100 ปี';
    }
    if (weight != null) {
      if (weight < 1 || weight > 200)
        _weightError = 'น้ำหนักต้องอยู่ระหว่าง 1 - 200 กก.';
    }
    if (height != null) {
      if (height < 1 || height > 250)
        _heightError = 'ส่วนสูงต้องอยู่ระหว่าง 1 - 250 ซม.';
    }

    if (age != null && height != null && age < 10 && height < 80)
      _heightError = 'ส่วนสูงน้อยเกินไปสำหรับอายุ';
    if (age != null && weight != null && age < 10 && weight > 50)
      _weightError = 'น้ำหนักมากเกินไปสำหรับอายุ';

    if (weight != null && height != null) {
      final double bmi = weight / ((height / 100) * (height / 100));
      if (bmi.isNaN || bmi < 6 || bmi > 60) {
        _bmiError =
            'ดัชนีมวลกาย (BMI) ผิดปกติ: ${bmi.isFinite ? bmi.toStringAsFixed(1) : 'ไม่ทราบ'}';
      }
    }

    setState(() {});

    return _genderError != null ||
        _ageError != null ||
        _weightError != null ||
        _heightError != null ||
        _bmiError != null;
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6.0),
    child: Text(
      text,
      style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w600),
    ),
  );

  Future<void> _onNext() async {
    final auth = AuthService();
    // Block only if guest has already used their one-time submission
    if (auth.isGuestLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถแก้ไขข้อมูลได้อีก')),
      );
      return;
    }

    // Validate based on controllers (single source of truth for this page)
    final sg = genderController.text.trim();
    final sa = ageController.text.trim();
    final sw = weightController.text.trim();
    final sh = heightController.text.trim();

    // Run full validation and block if any inline errors exist
    if (_validateAll()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'พบค่าที่ผิดปกติ/ไม่ครบถ้วน โปรดตรวจสอบก่อนดำเนินการต่อ',
          ),
        ),
      );
      return;
    }
    debugPrint(
      'Before _onNext save: gender=$sg age=$sa weight=$sw height=$sh _hasPersonalInfo=$_hasPersonalInfo',
    );
    if (sg.isEmpty || sa.isEmpty || sw.isEmpty || sh.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกข้อมูลให้ครบถ้วน')),
      );
      return;
    }
    if (_saving) return;

    final age = int.tryParse(sa.split(' ').first);
    final weight = int.tryParse(sw.split(' ').first);
    final height = int.tryParse(sh.split(' ').first);
    if (age == null || weight == null || height == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ข้อมูลไม่ถูกต้อง')));
      return;
    }

    if (age < 5 ||
        age > 100 ||
        weight < 1 ||
        weight > 200 ||
        height < 1 ||
        height > 250) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาใส่ค่าภายในช่วงที่กำหนด')),
      );
      return;
    }

    final double bmi = weight / ((height / 100) * (height / 100));
    final List<String> reasons = [];
    if (age < 10 && height < 80) reasons.add('ส่วนสูงน้อยเกินไปสำหรับอายุ');
    if (age < 10 && weight > 50) reasons.add('น้ำหนักมากเกินไปสำหรับอายุ');
    if (bmi.isNaN || bmi < 6 || bmi > 60)
      reasons.add(
        'ดัชนีมวลกาย (BMI) ผิดปกติ: ${bmi.isFinite ? bmi.toStringAsFixed(1) : 'ไม่ทราบ'}',
      );

    if (reasons.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('ข้อมูลอาจผิดปกติ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('พบค่าที่น่าจะผิดปกติ/เป็นไปได้ยาก โปรดตรวจสอบ:'),
              const SizedBox(height: 8),
              ...reasons.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text('- $r'),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'ระบบจะไม่อนุญาตให้ไปหน้าถัดไปจนกว่าจะแก้ไขข้อมูลให้ถูกต้อง',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('กลับไปแก้ไข'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    // Prepare merged data for background save
    Map<String, dynamic>? mergedUser;
    Map<String, dynamic>? mergedGuest;

    if (!auth.isLoggedIn) {
      if (!auth.isGuest) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const RegisterLoginPage()),
        );
        return;
      }
      mergedGuest = <String, dynamic>{
        'gender': sg,
        'age': sa,
        'weight': sw,
        'height': sh,
      };
    } else {
      final existing = auth.user ?? {};
      mergedUser = Map<String, dynamic>.from(existing);
      mergedUser['gender'] = sg;
      mergedUser['age'] = sa;
      mergedUser['weight'] = sw;
      mergedUser['height'] = sh;
    }

    if (!mounted) return;

    // Navigate immediately; perform saves in background (fire-and-forget)
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ChooseFoodTypePage()),
    );

    try {
      if (mergedUser != null) {
        auth.saveUser(mergedUser);
      } else if (mergedGuest != null) {
        auth.saveGuestPersonal(mergedGuest);
        auth.markGuestUsed();
      }
    } catch (e) {
      // swallow background errors; optionally log
      if (kDebugMode) print('Background save error: $e');
    }
  }

  void _goNextViewOnly() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'ไม่สามารถแก้ไขข้อมูลได้อีก',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 1),
      ),
    );
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted)
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ChooseFoodTypePage()),
        );
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    // Only perform logout redirect when the session is neither a logged-in
    // user nor a Guest. This prevents spurious logout when storage marks a
    // Guest but in-memory state is still initializing.
    if (!auth.isGuest && !auth.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => RegisterLoginPage()),
          (route) => false,
        );
      });
      return const SizedBox.shrink();
    }
    if (!_authLoaded) {
      Future.microtask(() async {
        await _loadSavedUser();
        if (mounted) setState(() {});
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bool canEdit = auth.isLoggedIn ? true : !auth.isGuestLocked;
    debugPrint(
      'PersonalInformationPage build: isGuest=${auth.isGuest} guestUsed=${auth.guestUsed} isGuestLocked=${auth.isGuestLocked} _hasPersonalInfo=$_hasPersonalInfo canEdit=$canEdit',
    );
    debugPrint(
      'controllers: gender=${genderController.text} age=${ageController.text} weight=${weightController.text} height=${heightController.text}',
    );

    final bool hasValidationErrors =
        _genderError != null ||
        _ageError != null ||
        _weightError != null ||
        _heightError != null ||
        _bmiError != null;

    String idText = '';
    if (auth.isLoggedIn && auth.user != null) {
      final uname =
          auth.user!['username'] ??
          auth.user!['name'] ??
          (auth.user!['id']?.toString() ?? '—');
      idText = uname;
    } else if (auth.isGuest) {
      idText = 'Guest';
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icon(Icons.arrow_back, color: primaryGreen),
        ),
        title: Text('กรอกข้อมูลส่วนตัว', style: TextStyle(color: primaryGreen)),
        actions: [
          if (idText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Center(
                child: Text(idText, style: TextStyle(color: primaryGreen)),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _label('เพศ'),
            const SizedBox(height: 6),
            _dropdownField(
              'ระบุเพศ (ชาย - หญิง)',
              _selectedGender,
              _genderOptions,
              canEdit
                  ? (v) => setState(() {
                      _selectedGender = v;
                      genderController.text = v ?? '';
                      _genderError = null;
                      _validateAll();
                    })
                  : null,
              enabled: canEdit,
              error: _genderError,
            ),
            const SizedBox(height: 12),
            _label('อายุ'),
            _dropdownField(
              'ระบุอายุตั้งแต่ (5 - 100 ปี)',
              _selectedAge,
              _ageOptions,
              canEdit
                  ? (v) => setState(() {
                      _selectedAge = v;
                      ageController.text = v ?? '';
                      _ageError = null;
                      _validateAll();
                    })
                  : null,
              enabled: canEdit,
              error: _ageError,
            ),
            const SizedBox(height: 12),
            _label('น้ำหนัก'),
            _dropdownField(
              'ระบุน้ำหนักตั้งแต่ (1 - 200 กิโลกรัม)',
              _selectedWeight,
              _weightOptions,
              canEdit
                  ? (v) => setState(() {
                      _selectedWeight = v;
                      weightController.text = v ?? '';
                      _weightError = null;
                      _validateAll();
                    })
                  : null,
              enabled: canEdit,
              error: _weightError,
            ),
            const SizedBox(height: 12),
            _label('ส่วนสูง'),
            _dropdownField(
              'ระบุส่วนสูงตั้งแต่ (1 - 250 เซนติเมตร)',
              _selectedHeight,
              _heightOptions,
              canEdit
                  ? (v) => setState(() {
                      _selectedHeight = v;
                      heightController.text = v ?? '';
                      _heightError = null;
                      _validateAll();
                    })
                  : null,
              enabled: canEdit,
              error: _heightError,
            ),
            if (_bmiError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(_bmiError!, style: TextStyle(color: Colors.red)),
              ),
            const Spacer(),
            if (auth.isGuestLocked)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'ไม่สามารถกรอกข้อมูลได้อีก',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _saving
                    ? null
                    : auth.isGuestLocked
                    ? _goNextViewOnly
                    : (hasValidationErrors ? null : _onNext),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'หน้าถัดไป',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
