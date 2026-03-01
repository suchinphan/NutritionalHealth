import 'dart:io';
import 'dart:convert';

class CsvLoader {
  // Lightweight model for food rows when using strict Thai CSV format
  // Index mapping expected by the new format:
  // 0 = ชื่ออาหาร
  // 1 = หมวดหมู่
  // 2 = พลังงาน(กิโลแคลอรี)
  // 3 = โปรตีน(กรัม)
  // 4 = คาร์โบไฮเดรต(กรัม)
  // 5 = ไขมัน(กรัม)

  // Use this model when loading strict CSVs per user request
  static FoodItem _foodItemFromRow(List<String> row, Map<String, int> idx) {
    String name = (idx['name'] != null && idx['name']! < row.length)
        ? row[idx['name']!].trim()
        : '';
    String category = (idx['category'] != null && idx['category']! < row.length)
        ? row[idx['category']!].trim()
        : '';
    double kcal = 0.0;
    double protein = 0.0;
    double carbs = 0.0;
    double fat = 0.0;
    try {
      if (idx['kcal'] != null && idx['kcal']! < row.length)
        kcal =
            double.tryParse(row[idx['kcal']!].replaceAll('"', '').trim()) ??
            0.0;
    } catch (_) {}
    try {
      if (idx['protein'] != null && idx['protein']! < row.length)
        protein =
            double.tryParse(row[idx['protein']!].replaceAll('"', '').trim()) ??
            0.0;
    } catch (_) {}
    try {
      if (idx['carbs'] != null && idx['carbs']! < row.length)
        carbs =
            double.tryParse(row[idx['carbs']!].replaceAll('"', '').trim()) ??
            0.0;
    } catch (_) {}
    try {
      if (idx['fat'] != null && idx['fat']! < row.length)
        fat =
            double.tryParse(row[idx['fat']!].replaceAll('"', '').trim()) ?? 0.0;
    } catch (_) {}
    return FoodItem(
      name: name,
      category: category,
      kcal: kcal,
      protein: protein,
      carbs: carbs,
      fat: fat,
    );
  }

  // normalize strings: trim, lowercase, remove whitespace and invisible chars
  static String _normalize(String s) {
    if (s == null) return '';
    return s
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll('\u200b', '')
        .replaceAll('\u00a0', '');
  }

  // Map common English CSV category values (USDA-like) to Thai app categories
  static String _englishCategoryToThai(String src) {
    if (src == null) return '';
    final v = src.toString().toLowerCase();
    if (v.isEmpty) return '';
    // protein-like
    final protTokens = [
      'meat',
      'chicken',
      'beef',
      'pork',
      'seafood',
      'fish',
      'egg',
      'dairy',
      'cheese',
      'protein',
      'poultry',
    ];
    for (var t in protTokens) {
      if (v.contains(t)) return 'เมนูโปรตีน';
    }
    // veg/fruit-like
    final vegTokens = [
      'vegetable',
      'vegetables',
      'fruit',
      'fruits',
      'apple',
      'banana',
      'berry',
      'salad',
      'produce',
    ];
    for (var t in vegTokens) {
      if (v.contains(t)) return 'เมนูผักและผลไม้';
    }
    // carb-like
    final carbTokens = [
      'rice',
      'noodle',
      'noodles',
      'pasta',
      'bread',
      'cereal',
      'grain',
      'potato',
      'starch',
      'mixed dishes',
    ];
    for (var t in carbTokens) {
      if (v.contains(t)) return 'เมนูคาร์โบไฮเดรต';
    }
    // beverages -> treat as high-energy food bucket or carbs depending on context
    final bevTokens = [
      'beverage',
      'beverages',
      'drink',
      'drinks',
      'juice',
      'tea',
      'coffee',
    ];
    for (var t in bevTokens) {
      if (v.contains(t)) return 'อาหารให้พลังงานสูง';
    }
    // fallback mappings for some USDA categories
    if (v.contains('dairy') || v.contains('egg')) return 'เมนูโปรตีน';
    if (v.contains('soup')) return 'เมนูผักและผลไม้';
    // if nothing matched, return original trimmed (could be Thai already)
    return src.toString().trim();
  }

  /// Load the CSV content by trying the Flutter asset first (assets/csv/)
  /// then falling back to the repository path `../../backend/data/filename` (replace `filename` with the actual file name)
  static Future<String> _loadRaw(String filename) async {
    // CSV asset loading disabled. Use backend API instead.
    throw Exception(
      'CsvLoader._loadRaw disabled; use ApiLoader to fetch data from backend API',
    );
    // Intentionally disabled: do not read CSV files from Flutter app.
    // Consumers should use `ApiLoader` which fetches from backend endpoints.
    throw Exception('CsvLoader disabled: use ApiLoader');
  }

  /// Parse and return unique non-empty values from the first column of the CSV
  static Future<List<String>> loadFirstColumn(
    String filename, {
    int max = 200,
  }) async {
    final raw = await _loadRaw(filename);
    final lines = raw.split(RegExp(r'\r?\n'));
    final rows = <List<String>>[];
    for (var line in lines) {
      if (line.trim().isEmpty) continue;
      // robust split handling quoted fields
      final parts = _splitCsvLine(
        line,
      ).map((s) => s.replaceAll('"', '').trim()).toList();
      if (parts.isEmpty) continue;
      rows.add(parts);
    }
    if (rows.isEmpty) return [];

    // Heuristic: choose the column that looks most like text (contains letters)
    final sampleCount = rows.length < 10 ? rows.length : 10;
    final colCount = rows
        .map((r) => r.length)
        .fold<int>(0, (p, e) => e > p ? e : p);
    final scores = List<int>.filled(colCount, 0);
    final letterRegex = RegExp(r'[A-Za-z\u0E00-\u0E7F]'); // includes Thai range
    for (var i = 0; i < sampleCount; i++) {
      final r = rows[i];
      for (var c = 0; c < r.length; c++) {
        if (letterRegex.hasMatch(r[c])) scores[c]++;
      }
    }
    // choose column with max score
    var bestCol = 0;
    var bestScore = -1;
    for (var c = 0; c < scores.length; c++) {
      if (scores[c] > bestScore) {
        bestScore = scores[c];
        bestCol = c;
      }
    }

    // Collect unique non-empty values from chosen column
    final seen = <String>{};
    final out = <String>[];
    for (var r in rows) {
      if (bestCol >= r.length) continue;
      var val = r[bestCol].trim();
      if (val.isEmpty) continue;
      if (!seen.contains(val)) {
        seen.add(val);
        out.add(val);
        if (out.length >= max) break;
      }
    }
    try {
      print('[CsvLoader] loadFirstColumn count=${out.length}');
    } catch (_) {}
    return out;
  }

  /// List all CSV files under backend/data (recursive), returning paths
  static Future<List<String>> listBackendCsvFiles() async {
    final repoPath = Directory.current.path;
    final base = Directory('$repoPath/../../backend/data');
    if (!await base.exists()) return [];
    final files = <String>[];
    await for (var entity in base.list(recursive: true, followLinks: false)) {
      if (entity is File && entity.path.toLowerCase().endsWith('.csv')) {
        // return path relative to backend/data
        final rel = entity.path
            .substring(base.path.length + 1)
            .replaceAll('\\', '/');
        files.add(rel);
      }
    }
    return files;
  }

  /// Load a CSV and return header (if present) and all rows as List<List<String>>
  static Future<Map<String, dynamic>> loadCsvRows(String filename) async {
    final raw = await _loadRaw(filename);
    final lines = raw.split(RegExp(r'\r?\n'));
    final rows = <List<String>>[];
    for (var line in lines) {
      if (line.trim().isEmpty) continue;
      final parts = _splitCsvLine(
        line,
      ).map((s) => s.replaceAll('"', '').trim()).toList();
      rows.add(parts);
    }
    String? header;
    if (rows.isNotEmpty) {
      // check if first row looks like header (has non-numeric tokens)
      final first = rows.first;
      final allAlpha = first
          .where((c) => c.isNotEmpty)
          .every((c) => RegExp(r'[A-Za-z\u0E00-\u0E7F]').hasMatch(c));
      if (allAlpha) {
        header = first.join(',');
        rows.removeAt(0);
        // debug: print header/first row lengths for parser validation
        try {
          print(
            '[CsvLoader] loadCsvRows headerCols=${_splitCsvLine(header).length} rowsParsed=${rows.length}',
          );
          if (rows.isNotEmpty)
            print('[CsvLoader] loadCsvRows firstRowCols=${rows.first.length}');
        } catch (_) {}
      }
    }
    return {'header': header, 'rows': rows};
  }

  /// Load all CSVs and build a categorized map.
  /// Result: a map from filename -> (categoryKey -> list of items).
  /// Heuristics: if header contains category-like column name, use it; otherwise choose text-like column as item name and place under filename key.
  static Future<Map<String, Map<String, List<String>>>>
  loadAllCategorized() async {
    final result = <String, Map<String, List<String>>>{};
    // Load optional custom tags mapping from backend/data/custom_tags.csv
    final customTags = <String, Map<String, List<String>>>{};
    try {
      final raw = await _loadRaw('custom_tags.csv');
      final lines = raw.split(RegExp(r'\r?\n'));
      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        final parts = line.split(',');
        if (parts.length < 3) continue;
        final src = parts[0].trim().replaceAll('\\', '/');
        final item = parts[1].trim();
        final tags = parts.sublist(2).join(',').trim();
        if (item.isEmpty || tags.isEmpty) continue;
        customTags
            .putIfAbsent(src, () => {})
            .putIfAbsent(item, () => [])
            .addAll(
              tags.split(';').map((s) => s.trim()).where((s) => s.isNotEmpty),
            );
      }
    } catch (_) {}
    // Prefer a single master CSV if available in assets or backend data
    try {
      final masterInfo = await loadCsvRows('master_foods.csv');
      final header = masterInfo['header'] as String?;
      final rows = masterInfo['rows'] as List<List<String>>;
      if (rows.isNotEmpty) {
        // treat master as one file source and attempt to map rows into app-friendly categories
        final map = <String, List<String>>{};
        // Prefer a meaningful name-like header if present
        int itemCol = 0;
        if (header != null) {
          final headers = _splitCsvLine(
            header,
          ).map((s) => s.trim().toLowerCase()).toList();
          final prefer = [
            'en_name',
            'th_name',
            'name',
            'food',
            'title',
            'item',
            'ชื่อ',
            'อาหาร',
            'name_en',
            'food_name',
            'description',
          ];
          int found = -1;
          for (var p in prefer) {
            final idx = headers.indexWhere((h) => h == p || h.contains(p));
            if (idx >= 0) {
              found = idx;
              break;
            }
          }
          if (found >= 0) itemCol = found;
        }
        // fallback: choose the most text-like column while avoiding numeric-heavy columns
        if (itemCol == 0) {
          final sampleCount = rows.length < 50 ? rows.length : 50;
          final colCount = rows
              .map((r) => r.length)
              .fold<int>(0, (p, e) => e > p ? e : p);
          final scores = List<int>.filled(colCount, 0);
          final nonNumeric = List<int>.filled(colCount, 0);
          final letterRegex = RegExp(r'[A-Za-z\u0E00-\u0E7F]');
          final numericRe = RegExp(r'^[-+]?[0-9]*\.?[0-9]+$');
          for (var i = 0; i < sampleCount; i++) {
            final r = rows[i];
            for (var c = 0; c < r.length; c++) {
              final cell = r[c].trim();
              if (cell.isEmpty) continue;
              if (letterRegex.hasMatch(cell)) scores[c]++;
              if (!numericRe.hasMatch(cell)) nonNumeric[c]++;
            }
          }
          var best = 0;
          double bestScore = -1.0;
          for (var c = 0; c < scores.length; c++) {
            final double score = scores[c].toDouble() + (nonNumeric[c] * 0.5);
            if (score > bestScore) {
              bestScore = score;
              best = c;
            }
          }
          itemCol = best;
        }

        // Identify other useful columns (category/tags, calories, protein) by header heuristics
        List<String> headers = [];
        if (header != null)
          headers = _splitCsvLine(
            header,
          ).map((s) => s.trim().toLowerCase()).toList();
        int catCol = -1;
        int tagCol = -1;
        int caloriesCol = -1;
        int proteinCol = -1;
        for (var i = 0; i < headers.length; i++) {
          final h = headers[i];
          if (catCol < 0 &&
              (h.contains('category') ||
                  h.contains('group') ||
                  h.contains('type') ||
                  h.contains('class') ||
                  h.contains('หมวด') ||
                  h.contains('ประเภท') ||
                  h.contains('กลุ่ม') ||
                  h.contains('ชนิด')))
            catCol = i;
          if (tagCol < 0 &&
              (h.contains('tag') ||
                  h.contains('tags') ||
                  h.contains('label') ||
                  h.contains('diet') ||
                  h.contains('goal') ||
                  h.contains('label')))
            tagCol = i;
          if (caloriesCol < 0 &&
              (h.contains('calor') ||
                  h.contains('energy') ||
                  h.contains('kcal')))
            caloriesCol = i;
          if (proteinCol < 0 &&
              (h.contains('protein') ||
                  h.contains('prot') ||
                  h.contains('โปรตีน')))
            proteinCol = i;
        }

        final numericRe = RegExp(r'^[-+]?[0-9]*\.?[0-9]+$');
        final seen = <String>{};
        final Map<String, String> nameToCombined = {};

        // Prepare buckets for app categories/types
        final buckets = <String, Set<String>>{
          'เมนูโปรตีน': <String>{},
          'เมนูผักและผลไม้': <String>{},
          'เมนูคาร์โบไฮเดรต': <String>{},
          'เมนูของหวาน': <String>{},
          'อาหารครบ5หมู่': <String>{},
          'อาหารลดน้ำหนัก': <String>{},
          'อาหารบำรุงสุขภาพ': <String>{},
          'อาหารให้พลังงานสูง': <String>{},
          'เครื่องดื่ม': <String>{},
          'เครื่องดื่มเพื่อสุขภาพ': <String>{},
          'เครื่องดื่มลดน้ำหนัก': <String>{},
          'เครื่องดื่มบำรุงร่างกาย / เพิ่มพลังงาน': <String>{},
        };

        final letterRegex = RegExp(r'[A-Za-z\u0E00-\u0E7F]');
        String pickName(List<String> r) {
          String n = '';
          if (itemCol < r.length) n = r[itemCol].trim();
          if ((n.isEmpty || numericRe.hasMatch(n)) && headers.isNotEmpty) {
            // try th_name or en_name columns explicitly
            for (var cand in ['th_name', 'en_name', 'name', 'food']) {
              final idx = headers.indexWhere(
                (h) => h == cand || h.contains(cand),
              );
              if (idx >= 0 && idx < r.length) {
                final v = r[idx].trim();
                if (v.isNotEmpty && !numericRe.hasMatch(v)) {
                  n = v;
                  break;
                }
              }
            }
          }
          // final fallback: scan row for first text-like token that's not numeric
          if ((n.isEmpty || numericRe.hasMatch(n))) {
            for (var cell in r) {
              final v = cell.trim();
              if (v.isEmpty) continue;
              if (numericRe.hasMatch(v)) continue;
              if (letterRegex.hasMatch(v)) {
                n = v;
                break;
              }
            }
          }
          return n;
        }

        for (var r in rows) {
          final name = pickName(r);
          if (name.isEmpty) continue;
          if (seen.contains(name)) continue;
          seen.add(name);

          // gather tag text
          final catText = (catCol >= 0 && catCol < r.length)
              ? r[catCol].toLowerCase()
              : '';
          final tagText = (tagCol >= 0 && tagCol < r.length)
              ? r[tagCol].toLowerCase()
              : '';
          final combined = '$catText $tagText ${r.join(' ').toLowerCase()}';
          nameToCombined[name] = combined;

          // numeric heuristics: parse calories/protein/fiber when available
          double? kcal;
          double? prot;
          double? fiber;
          if (caloriesCol >= 0 && caloriesCol < r.length)
            kcal = double.tryParse(r[caloriesCol].replaceAll('"', '').trim());
          if (proteinCol >= 0 && proteinCol < r.length)
            prot = double.tryParse(r[proteinCol].replaceAll('"', '').trim());
          final fiberIdx = headers.indexWhere(
            (h) =>
                h.contains('dietary_fiber') ||
                h.contains('fiber') ||
                h.contains('dietary'),
          );
          if (fiberIdx >= 0 && fiberIdx < r.length)
            fiber = double.tryParse(r[fiberIdx].replaceAll('"', '').trim());

          // compute flags for types and goals (clearer distribution)
          bool isProtein = false;
          bool isVeg = false;
          bool isCarb = false;
          bool isDrink = false;
          bool isWeightLoss = false;
          bool isBuildMuscle = false;

          // type keywords
          if (combined.contains('protein') ||
              combined.contains('เนื้อ') ||
              combined.contains('ปลา') ||
              combined.contains('ไข่') ||
              combined.contains('meat') ||
              combined.contains('chicken') ||
              combined.contains('egg') ||
              combined.contains('โปรตีน'))
            isProtein = true;
          if (combined.contains('vegetable') ||
              combined.contains('ผัก') ||
              combined.contains('ผลไม้') ||
              combined.contains('fruit') ||
              combined.contains('vegan'))
            isVeg = true;
          if (combined.contains('carb') ||
              combined.contains('rice') ||
              combined.contains('noodle') ||
              combined.contains('bread') ||
              combined.contains('คาร์บ') ||
              combined.contains('แป้ง') ||
              combined.contains('grain'))
            isCarb = true;
          if (combined.contains('drink') ||
              combined.contains('เครื่องดื่ม') ||
              combined.contains('น้ำ') ||
              combined.contains('beverage') ||
              combined.contains('smoothie') ||
              combined.contains('juice') ||
              combined.contains('ชา') ||
              combined.contains('กาแฟ'))
            isDrink = true;

          // goal keywords / numeric heuristics
          if (combined.contains('ลด') ||
              combined.contains('weight') ||
              combined.contains('loss') ||
              combined.contains('slim') ||
              combined.contains('ลดน้ำหนัก') ||
              combined.contains('ลดความอ้วน'))
            isWeightLoss = true;
          if (combined.contains('กล้าม') ||
              combined.contains('muscle') ||
              combined.contains('protein') ||
              combined.contains('สร้างกล้าม') ||
              combined.contains('build muscle') ||
              combined.contains('สร้างกล้ามเนื้อ'))
            isBuildMuscle = true;
          if (kcal != null) {
            if (kcal > 0 && kcal <= 200) isWeightLoss = true;
          }
          if (fiber != null) {
            if (fiber >= 5 && (kcal == null || kcal <= 300))
              isWeightLoss = true;
          }
          if (prot != null) {
            if (prot >= 15) isBuildMuscle = true;
          }

          // add to type buckets — if an item is a drink, keep it only in drink buckets
          if (!isDrink) {
            if (isProtein) buckets['เมนูโปรตีน']!.add(name);
            if (isVeg) buckets['เมนูผักและผลไม้']!.add(name);
            if (isCarb) buckets['เมนูคาร์โบไฮเดรต']!.add(name);
          }
          if (isDrink) buckets['เครื่องดื่ม']!.add(name);

          // add to goal buckets (prioritize explicit goal matches)
          if (isWeightLoss) buckets['อาหารลดน้ำหนัก']!.add(name);
          if (isBuildMuscle) buckets['อาหารสร้างกล้ามเนื้อ']!.add(name);

          // If the row explicitly mentions 'ครบ' or 'ครบ 5' or '5 หมู่' treat it as the default drink category
          if (combined.contains('ครบ') ||
              combined.contains('complete') ||
              combined.contains('ครบ 5') ||
              combined.contains('5 หมู่')) {
            buckets['เครื่องดื่มเพื่อสุขภาพ']!.add(name);
          } else {
            // If no goal/type keywords matched, also surface under the default drink category so the UI can show these items
            if (!isWeightLoss &&
                !isBuildMuscle &&
                !isProtein &&
                !isVeg &&
                !isCarb &&
                !isDrink) {
              buckets['เครื่องดื่มเพื่อสุขภาพ']!.add(name);
            }
          }

          // apply nutrition-based heuristics to supplement mapping
          try {
            if (kcal != null) {
              if (kcal > 0 && kcal <= 200) {
                buckets['อาหารลดน้ำหนัก']!.add(name);
              }
            }
            if (fiber != null) {
              if (fiber >= 5 && (kcal == null || kcal <= 300)) {
                buckets['อาหารลดน้ำหนัก']!.add(name);
              }
            }
            if (prot != null) {
              if (prot >= 15) {
                buckets['อาหารสร้างกล้ามเนื้อ']!.add(name);
              }
            }
          } catch (_) {}
        }

        // Fallback: if some primary type buckets are empty, try a targeted fill
        final expandedTypeTokens = {
          'เมนูโปรตีน': [
            'protein',
            'โปรตีน',
            'meat',
            'chicken',
            'beef',
            'pork',
            'fish',
            'egg',
            'tofu',
            'tempeh',
            'seafood',
            'shrimp',
            'salmon',
            'tuna',
            'steak',
            'ไก่',
            'ปลา',
            'ไข่',
            'เนื้อ',
          ],
          'เมนูผักและผลไม้': [
            'vegetable',
            'ผัก',
            'ผลไม้',
            'fruit',
            'salad',
            'vegan',
            'leaf',
            'ผลไม้',
            'ผักสด',
            'ผักต้ม',
            'vegan',
          ],
          'เมนูคาร์โบไฮเดรต': [
            'carb',
            'carbo',
            'rice',
            'noodle',
            'pasta',
            'bread',
            'potato',
            'แป้ง',
            'ข้าว',
            'เส้น',
            'ขนมปัง',
            'grain',
            'rice',
            'mashed',
          ],
          'เครื่องดื่ม': [
            'drink',
            'เครื่องดื่ม',
            'น้ำ',
            'beverage',
            'juice',
            'smoothie',
            'tea',
            'coffee',
            'กาแฟ',
            'ชา',
            'น้ำผลไม้',
          ],
        };

        // If a bucket is empty, scan nameToCombined and add matches (limit to 200 each)
        expandedTypeTokens.forEach((bucketKey, toks) {
          if ((buckets[bucketKey] == null) || buckets[bucketKey]!.isEmpty) {
            int added = 0;
            nameToCombined.forEach((nm, cmb) {
              final lower = cmb.toLowerCase();
              for (var t in toks) {
                if (lower.contains(t)) {
                  buckets[bucketKey]!.add(nm);
                  added++;
                  break;
                }
              }
              if (added >= 200) return;
            });
          }
        });

        // Ensure items classified as drinks are not also present in primary-type buckets
        if (buckets['เครื่องดื่ม'] != null &&
            buckets['เครื่องดื่ม']!.isNotEmpty) {
          final drinksSet = Set<String>.from(buckets['เครื่องดื่ม']!);
          for (var d in drinksSet) {
            buckets['เมนูโปรตีน']?.remove(d);
            buckets['เมนูผักและผลไม้']?.remove(d);
            buckets['เมนูคาร์โบไฮเดรต']?.remove(d);
          }
        }

        // Convert sets to lists and only include non-empty buckets
        buckets.forEach((k, s) {
          if (s.isNotEmpty) map[k] = s.toList();
        });
        if (map.isNotEmpty) result['master_foods.csv'] = map;
        return result;
      }
    } catch (_) {}

    final files = await listBackendCsvFiles();
    for (var rel in files) {
      final filename = rel;
      try {
        final info = await loadCsvRows(rel);
        final header = info['header'] as String?;
        final rows = info['rows'] as List<List<String>>;

        // detect category column index
        int? categoryCol;
        int? itemCol;
        if (header != null) {
          final headers = _splitCsvLine(
            header,
          ).map((s) => s.toLowerCase()).toList();
          for (var i = 0; i < headers.length; i++) {
            final h = headers[i];
            if (h.contains('category') ||
                h.contains('type') ||
                h.contains('group') ||
                h.contains('class') ||
                h.contains('หมวด') ||
                h.contains('ประเภท') ||
                h.contains('กลุ่ม') ||
                h.contains('ชนิด')) {
              categoryCol = i;
            }
            if (h.contains('name') ||
                h.contains('food') ||
                h.contains('item') ||
                h.contains('อาหาร') ||
                h.contains('ชื่อ')) {
              itemCol = i;
            }
          }
        }

        // If no itemCol determined, pick most-text-like column while avoiding numeric-heavy columns
        if (itemCol == null) {
          final colCount = rows
              .map((r) => r.length)
              .fold<int>(0, (p, e) => e > p ? e : p);
          final scores = List<int>.filled(colCount, 0);
          final nonNumeric = List<int>.filled(colCount, 0);
          final sampleCount = rows.length < 50 ? rows.length : 50;
          final letterRegex = RegExp(r'[A-Za-z\u0E00-\u0E7F]');
          final numericRe = RegExp(r'^[-+]?[0-9]*\.?[0-9]+$');
          for (var i = 0; i < sampleCount; i++) {
            final r = rows[i];
            for (var c = 0; c < r.length; c++) {
              final cell = r[c].trim();
              if (cell.isEmpty) continue;
              if (letterRegex.hasMatch(cell)) scores[c]++;
              if (!numericRe.hasMatch(cell)) nonNumeric[c]++;
            }
          }
          var best = 0;
          double bestScore = -1.0;
          for (var c = 0; c < scores.length; c++) {
            final double score = scores[c].toDouble() + (nonNumeric[c] * 0.5);
            if (score > bestScore) {
              bestScore = score;
              best = c;
            }
          }
          itemCol = best;
        }

        final map = <String, List<String>>{};
        if (categoryCol != null) {
          for (var r in rows) {
            if (categoryCol >= r.length || itemCol >= r.length) continue;
            final cat = r[categoryCol].trim();
            final item = r[itemCol].trim();
            if (item.isEmpty) continue;
            if (RegExp(r'^[-+]?[0-9]*\.?[0-9]+$').hasMatch(item)) continue;
            map.putIfAbsent(cat.isEmpty ? filename : cat, () => []).add(item);
          }
        } else {
          // no category column — group under filename
          final items = <String>[];
          for (var r in rows) {
            if (itemCol >= r.length) continue;
            final item = r[itemCol].trim();
            if (item.isEmpty) continue;
            items.add(item);
          }
          map[filename] = items;
        }

        // Supplement: compute app-level buckets (weight-loss, build-muscle, types) per file
        try {
          final buckets = <String, Set<String>>{
            'เมนูโปรตีน': <String>{},
            'เมนูผักและผลไม้': <String>{},
            'เมนูคาร์โบไฮเดรต': <String>{},
            'เมนูของหวาน': <String>{},
            'อาหารครบ5หมู่': <String>{},
            'อาหารลดน้ำหนัก': <String>{},
            'อาหารบำรุงสุขภาพ': <String>{},
            'อาหารให้พลังงานสูง': <String>{},
            'เครื่องดื่ม': <String>{},
            'เครื่องดื่มเพื่อสุขภาพ': <String>{},
            'เครื่องดื่มลดน้ำหนัก': <String>{},
            'เครื่องดื่มบำรุงร่างกาย / เพิ่มพลังงาน': <String>{},
          };

          // helper to safely get numeric value from row by header match
          double? findNumeric(
            List<String> r,
            List<String> headers,
            List<String> matchers,
          ) {
            for (var m in matchers) {
              final idx = headers.indexWhere((h) => h.contains(m));
              if (idx >= 0 && idx < r.length) {
                final v = r[idx].replaceAll('"', '').trim();
                final parsed = double.tryParse(v);
                if (parsed != null) return parsed;
              }
            }
            return null;
          }

          final hdrs = header != null
              ? _splitCsvLine(header).map((s) => s.toLowerCase()).toList()
              : <String>[];
          final nameToNumericPerFile = <String, Map<String, double?>>{};
          for (var r in rows) {
            if (itemCol >= r.length) continue;
            final name = r[itemCol].trim();
            if (name.isEmpty) continue;
            final combined = r.join(' ').toLowerCase();

            // basic type keywords — if it's a drink, keep only in drink bucket
            final bool basicIsDrink =
                (combined.contains('drink') ||
                combined.contains('เครื่องดื่ม') ||
                combined.contains('น้ำ') ||
                combined.contains('juice') ||
                combined.contains('tea') ||
                combined.contains('coffee'));
            if (!basicIsDrink) {
              if (combined.contains('protein') ||
                  combined.contains('เนื้อ') ||
                  combined.contains('ปลา') ||
                  combined.contains('ไข่') ||
                  combined.contains('meat') ||
                  combined.contains('chicken') ||
                  combined.contains('egg') ||
                  combined.contains('โปรตีน'))
                buckets['เมนูโปรตีน']!.add(name);
              if (combined.contains('vegetable') ||
                  combined.contains('ผัก') ||
                  combined.contains('ผลไม้') ||
                  combined.contains('fruit') ||
                  combined.contains('vegan'))
                buckets['เมนูผักและผลไม้']!.add(name);
              if (combined.contains('carb') ||
                  combined.contains('rice') ||
                  combined.contains('noodle') ||
                  combined.contains('pasta') ||
                  combined.contains('bread') ||
                  combined.contains('แป้ง') ||
                  combined.contains('ข้าว') ||
                  combined.contains('เส้น'))
                buckets['เมนูคาร์โบไฮเดรต']!.add(name);
            } else {
              buckets['เครื่องดื่ม']!.add(name);
            }

            // numeric heuristics
            final kcal = findNumeric(r, hdrs, ['calor', 'energy', 'kcal']);
            final prot = findNumeric(r, hdrs, ['protein', 'prot', 'โปรตีน']);
            final fiber = findNumeric(r, hdrs, ['fiber', 'dietary_fiber']);
            // store numeric values for later supplemental heuristics
            nameToNumericPerFile[name] = {
              'kcal': kcal,
              'prot': prot,
              'fiber': fiber,
            };
            if (kcal != null && kcal > 0 && kcal <= 200)
              buckets['อาหารลดน้ำหนัก']!.add(name);
            if (fiber != null && fiber >= 5 && (kcal == null || kcal <= 300))
              buckets['อาหารลดน้ำหนัก']!.add(name);
            if (prot != null && prot >= 15)
              buckets['อาหารสร้างกล้ามเนื้อ']!.add(name);

            // keyword match for goals
            if (combined.contains('ลด') ||
                combined.contains('weight') ||
                combined.contains('loss') ||
                combined.contains('slim') ||
                combined.contains('ลดน้ำหนัก'))
              buckets['อาหารลดน้ำหนัก']!.add(name);
            if (combined.contains('กล้าม') ||
                combined.contains('muscle') ||
                combined.contains('สร้างกล้าม') ||
                combined.contains('build muscle'))
              buckets['อาหารสร้างกล้ามเนื้อ']!.add(name);

            // If the row explicitly mentions 'ครบ' or 'ครบ 5' or '5 หมู่' treat it as the default drink category
            if (combined.contains('ครบ') ||
                combined.contains('complete') ||
                combined.contains('ครบ 5') ||
                combined.contains('5 หมู่')) {
              buckets['เครื่องดื่มเพื่อสุขภาพ']!.add(name);
            }
          }

          // If some primary type buckets are empty for this file, try to fill them by scanning categories/items
          final nameToCombinedPerFile = <String, String>{};
          map.forEach((catK, itemsList) {
            for (var nm in itemsList) {
              nameToCombinedPerFile[nm] = '$catK $nm'.toLowerCase();
            }
          });

          // Supplement: if weight-loss bucket is empty or sparse, consider protein items that are low-calorie or moderately high-protein
          try {
            if (buckets['อาหารลดน้ำหนัก'] == null ||
                buckets['อาหารลดน้ำหนัก']!.isEmpty) {
              for (var nm in List<String>.from(buckets['เมนูโปรตีน']!)) {
                final nums = nameToNumericPerFile[nm];
                final kcal = nums != null ? nums['kcal'] : null;
                final prot = nums != null ? nums['prot'] : null;
                final lower = nm.toLowerCase();
                if ((kcal != null && kcal > 0 && kcal <= 350) ||
                    (prot != null && prot >= 12) ||
                    lower.contains('low') ||
                    lower.contains('ลด')) {
                  buckets['อาหารลดน้ำหนัก']!.add(nm);
                }
              }
            }
          } catch (_) {}

          final expandedTypeTokensFile = {
            'เมนูโปรตีน': [
              'protein',
              'โปรตีน',
              'meat',
              'chicken',
              'beef',
              'pork',
              'fish',
              'egg',
              'tofu',
              'tempeh',
              'seafood',
              'shrimp',
              'salmon',
              'tuna',
              'steak',
              'ไก่',
              'ปลา',
              'ไข่',
              'เนื้อ',
            ],
            'เมนูผักและผลไม้': [
              'vegetable',
              'ผัก',
              'ผลไม้',
              'fruit',
              'salad',
              'vegan',
              'leaf',
              'ผลไม้',
              'ผักสด',
              'ผักต้ม',
              'vegan',
            ],
            'เมนูคาร์โบไฮเดรต': [
              'carb',
              'carbo',
              'rice',
              'noodle',
              'pasta',
              'bread',
              'potato',
              'แป้ง',
              'ข้าว',
              'เส้น',
              'ขนมปัง',
              'grain',
              'rice',
              'mashed',
            ],
            'เครื่องดื่ม': [
              'drink',
              'เครื่องดื่ม',
              'น้ำ',
              'beverage',
              'juice',
              'smoothie',
              'tea',
              'coffee',
              'กาแฟ',
              'ชา',
              'น้ำผลไม้',
            ],
          };

          expandedTypeTokensFile.forEach((bucketKey, toks) {
            if ((buckets[bucketKey] == null) || buckets[bucketKey]!.isEmpty) {
              int added = 0;
              nameToCombinedPerFile.forEach((nm, cmb) {
                for (var t in toks) {
                  if (cmb.contains(t)) {
                    buckets[bucketKey]!.add(nm);
                    added++;
                    break;
                  }
                }
                if (added >= 200) return;
              });
            }
          });

          // Ensure items classified as drinks are not also present in primary-type buckets for this file
          if (buckets['เครื่องดื่ม'] != null &&
              buckets['เครื่องดื่ม']!.isNotEmpty) {
            final drinksSetFile = Set<String>.from(buckets['เครื่องดื่ม']!);
            for (var d in drinksSetFile) {
              buckets['เมนูโปรตีน']?.remove(d);
              buckets['เมนูผักและผลไม้']?.remove(d);
              buckets['เมนูคาร์โบไฮเดรต']?.remove(d);
            }
          }

          // merge non-empty buckets into map
          buckets.forEach((k, s) {
            if (s.isNotEmpty) map.putIfAbsent(k, () => []).addAll(s);
          });
        } catch (_) {}

        // apply custom tags for this file (relative path format)
        try {
          final relKey = filename.replaceAll('\\', '/');
          if (customTags.containsKey(relKey)) {
            customTags[relKey]?.forEach((item, tagList) {
              for (var tag in tagList) {
                map.putIfAbsent(tag, () => []).add(item);
              }
            });
          }
        } catch (_) {}
        result[filename] = map;
      } catch (_) {
        // skip bad files silently
      }
    }
    return result;
  }

  /// Load pre-extracted app categories JSON if present (produced by scripts/extract_app_categories.py)
  // `extracted_app_categories.json` and the legacy loader were removed per production refactor.
  // Use the new specialized loaders below instead.

  // ---------------------------------------------------------------------------
  // New specialized loaders (production refactor)
  // - Deterministic, CSV-only mapping for three main food types
  // - Separate dessert loader (calorie_dataset.csv)
  // - Drink loaders (Starbucks files) and smoothie-based healthy drinks loader
  // ---------------------------------------------------------------------------

  // Global used set for the three primary food menus to avoid cross-category duplicates
  static final Set<String> _usedMenus = <String>{};

  static List<String> _filterUnique(List<String> input) {
    final result = <String>[];
    for (var item in input) {
      final key = item.trim().toLowerCase();
      if (key.isEmpty) continue;
      if (!_usedMenus.contains(key)) {
        _usedMenus.add(key);
        result.add(item.trim());
      }
    }
    return result;
  }

  // Local uniqueness filter that does not interact with global `_usedMenus`.
  static List<String> _localUnique(List<String> input) {
    final uniq = <String>[];
    final seenLocal = <String>{};
    for (var n in input) {
      final kk = n.toLowerCase().trim();
      if (kk.isEmpty) continue;
      if (!seenLocal.contains(kk)) {
        seenLocal.add(kk);
        uniq.add(n.trim());
      }
    }
    return uniq;
  }

  // Remove duplicates (case-insensitive) and remove items that share the same numeric token.
  // If any numeric sequence (e.g., '1', '2020') appears in more than one item, all items containing that numeric sequence are removed.
  static List<String> _dedupeAndRemoveNumericConflicts(List<String> input) {
    final seen = <String>{};
    final cleaned = <String>[];
    for (var it in input) {
      final k = it.trim();
      if (k.isEmpty) continue;
      final key = k.toLowerCase();
      if (seen.contains(key)) continue;
      seen.add(key);
      cleaned.add(k);
    }

    // map numeric token -> list of indices
    final Map<String, List<int>> numMap = {};
    final numberRe = RegExp(r"\d+");
    for (var i = 0; i < cleaned.length; i++) {
      final name = cleaned[i];
      final matches = numberRe.allMatches(name);
      for (var m in matches) {
        final tok = m.group(0) ?? '';
        if (tok.isEmpty) continue;
        numMap.putIfAbsent(tok, () => []).add(i);
      }
    }

    // collect indices that are part of conflicts (numeric token appears more than once)
    final removeIdx = <int>{};
    numMap.forEach((tok, idxs) {
      if (idxs.length > 1) removeIdx.addAll(idxs);
    });

    final out = <String>[];
    for (var i = 0; i < cleaned.length; i++) {
      if (removeIdx.contains(i)) continue;
      out.add(cleaned[i]);
    }
    return out;
  }

  static List<String> _splitCsvLine(String line) {
    // Robust CSV parser: iterate characters and split on commas not inside quotes.
    final parts = <String>[];
    var sb = StringBuffer();
    bool inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        // handle escaped double quote
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          sb.write('"');
          i++; // skip next
          continue;
        }
        inQuotes = !inQuotes;
        continue;
      }
      if (ch == ',' && !inQuotes) {
        parts.add(sb.toString());
        sb = StringBuffer();
      } else {
        sb.write(ch);
      }
    }
    parts.add(sb.toString());
    return parts.map((s) {
      var t = s.trim();
      if (t.length >= 2 && t.startsWith('"') && t.endsWith('"'))
        t = t.substring(1, t.length - 1);
      return t;
    }).toList();
  }

  static Future<Map<String, Set<String>>> loadProteinMenus({
    String? category,
  }) async {
    final info = await loadCsvRows('Food_Nutrition_Dataset.csv');
    final header = info['header'] as String?;
    final rows = info['rows'] as List<List<String>>;
    final out = {
      'อาหารครบ5หมู่': <String>{},
      'อาหารลดน้ำหนัก': <String>{},
      'อาหารสร้างกล้ามเนื้อ': <String>{},
    };
    int nameIdx = -1;
    int categoryIdx = -1;
    int proteinIdx = -1;
    int carbsIdx = -1;
    int fatIdx = -1;
    int caloriesIdx = -1;

    if (header == null) {
      // Fallback mapping for files without header row: assume common positions
      if (rows.isNotEmpty && rows.first.length >= 6) {
        nameIdx = 0;
        categoryIdx = 1;
        caloriesIdx = 2;
        proteinIdx = 3;
        carbsIdx = 4;
        fatIdx = 5;
        try {
          print(
            '[CsvLoader] loadProteinMenus: no header, using fallback indices name=0 cat=1 kcal=2 prot=3 carbs=4 fat=5',
          );
        } catch (_) {}
      } else {
        // not enough columns to make a guess
        try {
          print(
            '[CsvLoader] loadProteinMenus: no header and insufficient columns',
          );
        } catch (_) {}
        return out;
      }
    } else {
      final headers = _splitCsvLine(
        header,
      ).map((s) => s.toLowerCase()).toList();
      nameIdx = headers.indexWhere(
        (h) =>
            h.contains('food_name') ||
            h.contains('name') ||
            h.contains('ชื่อ') ||
            h.contains('th_name'),
      );
      categoryIdx = headers.indexWhere(
        (h) =>
            h.contains('category') || h.contains('type') || h.contains('หมวด'),
      );
      proteinIdx = headers.indexWhere(
        (h) => h.contains('protein') || h.contains('โปรตีน'),
      );
      carbsIdx = headers.indexWhere(
        (h) =>
            h.contains('carb') ||
            h.contains('carbo') ||
            h.contains('คาร์โบไฮเดรต'),
      );
      fatIdx = headers.indexWhere(
        (h) => h.contains('fat') || h.contains('ไขมัน'),
      );
      caloriesIdx = headers.indexWhere(
        (h) =>
            h.contains('calor') || h.contains('kcal') || h.contains('energy'),
      );
    }
    try {
      print(
        '[CsvLoader] loadProteinMenus header=${header != null} rows=${rows.length}',
      );
      if (header != null)
        print('[CsvLoader] loadProteinMenus headerStr=$header');
      if (rows.isNotEmpty)
        print('[CsvLoader] loadProteinMenus firstRowSample=${rows.first}');
      print(
        '[CsvLoader] loadProteinMenus indices name=$nameIdx cat=$categoryIdx kcal=$caloriesIdx prot=$proteinIdx carbs=$carbsIdx fat=$fatIdx',
      );
    } catch (_) {}

    final proteinTokens = [
      'protein',
      'โปรตีน',
      'meat',
      'chicken',
      'fish',
      'egg',
      'เนื้อ',
      'ปลา',
      'ไข่',
      'tofu',
      'tempeh',
      'seafood',
    ];
    for (var r in rows) {
      if (nameIdx < 0 || nameIdx >= r.length) continue;
      final name = r[nameIdx].trim();
      if (name.isEmpty) continue;

      final catVal = (categoryIdx >= 0 && categoryIdx < r.length)
          ? r[categoryIdx].toLowerCase()
          : '';
      final combined = r.join(' ').toLowerCase();

      // Determine whether this row should be considered a protein item.
      bool isProtein = false;
      if (catVal.isNotEmpty && proteinTokens.any((t) => catVal.contains(t)))
        isProtein = true;
      if (!isProtein) {
        // Heuristic: inspect combined row text for protein keywords
        if (proteinTokens.any((t) => combined.contains(t))) isProtein = true;
      }

      if (!isProtein) continue;

      double tryParseIdx(int idx) {
        if (idx < 0 || idx >= r.length) return double.nan;
        return double.tryParse(r[idx].replaceAll('"', '').trim()) ?? double.nan;
      }

      final prot = tryParseIdx(proteinIdx);
      final carbs = tryParseIdx(carbsIdx);
      final fat = tryParseIdx(fatIdx);
      final kcal = tryParseIdx(caloriesIdx);

      // ครบ 5 หมู่: simple numeric thresholds
      if (!prot.isNaN && !carbs.isNaN && !fat.isNaN) {
        if (prot > 5 && carbs > 5 && fat > 2) out['อาหารครบ5หมู่']!.add(name);
      }

      // ลดน้ำหนัก: low calories and low fat
      if (!kcal.isNaN && !fat.isNaN) {
        if (kcal < 300 && fat < 10) out['อาหารลดน้ำหนัก']!.add(name);
      }

      // สร้างกล้าม: high protein OR explicit keywords
      if (!prot.isNaN && prot >= 12) {
        out['อาหารสร้างกล้ามเนื้อ']!.add(name);
      } else {
        final muscleTokens = [
          'กล้าม',
          'muscle',
          'สร้างกล้าม',
          'high protein',
          'high-protein',
          'โปรตีนสูง',
          'ให้โปรตีนสูง',
          'rich in protein',
          'highprotein',
        ];
        if (muscleTokens.any((t) => combined.contains(t))) {
          out['อาหารสร้างกล้ามเนื้อ']!.add(name);
        }
      }
    }
    try {
      print(
        '[CsvLoader] loadProteinMenus counts: ครบ5=${out['อาหารครบ5หมู่']?.length} ลดน้ำหนัก=${out['อาหารลดน้ำหนัก']?.length} สร้างกล้าม=${out['อาหารสร้างกล้ามเนื้อ']?.length}',
      );
    } catch (_) {}
    return out;
  }

  // Internal helper: parse Food_Nutrition_Dataset.csv and assign each item to one
  // of 'protein','vegetable','carb' using priority protein > vegetable > carb.
  static Future<Map<String, List<String>>> _loadFoodNutritionCategories({
    String? filterCategory,
  }) async {
    final raw = await _loadRaw('Food_Nutrition_Dataset.csv');
    final lines = raw.split(RegExp(r'\r?\n'));
    final result = {
      'protein': <String>[],
      'vegetable': <String>[],
      'carb': <String>[],
    };
    if (lines.length <= 1) return result;
    // debug: show incoming filter and total rows
    try {
      print(
        '[CsvLoader] _loadFoodNutritionCategories filterCategory=$filterCategory',
      );
      print(
        '[CsvLoader] _loadFoodNutritionCategories rows total=${lines.length - 1}',
      );
    } catch (_) {}
    final header = _splitCsvLine(
      lines.first,
    ).map((h) => h.toLowerCase()).toList();
    final nameIdx = header.indexWhere(
      (h) => h.contains('food_name') || h.contains('name'),
    );
    int categoryIdx = header.indexWhere(
      (h) =>
          h.contains('category') || h.contains('type') || h.contains('group'),
    );
    // fallback: if no explicit category, try common header names
    if (categoryIdx < 0)
      categoryIdx = header.indexWhere(
        (h) => h.contains('category') || h.contains('หมวด'),
      );

    // detect numeric column indices to help classify items
    final proteinCol = header.indexWhere(
      (h) => h.contains('protein') || h.contains('prot'),
    );
    final carbsCol = header.indexWhere(
      (h) => h.contains('carb') || h.contains('carbo'),
    );
    final caloriesCol = header.indexWhere(
      (h) => h.contains('calor') || h.contains('energy') || h.contains('kcal'),
    );

    final seen = <String>{};
    int debugPrinted = 0;
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().isEmpty) continue;
      final cols = _splitCsvLine(line);
      if (nameIdx < 0 || nameIdx >= cols.length) continue;
      final name = cols[nameIdx].trim();
      if (name.isEmpty) continue;
      final key = name.toLowerCase();
      if (seen.contains(key)) continue;
      // Use CSV 'category' column as authoritative. Normalize strings
      final rowCategory = (categoryIdx >= 0 && categoryIdx < cols.length)
          ? cols[categoryIdx]
          : '';
      final mappedCat = _englishCategoryToThai(rowCategory);
      final rowCatNorm = _normalize(mappedCat);
      final filterNorm = _normalize(filterCategory ?? '');

      // If filterCategory supplied, only take exact normalized matches
      if (filterCategory != null && filterCategory.trim().isNotEmpty) {
        if (rowCatNorm == filterNorm) {
          // Add to a neutral collection; callers that requested a specific
          // loader will take the returned list appropriate for that loader.
          result['protein']!.add(name);
          result['vegetable']!.add(name);
          result['carb']!.add(name);
          seen.add(key);
        }
        // detailed debug when filter supplied
        if (rowCatNorm != filterNorm && debugPrinted < 60) {
          try {
            print(
              '[CsvLoader] _loadFoodNutritionCategories filter="${filterNorm}" row="${rowCategory}" rowNorm="${rowCatNorm}"',
            );
          } catch (_) {}
          debugPrinted++;
        }
        continue;
      }

      // No filter supplied: map CSV category keywords to buckets deterministically
      final cat = rowCatNorm;
      if (cat.contains('meat') ||
          cat.contains('chicken') ||
          cat.contains('fish') ||
          cat.contains('egg') ||
          cat.contains('pork') ||
          cat.contains('beef') ||
          cat.contains('seafood') ||
          cat.contains('protein') ||
          cat.contains('โปรตีน') ||
          cat.contains('เนื้อ')) {
        result['protein']!.add(name);
        seen.add(key);
        continue;
      }
      if (cat.contains('vegetable') ||
          cat.contains('ผัก') ||
          cat.contains('fruit') ||
          cat.contains('ผลไม้') ||
          cat.contains('salad')) {
        result['vegetable']!.add(name);
        seen.add(key);
        continue;
      }
      if (cat.contains('rice') ||
          cat.contains('noodle') ||
          cat.contains('pasta') ||
          cat.contains('bread') ||
          cat.contains('carb') ||
          cat.contains('carbo') ||
          cat.contains('ข้าว') ||
          cat.contains('แป้ง') ||
          cat.contains('เส้น')) {
        result['carb']!.add(name);
        seen.add(key);
        continue;
      }
      // fallback into vegetable
      result['vegetable']!.add(name);
      seen.add(key);
      continue;
    }

    // ensure dedupe and limit sizes
    // If all three primary buckets are empty, attempt a more permissive
    // fallback classification that scans row content and keywords to
    // populate the buckets (useful when CSVs don't contain expected
    // category column or its values differ).
    try {
      final int totalPrimary =
          (result['protein']?.length ?? 0) +
          (result['vegetable']?.length ?? 0) +
          (result['carb']?.length ?? 0);
      if (totalPrimary == 0) {
        print(
          '[CsvLoader] _loadFoodNutritionCategories primary buckets empty — running fallback classifier',
        );
        final seenFallback = <String>{};
        final proteinTokens = [
          'protein',
          'เนื้อ',
          'chicken',
          'fish',
          'egg',
          'meat',
          'pork',
          'beef',
          'seafood',
          'tofu',
        ];
        final vegTokens = [
          'vegetable',
          'ผัก',
          'fruit',
          'ผลไม้',
          'salad',
          'ผักสด',
        ];
        final carbTokens = [
          'carb',
          'carbo',
          'rice',
          'noodle',
          'pasta',
          'bread',
          'ข้าว',
          'แป้ง',
          'เส้น',
          'potato',
        ];
        final drinkTokens = [
          'drink',
          'เครื่องดื่ม',
          'smoothie',
          'juice',
          'tea',
          'coffee',
          'กาแฟ',
          'ชา',
        ];
        for (var i = 1; i < lines.length; i++) {
          final line = lines[i];
          if (line.trim().isEmpty) continue;
          final cols = _splitCsvLine(line);
          // pick a name-like token from the row
          String name = '';
          for (var c in cols) {
            final v = c.trim();
            if (v.isEmpty) continue;
            if (!RegExp(r'^[-+]?[0-9]*\.?[0-9]+\$').hasMatch(v)) {
              name = v;
              break;
            }
          }
          if (name.isEmpty) continue;
          final lname = name.toLowerCase();
          if (seenFallback.contains(lname)) continue;
          seenFallback.add(lname);
          final combined = cols.join(' ').toLowerCase();
          bool added = false;
          for (var t in proteinTokens) {
            if (combined.contains(t)) {
              result['protein']!.add(name);
              added = true;
              break;
            }
          }
          if (added) continue;
          for (var t in vegTokens) {
            if (combined.contains(t)) {
              result['vegetable']!.add(name);
              added = true;
              break;
            }
          }
          if (added) continue;
          for (var t in carbTokens) {
            if (combined.contains(t)) {
              result['carb']!.add(name);
              added = true;
              break;
            }
          }
          if (added) continue;
          // fallback: if row looks like a drink, put into drinks; otherwise into vegetable
          for (var t in drinkTokens) {
            if (combined.contains(t)) {
              result['vegetable']!.add(name);
              added = true;
              break;
            }
          }
          if (!added) result['vegetable']!.add(name);
        }
      }
    } catch (_) {}

    result.forEach((k, list) {
      final uniq = <String>[];
      final seenLocal = <String>{};
      for (var n in list) {
        final kk = n.toLowerCase().trim();
        if (kk.isEmpty) continue;
        if (!seenLocal.contains(kk)) {
          seenLocal.add(kk);
          uniq.add(n.trim());
        }
      }
      result[k] = uniq;
    });
    // debug: print sizes and samples before numeric-conflict removal
    try {
      final pSample = (result['protein'] ?? []).take(5).toList();
      final vSample = (result['vegetable'] ?? []).take(5).toList();
      final cSample = (result['carb'] ?? []).take(5).toList();
      print(
        '[CsvLoader] _loadFoodNutritionCategories -> sizes protein=${(result['protein'] ?? []).length} vegetable=${(result['vegetable'] ?? []).length} carb=${(result['carb'] ?? []).length}',
      );
      print('[CsvLoader] samples protein=$pSample veg=$vSample carb=$cSample');
    } catch (_) {}
    // debug: show after-filter counts (rows matched filter)
    try {
      print(
        '[CsvLoader] _loadFoodNutritionCategories afterFilter protein=${(result['protein'] ?? []).length} vegetable=${(result['vegetable'] ?? []).length} carb=${(result['carb'] ?? []).length}',
      );
    } catch (_) {}
    // For the main food-category lists, prefer local uniqueness so we don't
    // accidentally remove items that were previously consumed by other
    // operations during the app lifecycle.
    result.forEach((k, list) {
      final filtered = _localUnique(list);
      try {
        print(
          '[CsvLoader] _loadFoodNutritionCategories final $k=${filtered.length} sample=${filtered.take(5).toList()}',
        );
      } catch (_) {}
      result[k] = filtered;
    });
    return result;
  }

  static Future<Map<String, Set<String>>> loadVegetableMenus({
    String? category,
  }) async {
    final info = await loadCsvRows('Food_Nutrition_Dataset.csv');
    final header = info['header'] as String?;
    final rows = info['rows'] as List<List<String>>;
    final out = {
      'อาหารครบ5หมู่': <String>{},
      'อาหารลดน้ำหนัก': <String>{},
      'อาหารบำรุงสุขภาพ': <String>{},
    };
    if (header == null) return out;
    final headers = _splitCsvLine(header).map((s) => s.toLowerCase()).toList();
    final nameIdx = headers.indexWhere(
      (h) =>
          h.contains('food_name') || h.contains('name') || h.contains('ชื่อ'),
    );
    final categoryIdx = headers.indexWhere(
      (h) => h.contains('category') || h.contains('type') || h.contains('หมวด'),
    );
    final proteinIdx = headers.indexWhere(
      (h) => h.contains('protein') || h.contains('โปรตีน'),
    );
    final carbsIdx = headers.indexWhere(
      (h) =>
          h.contains('carb') ||
          h.contains('carbo') ||
          h.contains('คาร์โบไฮเดรต'),
    );
    final caloriesIdx = headers.indexWhere(
      (h) => h.contains('calor') || h.contains('kcal') || h.contains('energy'),
    );
    final vitCIdx = headers.indexWhere(
      (h) =>
          h.contains('vitamin_c') ||
          h.contains('vitamin c') ||
          h.contains('vit c') ||
          h.contains('วิตามิน'),
    );
    final ironIdx = headers.indexWhere(
      (h) => h.contains('iron') || h.contains('เหล็ก'),
    );

    for (var r in rows) {
      if (nameIdx < 0 || nameIdx >= r.length) continue;
      final name = r[nameIdx].trim();
      if (name.isEmpty) continue;
      final catVal = (categoryIdx >= 0 && categoryIdx < r.length)
          ? r[categoryIdx].toLowerCase()
          : '';
      if (!(catVal.contains('vegetable') ||
          catVal.contains('vegetables') ||
          catVal.contains('veg') ||
          catVal.contains('ผัก') ||
          catVal.contains('ผลไม้') ||
          catVal.contains('fruit')))
        continue;

      double tryParseIdx(int idx) {
        if (idx < 0 || idx >= r.length) return double.nan;
        return double.tryParse(r[idx].replaceAll('"', '').trim()) ?? double.nan;
      }

      final prot = tryParseIdx(proteinIdx);
      final carbs = tryParseIdx(carbsIdx);
      final kcal = tryParseIdx(caloriesIdx);
      final vitc = tryParseIdx(vitCIdx);
      final iron = tryParseIdx(ironIdx);

      if (!prot.isNaN && !carbs.isNaN) {
        if (prot > 3 && carbs > 5) out['อาหารครบ5หมู่']!.add(name);
      }
      if (!kcal.isNaN) {
        if (kcal < 250) out['อาหารลดน้ำหนัก']!.add(name);
      }
      if (!vitc.isNaN && vitc > 10) out['อาหารบำรุงสุขภาพ']!.add(name);
      if (!iron.isNaN && iron > 2) out['อาหารบำรุงสุขภาพ']!.add(name);
    }
    return out;
  }

  static Future<Map<String, Set<String>>> loadCarbMenus({
    String? category,
  }) async {
    final info = await loadCsvRows('Food_Nutrition_Dataset.csv');
    final header = info['header'] as String?;
    final rows = info['rows'] as List<List<String>>;
    final out = {
      'อาหารครบ5หมู่': <String>{},
      'อาหารลดน้ำหนัก': <String>{},
      'อาหารให้พลังงานสูง': <String>{},
    };
    if (header == null) return out;
    final headers = _splitCsvLine(header).map((s) => s.toLowerCase()).toList();
    final nameIdx = headers.indexWhere(
      (h) =>
          h.contains('food_name') || h.contains('name') || h.contains('ชื่อ'),
    );
    final categoryIdx = headers.indexWhere(
      (h) => h.contains('category') || h.contains('type') || h.contains('หมวด'),
    );
    final proteinIdx = headers.indexWhere(
      (h) => h.contains('protein') || h.contains('โปรตีน'),
    );
    final fatIdx = headers.indexWhere(
      (h) => h.contains('fat') || h.contains('ไขมัน'),
    );
    final caloriesIdx = headers.indexWhere(
      (h) => h.contains('calor') || h.contains('kcal') || h.contains('energy'),
    );
    final carbsIdx = headers.indexWhere(
      (h) =>
          h.contains('carb') ||
          h.contains('carbo') ||
          h.contains('carbohydrate') ||
          h.contains('คาร์โบ') ||
          h.contains('คาร์โบไฮเดรต') ||
          h.contains('carbohydrates'),
    );

    final dessertTokens = [
      'cake',
      'เค้ก',
      'icecream',
      'ไอศกรีม',
      'dessert',
      'cookie',
      'คุกกี้',
      'pudding',
      'ขนม',
    ];
    // Also exclude any names present in the dedicated dessert CSV to be safe
    final dessertList = await loadDessertMenus();
    final dessertSet = dessertList.map((s) => s.trim().toLowerCase()).toSet();
    final carbTokens = [
      'carb',
      'carbo',
      'rice',
      'noodle',
      'pasta',
      'bread',
      'potato',
      'แป้ง',
      'ข้าว',
      'เส้น',
      'ขนมปัง',
      'grain',
      'mashed',
      'cereal',
    ];

    for (var r in rows) {
      if (nameIdx < 0 || nameIdx >= r.length) continue;
      final name = r[nameIdx].trim();
      if (name.isEmpty) continue;
      final lowerName = name.toLowerCase();
      if (dessertTokens.any((t) => lowerName.contains(t)))
        continue; // exclude desserts
      if (dessertSet.contains(lowerName))
        continue; // exclude names explicitly listed as desserts

      final catVal = (categoryIdx >= 0 && categoryIdx < r.length)
          ? r[categoryIdx].toLowerCase()
          : '';
      final combined = r.join(' ').toLowerCase();

      // Determine carb-ness: prefer explicit category, fallback to keyword scan or numeric heuristics
      bool isCarb = false;
      if (catVal.isNotEmpty && carbTokens.any((t) => catVal.contains(t)))
        isCarb = true;
      if (!isCarb) {
        if (carbTokens.any((t) => combined.contains(t))) isCarb = true;
      }

      double tryParseIdx(int idx) {
        if (idx < 0 || idx >= r.length) return double.nan;
        return double.tryParse(r[idx].replaceAll('"', '').trim()) ?? double.nan;
      }

      final prot = tryParseIdx(proteinIdx);
      final fat = tryParseIdx(fatIdx);
      final kcal = tryParseIdx(caloriesIdx);
      final carbsVal = tryParseIdx(carbsIdx);

      // If no clear carb indicators, use numeric heuristic: carbs value present and larger than protein
      if (!isCarb) {
        if (!carbsVal.isNaN && (!prot.isNaN ? carbsVal >= prot : carbsVal > 5))
          isCarb = true;
      }

      if (!isCarb) continue;

      // classify
      if (!prot.isNaN && !fat.isNaN) {
        if (prot > 3 && fat > 2) out['อาหารครบ5หมู่']!.add(name);
      }
      if (!kcal.isNaN) {
        if (kcal < 300) out['อาหารลดน้ำหนัก']!.add(name);
        if (kcal >= 400) out['อาหารให้พลังงานสูง']!.add(name);
      }
    }

    try {
      print(
        '[CsvLoader] loadCarbMenus counts: ครบ5=${out['อาหารครบ5หมู่']?.length} ลดน้ำหนัก=${out['อาหารลดน้ำหนัก']?.length} พลังงานสูง=${out['อาหารให้พลังงานสูง']?.length}',
      );
    } catch (_) {}
    return out;
  }

  static Future<List<String>> loadDessertMenus() async {
    // For desserts, use calorie_dataset.csv exclusively per requirements.
    try {
      final raw = await _loadRaw('calorie_dataset.csv');
      final lines = raw.split(RegExp(r'\r?\n'));
      if (lines.isEmpty) return [];
      final out = <String>[];
      // try to detect header and name column heuristically
      final firstCols = _splitCsvLine(lines.first);
      bool hasHeader = false;
      int nameIdx = 0;
      if (firstCols.any((c) => RegExp(r'[A-Za-z\u0E00-\u0E7F]').hasMatch(c))) {
        // assume header
        hasHeader = true;
        final lower = firstCols.map((c) => c.toLowerCase()).toList();
        final prefer = [
          'name',
          'food',
          'title',
          'th_name',
          'food_name',
          'description',
        ];
        for (var p in prefer) {
          final idx = lower.indexWhere((h) => h.contains(p));
          if (idx >= 0) {
            nameIdx = idx;
            break;
          }
        }
      }
      for (var i = (hasHeader ? 1 : 0); i < lines.length; i++) {
        final line = lines[i];
        if (line.trim().isEmpty) continue;
        final cols = _splitCsvLine(line);
        final name = (nameIdx < cols.length)
            ? cols[nameIdx].trim()
            : (cols.isNotEmpty ? cols.first.trim() : '');
        if (name.isNotEmpty) out.add(name);
      }
      // dedupe and remove numeric conflicts
      return _dedupeAndRemoveNumericConflicts(out);
    } catch (_) {
      return [];
    }
  }

  // Find a FoodItem by exact name (trimmed) using the strict Thai CSV format
  static Future<FoodItem?> getFoodItemByName(String name) async {
    final info = await loadCsvRows('Food_Nutrition_Dataset.csv');
    final header = info['header'] as String?;
    final rows = info['rows'] as List<List<String>>;
    if (header == null) return null;
    final headers = _splitCsvLine(header).map((s) => s.trim()).toList();
    final nameIdx = headers.indexOf('ชื่ออาหาร');
    final categoryIdx = headers.indexOf('หมวดหมู่');
    final kcalIdx = headers.indexOf('พลังงาน(กิโลแคลอรี)');
    final proteinIdx = headers.indexOf('โปรตีน(กรัม)');
    final carbsIdx = headers.indexOf('คาร์โบไฮเดรต(กรัม)');
    final fatIdx = headers.indexOf('ไขมัน(กรัม)');
    if (nameIdx == -1) return null;
    final target = name.trim();
    for (var r in rows) {
      if (r.length <= nameIdx) continue;
      if (r[nameIdx].toString().trim() == target) {
        final mapIdx = {
          'name': nameIdx,
          'category': categoryIdx,
          'kcal': kcalIdx,
          'protein': proteinIdx,
          'carbs': carbsIdx,
          'fat': fatIdx,
        };
        return _foodItemFromRow(r, mapIdx);
      }
    }
    return null;
  }

  // Return all item names whose CSV category column matches the provided
  // category (normalized). This is used when the UI requests menus for a
  // particular semantic category (e.g., 'อาหารครบ5หมู่').
  static Future<List<String>> _loadFoodNutritionByCategory(
    String filterCategory,
  ) async {
    // Strict loader: expect Thai headers and exact equality compare (trimmed)
    final info = await loadCsvRows('Food_Nutrition_Dataset.csv');
    final header = info['header'] as String?;
    final rows = info['rows'] as List<List<String>>;
    if (header == null) {
      print('[CsvLoader] _loadFoodNutritionByCategory ❌ header not found');
      return [];
    }
    final headers = _splitCsvLine(header).map((s) => s.trim()).toList();
    // find name/category indices (support Thai and English headers)
    int nameIdx = headers.indexWhere((h) => h == 'ชื่ออาหาร');
    int categoryIdx = headers.indexWhere((h) => h == 'หมวดหมู่');
    int kcalIdx = headers.indexWhere((h) => h == 'พลังงาน(กิโลแคลอรี)');
    int proteinIdx = headers.indexWhere((h) => h == 'โปรตีน(กรัม)');
    int carbsIdx = headers.indexWhere((h) => h == 'คาร์โบไฮเดรต(กรัม)');
    int fatIdx = headers.indexWhere((h) => h == 'ไขมัน(กรัม)');
    // try English header names if Thai not present
    if (nameIdx == -1)
      nameIdx = headers.indexWhere(
        (h) =>
            h.toLowerCase().contains('food_name') ||
            h.toLowerCase().contains('food') ||
            h.toLowerCase().contains('name'),
      );
    if (categoryIdx == -1)
      categoryIdx = headers.indexWhere(
        (h) =>
            h.toLowerCase().contains('category') ||
            h.toLowerCase().contains('type') ||
            h.toLowerCase().contains('group'),
      );
    if (kcalIdx == -1)
      kcalIdx = headers.indexWhere(
        (h) =>
            h.toLowerCase().contains('calor') ||
            h.toLowerCase().contains('kcal') ||
            h.toLowerCase().contains('energy'),
      );
    if (proteinIdx == -1)
      proteinIdx = headers.indexWhere(
        (h) =>
            h.toLowerCase().contains('protein') ||
            h.toLowerCase().contains('prot'),
      );
    if (carbsIdx == -1)
      carbsIdx = headers.indexWhere(
        (h) =>
            h.toLowerCase().contains('carb') ||
            h.toLowerCase().contains('carbo'),
      );
    if (fatIdx == -1)
      fatIdx = headers.indexWhere(
        (h) =>
            h.toLowerCase().contains('fat') ||
            h.toLowerCase().contains('lipid'),
      );
    if (categoryIdx == -1 || nameIdx == -1) {
      print(
        '[CsvLoader] _loadFoodNutritionByCategory ❌ ไม่พบคอลัมน์ ชื่ออาหาร หรือ หมวดหมู่ (Thai or English)',
      );
      print('[CsvLoader] headers=${headers}');
      return [];
    }
    final List<String> out = [];
    final selRaw = (filterCategory ?? '').toString();
    final sel = _normalize(selRaw);
    print(
      '[CsvLoader] _loadFoodNutritionByCategory SelectedRaw: "$selRaw" Normalized: "$sel" headers=${headers}',
    );
    int rowCount = 0;
    int matched = 0;
    int debugPrinted = 0;
    for (var r in rows) {
      rowCount++;
      if (r.isEmpty) continue;
      final rowCategory = (categoryIdx < r.length)
          ? r[categoryIdx].toString()
          : '';
      // map English CSV categories to Thai when necessary
      final mapped = _englishCategoryToThai(rowCategory);
      final rowNorm = _normalize(mapped);
      bool isMatch = false;
      // If filter requests a weight-loss category, use numeric kcal when possible
      if (sel.contains('ลด')) {
        double kcal = double.nan;
        if (kcalIdx >= 0 && kcalIdx < r.length) {
          kcal =
              double.tryParse(
                r[kcalIdx].toString().replaceAll('"', '').trim(),
              ) ??
              double.nan;
        }
        if (!kcal.isNaN && kcal <= 200) isMatch = true;
      } else if (sel.contains('พลังงาน') || sel.contains('พลังงานสูง')) {
        double kcal = double.nan;
        if (kcalIdx >= 0 && kcalIdx < r.length) {
          kcal =
              double.tryParse(
                r[kcalIdx].toString().replaceAll('"', '').trim(),
              ) ??
              double.nan;
        }
        if (!kcal.isNaN && kcal >= 200) isMatch = true;
      } else {
        // Default: match by mapped Thai category (from English CSV) or exact equality
        if (rowNorm == sel) isMatch = true;
      }
      if (!isMatch && debugPrinted < 50) {
        print(
          '[CsvLoader] filter="$sel" mappedRow="$mapped" rowNorm="$rowNorm" rawRowCategory="$rowCategory" kcalIdx=$kcalIdx',
        );
        debugPrinted++;
      }
      if (isMatch) {
        final name = (nameIdx < r.length) ? r[nameIdx].toString().trim() : '';
        if (name.isNotEmpty) {
          out.add(name);
          matched++;
        }
      }
    }
    print(
      '[CsvLoader] _loadFoodNutritionByCategory rowsProcessed=$rowCount matched=$matched debugShown=$debugPrinted',
    );
    // dedupe
    final seen = <String>{};
    final finalOut = <String>[];
    for (var n in out) {
      final k = n.toLowerCase().trim();
      if (!seen.contains(k)) {
        seen.add(k);
        finalOut.add(n);
      }
    }
    print('[CsvLoader] _loadFoodNutritionByCategory Selected: $filterCategory');
    print(
      '[CsvLoader] _loadFoodNutritionByCategory Matched: ${finalOut.length}',
    );
    return finalOut;
  }

  static Future<List<String>> loadEnergyDrinks() async {
    // Combine the three Starbucks files, dedupe by (name, calories) and then
    // filter for high-energy drinks (high calories or high caffeine).
    final combined = await _loadStarbucksCombined();
    final items = <String>{};
    for (var row in combined) {
      final String name = (row['name'] ?? '').toString().trim();
      if (name.isEmpty) continue;
      final lower = name.toLowerCase();
      if (lower.contains('smoothie')) continue;
      final double cal = row['cal'] is double ? row['cal'] : double.nan;
      final double caf = row['caf'] is double ? row['caf'] : double.nan;
      if ((!cal.isNaN && cal >= 200) ||
          (!caf.isNaN && caf >= 150) ||
          lower.contains('energy') ||
          lower.contains('doubleshot')) {
        items.add(name);
      }
    }
    final list = items.toList();
    return list;
  }

  static Future<List<String>> loadWeightLossDrinks() async {
    // Combine Starbucks files and select low-calorie drinks (weight-loss).
    // If Starbucks data is missing or yields no results, fall back to healthy smoothie list.
    final combined = await _loadStarbucksCombined();
    final items = <String>{};
    for (var row in combined) {
      final String name = (row['name'] ?? '').toString().trim();
      if (name.isEmpty) continue;
      final lower = name.toLowerCase();
      if (lower.contains('smoothie')) continue;
      final double cal = row['cal'] is double ? row['cal'] : double.nan;
      // weight-loss: calories <= 150 (user-provided rule)
      if (!cal.isNaN && cal <= 150) items.add(name);
    }
    var list = items.toList();
    if (list.isNotEmpty) return list;
    // fallback: healthy smoothies CSV
    try {
      final healthy = await loadHealthyDrinks();
      if (healthy.isNotEmpty) return healthy;
    } catch (_) {}
    // as a final fallback, attempt to extract low-calorie items from calorie_dataset.csv
    try {
      final raw = await _loadRaw('calorie_dataset.csv');
      final lines = raw.split(RegExp(r'\r?\n'));
      if (lines.isNotEmpty) {
        final out = <String>{};
        // attempt header detection and numeric calorie column
        final firstCols = _splitCsvLine(lines.first);
        final lowerHeader = firstCols.map((c) => c.toLowerCase()).toList();
        int nameIdx = 0;
        int calIdx = -1;
        for (var i = 0; i < lowerHeader.length; i++) {
          if (lowerHeader[i].contains('name') ||
              lowerHeader[i].contains('food') ||
              lowerHeader[i].contains('title'))
            nameIdx = i;
          if (lowerHeader[i].contains('calor') ||
              lowerHeader[i].contains('kcal') ||
              lowerHeader[i].contains('energy'))
            calIdx = i;
        }
        for (var i = 1; i < lines.length; i++) {
          final line = lines[i];
          if (line.trim().isEmpty) continue;
          final cols = _splitCsvLine(line);
          final name = (nameIdx < cols.length)
              ? cols[nameIdx].trim()
              : (cols.isNotEmpty ? cols.first.trim() : '');
          if (name.isEmpty) continue;
          double cal = double.nan;
          try {
            if (calIdx >= 0 && calIdx < cols.length)
              cal =
                  double.tryParse(cols[calIdx].replaceAll('"', '').trim()) ??
                  double.nan;
          } catch (_) {}
          if (!cal.isNaN && cal <= 150) out.add(name);
          if (out.length >= 200) break;
        }
        list = out.toList();
        return list;
      }
    } catch (_) {}
    return [];
  }

  // Helper: read and combine three Starbucks CSV files into list of rows with
  // normalized fields: name (String), cal (double), caf (double).
  static Future<List<Map<String, dynamic>>> _loadStarbucksCombined() async {
    final files = [
      'starbucks_drinkMenu_expanded.csv',
      'starbucks-menu-nutrition-drinks.csv',
      'starbucks-menu-nutrition-food.csv',
    ];
    final rows = <Map<String, dynamic>>[];
    for (var fname in files) {
      try {
        final raw = await _loadRaw(fname);
        final lines = raw.split(RegExp(r'\r?\n'));
        if (lines.isEmpty) continue;
        final header = _splitCsvLine(
          lines.first,
        ).map((h) => h.toLowerCase()).toList();
        final nameIdx = header.indexWhere(
          (h) =>
              h.contains('beverage') ||
              h.contains('name') ||
              h.contains('item'),
        );
        final calIdx = header.indexWhere(
          (h) =>
              h.contains('calor') ||
              h.contains('kcal') ||
              h.contains('calories'),
        );
        final cafIdx = header.indexWhere(
          (h) => h.contains('caffeine') || h.contains('caf'),
        );
        for (var i = 1; i < lines.length; i++) {
          final line = lines[i];
          if (line.trim().isEmpty) continue;
          final cols = _splitCsvLine(line);
          String name = '';
          if (nameIdx >= 0 && nameIdx < cols.length)
            name = cols[nameIdx].trim();
          if (name.isEmpty && cols.isNotEmpty) name = cols.first.trim();
          if (name.isEmpty) continue;
          double cal = double.nan;
          double caf = double.nan;
          try {
            if (calIdx >= 0 && calIdx < cols.length)
              cal =
                  double.tryParse(
                    cols[calIdx].replaceAll('"', '').replaceAll('-', '').trim(),
                  ) ??
                  double.nan;
          } catch (_) {}
          try {
            if (cafIdx >= 0 && cafIdx < cols.length)
              caf =
                  double.tryParse(
                    cols[cafIdx].replaceAll('"', '').replaceAll('%', '').trim(),
                  ) ??
                  double.nan;
          } catch (_) {}
          rows.add({'name': name, 'cal': cal, 'caf': caf});
        }
      } catch (_) {
        // ignore missing file but continue
      }
    }
    // dedupe by lower(name) + '||' + calories (use empty string if NaN)
    final map = <String, Map<String, dynamic>>{};
    for (var r in rows) {
      final n = (r['name'] ?? '').toString().toLowerCase().trim();
      final calKey = (r['cal'] is double && !(r['cal'] as double).isNaN)
          ? (r['cal'].toString())
          : '';
      final key = '\$' + n + '||' + calKey;
      if (!map.containsKey(key)) map[key] = r;
    }
    final out = map.values.toList();
    try {
      print(
        '[CsvLoader] _loadStarbucksCombined -> rows=${out.length} sample=${out.take(5).map((r) => r['name']).toList()}',
      );
    } catch (_) {}
    return out;
  }

  static Future<List<String>> loadHealthyDrinks() async {
    try {
      final raw = await _loadRaw('000Smoothie-Recipes - Sheet1.csv');
      final lines = raw.split(RegExp(r'\r?\n'));
      if (lines.isEmpty) return [];
      final out = <String>[];
      // skip header row (first line)
      for (var i = 1; i < lines.length; i++) {
        final line = lines[i];
        if (line.trim().isEmpty) continue;
        final cols = _splitCsvLine(line);
        final name = cols.isNotEmpty ? cols.first.trim() : '';
        if (name.isNotEmpty) out.add(name);
      }
      // dedupe
      final seen = <String>{};
      final finalOut = <String>[];
      for (var n in out) {
        final k = n.toLowerCase().trim();
        if (!seen.contains(k)) {
          seen.add(k);
          finalOut.add(n);
        }
      }
      return finalOut;
    } catch (_) {
      return [];
    }
  }
}

class FoodItem {
  final String name;
  final String category;
  final double kcal;
  final double protein;
  final double carbs;
  final double fat;

  FoodItem({
    required this.name,
    required this.category,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
  @override
  String toString() {
    return '\$name, $category\nพลังงาน: ${kcal.toStringAsFixed(kcal.truncateToDouble() == kcal ? 0 : 1)} กิโลแคลอรี\nโปรตีน: ${protein.toString()} กรัม\nคาร์โไฮเดรต: ${carbs.toString()} กรัม\nไขมัน: ${fat.toString()} กรัม';
  }

  String toDisplayLines() {
    final kcalStr = kcal % 1 == 0 ? kcal.toStringAsFixed(0) : kcal.toString();
    final protStr = protein % 1 == 0
        ? protein.toStringAsFixed(0)
        : protein.toString();
    final carbStr = carbs % 1 == 0
        ? carbs.toStringAsFixed(0)
        : carbs.toString();
    final fatStr = fat % 1 == 0 ? fat.toStringAsFixed(0) : fat.toString();
    return '${name}, ${category}\nพลังงาน: ${kcalStr} กิโลแคลอรี\nโปรตีน: ${protStr} กรัม\nคาร์โบไฮเดรต: ${carbStr} กรัม\nไขมัน: ${fatStr} กรัม';
  }
}
