import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class CsvLoader {
  /// Load the CSV content by trying the Flutter asset first (assets/csv/)
  /// then falling back to the repository path `../../backend/data/filename` (replace `filename` with the actual file name)
  static Future<String> _loadRaw(String filename) async {
    final assetPath = 'assets/csv/menuallcsv/$filename';
    try {
      // try loading from Flutter assets first
      try {
        final s = await rootBundle.loadString(assetPath);
        print('[CsvLoader] loaded asset: $assetPath (len=${s.length})');
        return s;
      } catch (e) {
        print('[CsvLoader] asset not found: $assetPath; error: $e');
        // fall through to fallback
      }
    } catch (_) {
      // unreachable -- kept for safety
    }
    // Development fallback: try reading the asset file directly from the project
    // directory at `assets/csv/menuallcsv/` (useful when running locally without
    // rebuilding the Flutter asset bundle). Then try the repository backend/data path.
    try {
      final localPath = Directory.current.path + '/assets/csv/menuallcsv/$filename';
      final localFile = File(localPath);
      if (await localFile.exists()) {
        final s2 = await localFile.readAsString();
        print('[CsvLoader] loaded local file: $localPath (len=${s2.length})');
        return s2;
      } else {
        print('[CsvLoader] local file not found: $localPath');
      }
    } catch (e) {
      print('[CsvLoader] error reading local file: $e');
    }

    // fallback to repo path relative to app working directory
    final repoPath = Directory.current.path;
    final fallback = Directory('$repoPath/../../backend/data/$filename').path;
    final file = File(fallback);
    try {
      if (await file.exists()) {
        final s2 = await file.readAsString();
        print('[CsvLoader] loaded fallback file: $fallback (len=${s2.length})');
        return s2;
      } else {
        print('[CsvLoader] fallback file not found: $fallback');
      }
    } catch (e) {
      print('[CsvLoader] error reading fallback file $fallback: $e');
    }
    throw Exception('CSV not found as asset or at $fallback');
  }

  /// Parse and return unique non-empty values from the first column of the CSV
  static Future<List<String>> loadFirstColumn(String filename, {int max = 200}) async {
    final raw = await _loadRaw(filename);
    final lines = raw.split(RegExp(r'\r?\n'));
    final rows = <List<String>>[];
    for (var line in lines) {
      if (line.trim().isEmpty) continue;
      // naive split; still OK for many Kaggle CSVs
      final parts = line.split(',').map((s) => s.replaceAll('"', '').trim()).toList();
      if (parts.isEmpty) continue;
      rows.add(parts);
    }
    if (rows.isEmpty) return [];

    // Heuristic: choose the column that looks most like text (contains letters)
    final sampleCount = rows.length < 10 ? rows.length : 10;
    final colCount = rows.map((r) => r.length).fold<int>(0, (p, e) => e > p ? e : p);
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
        final rel = entity.path.substring(base.path.length + 1).replaceAll('\\', '/');
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
      final parts = line.split(',').map((s) => s.replaceAll('"', '').trim()).toList();
      rows.add(parts);
    }
    String? header;
    if (rows.isNotEmpty) {
      // check if first row looks like header (has non-numeric tokens)
      final first = rows.first;
      final allAlpha = first.where((c) => c.isNotEmpty).every((c) => RegExp(r'[A-Za-z\u0E00-\u0E7F]').hasMatch(c));
      if (allAlpha) {
        header = first.join(',');
        rows.removeAt(0);
      }
    }
    return {'header': header, 'rows': rows};
  }

  /// Load all CSVs and build a categorized map.
  /// Result: a map from filename -> (categoryKey -> list of items).
  /// Heuristics: if header contains category-like column name, use it; otherwise choose text-like column as item name and place under filename key.
  static Future<Map<String, Map<String, List<String>>>> loadAllCategorized() async {
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
        customTags.putIfAbsent(src, () => {}).putIfAbsent(item, () => []).addAll(tags.split(';').map((s) => s.trim()).where((s) => s.isNotEmpty));
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
          final headers = header.split(',').map((s) => s.trim().toLowerCase()).toList();
          final prefer = ['en_name','th_name','name','food','title','item','ชื่อ','อาหาร','name_en','food_name','description'];
          int found = -1;
          for (var p in prefer) {
            final idx = headers.indexWhere((h) => h == p || h.contains(p));
            if (idx >= 0) { found = idx; break; }
          }
          if (found >= 0) itemCol = found;
        }
        // fallback: choose the most text-like column while avoiding numeric-heavy columns
        if (itemCol == 0) {
          final sampleCount = rows.length < 50 ? rows.length : 50;
          final colCount = rows.map((r) => r.length).fold<int>(0, (p, e) => e > p ? e : p);
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
        if (header != null) headers = header.split(',').map((s) => s.trim().toLowerCase()).toList();
        int catCol = -1;
        int tagCol = -1;
        int caloriesCol = -1;
        int proteinCol = -1;
        for (var i = 0; i < headers.length; i++) {
          final h = headers[i];
          if (catCol < 0 && (h.contains('category') || h.contains('group') || h.contains('type') || h.contains('class') || h.contains('หมวด') || h.contains('ประเภท') || h.contains('กลุ่ม') || h.contains('ชนิด'))) catCol = i;
          if (tagCol < 0 && (h.contains('tag') || h.contains('tags') || h.contains('label') || h.contains('diet') || h.contains('goal') || h.contains('label'))) tagCol = i;
          if (caloriesCol < 0 && (h.contains('calor') || h.contains('energy') || h.contains('kcal'))) caloriesCol = i;
          if (proteinCol < 0 && (h.contains('protein') || h.contains('prot') || h.contains('โปรตีน'))) proteinCol = i;
        }

        final numericRe = RegExp(r'^[-+]?[0-9]*\.?[0-9]+$');
        final seen = <String>{};
        final Map<String, String> nameToCombined = {};

        // Prepare buckets for app categories/types
        final buckets = <String, Set<String>>{
          'เมนูโปรตีน': <String>{},
          'เมนูผักและผลไม้': <String>{},
          'เมนูคาร์โบไฮเดรต': <String>{},
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
            for (var cand in ['th_name','en_name','name','food']) {
              final idx = headers.indexWhere((h) => h == cand || h.contains(cand));
              if (idx >= 0 && idx < r.length) {
                final v = r[idx].trim();
                if (v.isNotEmpty && !numericRe.hasMatch(v)) { n = v; break; }
              }
            }
          }
          // final fallback: scan row for first text-like token that's not numeric
          if ((n.isEmpty || numericRe.hasMatch(n))) {
            for (var cell in r) {
              final v = cell.trim();
              if (v.isEmpty) continue;
              if (numericRe.hasMatch(v)) continue;
              if (letterRegex.hasMatch(v)) { n = v; break; }
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
          final catText = (catCol >= 0 && catCol < r.length) ? r[catCol].toLowerCase() : '';
          final tagText = (tagCol >= 0 && tagCol < r.length) ? r[tagCol].toLowerCase() : '';
          final combined = '$catText $tagText ${r.join(' ').toLowerCase()}';
          nameToCombined[name] = combined;

          // numeric heuristics: parse calories/protein/fiber when available
          double? kcal;
          double? prot;
          double? fiber;
          if (caloriesCol >= 0 && caloriesCol < r.length) kcal = double.tryParse(r[caloriesCol].replaceAll('"', '').trim());
          if (proteinCol >= 0 && proteinCol < r.length) prot = double.tryParse(r[proteinCol].replaceAll('"', '').trim());
          final fiberIdx = headers.indexWhere((h) => h.contains('dietary_fiber') || h.contains('fiber') || h.contains('dietary'));
          if (fiberIdx >= 0 && fiberIdx < r.length) fiber = double.tryParse(r[fiberIdx].replaceAll('"', '').trim());

          // compute flags for types and goals (clearer distribution)
          bool isProtein = false;
          bool isVeg = false;
          bool isCarb = false;
          bool isDrink = false;
          bool isWeightLoss = false;
          bool isBuildMuscle = false;

          // type keywords
          if (combined.contains('protein') || combined.contains('เนื้อ') || combined.contains('ปลา') || combined.contains('ไข่') || combined.contains('meat') || combined.contains('chicken') || combined.contains('egg') || combined.contains('โปรตีน')) isProtein = true;
          if (combined.contains('vegetable') || combined.contains('ผัก') || combined.contains('ผลไม้') || combined.contains('fruit') || combined.contains('vegan')) isVeg = true;
          if (combined.contains('carb') || combined.contains('rice') || combined.contains('noodle') || combined.contains('bread') || combined.contains('คาร์บ') || combined.contains('แป้ง') || combined.contains('grain')) isCarb = true;
          if (combined.contains('drink') || combined.contains('เครื่องดื่ม') || combined.contains('น้ำ') || combined.contains('beverage') || combined.contains('smoothie') || combined.contains('juice') || combined.contains('ชา') || combined.contains('กาแฟ')) isDrink = true;

          // goal keywords / numeric heuristics
          if (combined.contains('ลด') || combined.contains('weight') || combined.contains('loss') || combined.contains('slim') || combined.contains('ลดน้ำหนัก') || combined.contains('ลดความอ้วน')) isWeightLoss = true;
          if (combined.contains('กล้าม') || combined.contains('muscle') || combined.contains('protein') || combined.contains('สร้างกล้าม') || combined.contains('build muscle') || combined.contains('สร้างกล้ามเนื้อ')) isBuildMuscle = true;
          if (kcal != null) {
            if (kcal > 0 && kcal <= 200) isWeightLoss = true;
          }
          if (fiber != null) {
            if (fiber >= 5 && (kcal == null || kcal <= 300)) isWeightLoss = true;
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
          if (combined.contains('ครบ') || combined.contains('complete') || combined.contains('ครบ 5') || combined.contains('5 หมู่')) {
            buckets['เครื่องดื่มเพื่อสุขภาพ']!.add(name);
          } else {
            // If no goal/type keywords matched, also surface under the default drink category so the UI can show these items
            if (!isWeightLoss && !isBuildMuscle && !isProtein && !isVeg && !isCarb && !isDrink) {
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
          'เมนูโปรตีน': ['protein','โปรตีน','meat','chicken','beef','pork','fish','egg','tofu','tempeh','seafood','shrimp','salmon','tuna','steak','ไก่','ปลา','ไข่','เนื้อ'],
          'เมนูผักและผลไม้': ['vegetable','ผัก','ผลไม้','fruit','salad','vegan','leaf','ผลไม้','ผักสด','ผักต้ม','vegan'],
          'เมนูคาร์โบไฮเดรต': ['carb','carbo','rice','noodle','pasta','bread','potato','แป้ง','ข้าว','เส้น','ขนมปัง','grain','rice','mashed'],
          'เครื่องดื่ม': ['drink','เครื่องดื่ม','น้ำ','beverage','juice','smoothie','tea','coffee','กาแฟ','ชา','น้ำผลไม้']
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
        if (buckets['เครื่องดื่ม'] != null && buckets['เครื่องดื่ม']!.isNotEmpty) {
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
          final headers = header.split(',').map((s) => s.toLowerCase()).toList();
          for (var i = 0; i < headers.length; i++) {
            final h = headers[i];
            if (h.contains('category') || h.contains('type') || h.contains('group') || h.contains('class') || h.contains('หมวด') || h.contains('ประเภท') || h.contains('กลุ่ม') || h.contains('ชนิด')) {
              categoryCol = i;
            }
            if (h.contains('name') || h.contains('food') || h.contains('item') || h.contains('อาหาร') || h.contains('ชื่อ')) {
              itemCol = i;
            }
          }
        }

        // If no itemCol determined, pick most-text-like column while avoiding numeric-heavy columns
        if (itemCol == null) {
          final colCount = rows.map((r) => r.length).fold<int>(0, (p, e) => e > p ? e : p);
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
            'เครื่องดื่ม': <String>{},
            'เครื่องดื่มเพื่อสุขภาพ': <String>{},
            'เครื่องดื่มลดน้ำหนัก': <String>{},
            'เครื่องดื่มบำรุงร่างกาย / เพิ่มพลังงาน': <String>{},
          };

          // helper to safely get numeric value from row by header match
          double? findNumeric(List<String> r, List<String> headers, List<String> matchers) {
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

          final hdrs = header != null ? header.split(',').map((s) => s.toLowerCase()).toList() : <String>[];
          final nameToNumericPerFile = <String, Map<String, double?>>{};
          for (var r in rows) {
            if (itemCol >= r.length) continue;
            final name = r[itemCol].trim();
            if (name.isEmpty) continue;
            final combined = r.join(' ').toLowerCase();

              // basic type keywords — if it's a drink, keep only in drink bucket
              final bool basicIsDrink = (combined.contains('drink') || combined.contains('เครื่องดื่ม') || combined.contains('น้ำ') || combined.contains('juice') || combined.contains('tea') || combined.contains('coffee'));
              if (!basicIsDrink) {
                if (combined.contains('protein') || combined.contains('เนื้อ') || combined.contains('ปลา') || combined.contains('ไข่') || combined.contains('meat') || combined.contains('chicken') || combined.contains('egg') || combined.contains('โปรตีน')) buckets['เมนูโปรตีน']!.add(name);
                if (combined.contains('vegetable') || combined.contains('ผัก') || combined.contains('ผลไม้') || combined.contains('fruit') || combined.contains('vegan')) buckets['เมนูผักและผลไม้']!.add(name);
                if (combined.contains('carb') || combined.contains('rice') || combined.contains('noodle') || combined.contains('pasta') || combined.contains('bread') || combined.contains('แป้ง') || combined.contains('ข้าว') || combined.contains('เส้น')) buckets['เมนูคาร์โบไฮเดรต']!.add(name);
              } else {
                buckets['เครื่องดื่ม']!.add(name);
              }

            // numeric heuristics
            final kcal = findNumeric(r, hdrs, ['calor', 'energy', 'kcal']);
            final prot = findNumeric(r, hdrs, ['protein', 'prot', 'โปรตีน']);
            final fiber = findNumeric(r, hdrs, ['fiber', 'dietary_fiber']);
            // store numeric values for later supplemental heuristics
            nameToNumericPerFile[name] = {'kcal': kcal, 'prot': prot, 'fiber': fiber};
            if (kcal != null && kcal > 0 && kcal <= 200) buckets['อาหารลดน้ำหนัก']!.add(name);
            if (fiber != null && fiber >= 5 && (kcal == null || kcal <= 300)) buckets['อาหารลดน้ำหนัก']!.add(name);
            if (prot != null && prot >= 15) buckets['อาหารสร้างกล้ามเนื้อ']!.add(name);

            // keyword match for goals
            if (combined.contains('ลด') || combined.contains('weight') || combined.contains('loss') || combined.contains('slim') || combined.contains('ลดน้ำหนัก')) buckets['อาหารลดน้ำหนัก']!.add(name);
            if (combined.contains('กล้าม') || combined.contains('muscle') || combined.contains('สร้างกล้าม') || combined.contains('build muscle')) buckets['อาหารสร้างกล้ามเนื้อ']!.add(name);

            // If the row explicitly mentions 'ครบ' or 'ครบ 5' or '5 หมู่' treat it as the default drink category
            if (combined.contains('ครบ') || combined.contains('complete') || combined.contains('ครบ 5') || combined.contains('5 หมู่')) {
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
              if (buckets['อาหารลดน้ำหนัก'] == null || buckets['อาหารลดน้ำหนัก']!.isEmpty) {
                for (var nm in List<String>.from(buckets['เมนูโปรตีน']!)) {
                  final nums = nameToNumericPerFile[nm];
                  final kcal = nums != null ? nums['kcal'] : null;
                  final prot = nums != null ? nums['prot'] : null;
                  final lower = nm.toLowerCase();
                  if ((kcal != null && kcal > 0 && kcal <= 350) || (prot != null && prot >= 12) || lower.contains('low') || lower.contains('ลด')) {
                    buckets['อาหารลดน้ำหนัก']!.add(nm);
                  }
                }
              }
            } catch (_) {}

          final expandedTypeTokensFile = {
            'เมนูโปรตีน': ['protein','โปรตีน','meat','chicken','beef','pork','fish','egg','tofu','tempeh','seafood','shrimp','salmon','tuna','steak','ไก่','ปลา','ไข่','เนื้อ'],
            'เมนูผักและผลไม้': ['vegetable','ผัก','ผลไม้','fruit','salad','vegan','leaf','ผลไม้','ผักสด','ผักต้ม','vegan'],
            'เมนูคาร์โบไฮเดรต': ['carb','carbo','rice','noodle','pasta','bread','potato','แป้ง','ข้าว','เส้น','ขนมปัง','grain','rice','mashed'],
            'เครื่องดื่ม': ['drink','เครื่องดื่ม','น้ำ','beverage','juice','smoothie','tea','coffee','กาแฟ','ชา','น้ำผลไม้']
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
          if (buckets['เครื่องดื่ม'] != null && buckets['เครื่องดื่ม']!.isNotEmpty) {
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
  
  static List<String> _splitCsvLine(String line) {
    final parts = line.split(RegExp(r',(?=(?:[^\"]*\"[^\"]*\")*[^\"]*\$)'));
    return parts.map((s) {
      var t = s.trim();
      if (t.startsWith('"') && t.endsWith('"')) t = t.substring(1, t.length - 1);
      return t;
    }).toList();
  }
  
  static Future<List<String>> loadProteinMenus() async {
    // Use deterministic master parser to ensure no overlap between protein/veg/carb
    final map = await _loadFoodNutritionCategories();
    final list = map['protein'] ?? [];
    return list;
  }

  // Internal helper: parse Food_Nutrition_Dataset.csv and assign each item to one
  // of 'protein','vegetable','carb' using priority protein > vegetable > carb.
  static Future<Map<String, List<String>>> _loadFoodNutritionCategories() async {
    final raw = await _loadRaw('Food_Nutrition_Dataset.csv');
    final lines = raw.split(RegExp(r'\r?\n'));
    final result = {'protein': <String>[], 'vegetable': <String>[], 'carb': <String>[]};
    if (lines.length <= 1) return result;
    final header = _splitCsvLine(lines.first).map((h) => h.toLowerCase()).toList();
    final nameIdx = header.indexWhere((h) => h.contains('food_name') || h.contains('name'));
    int categoryIdx = header.indexWhere((h) => h.contains('category') || h.contains('type') || h.contains('group'));
    // fallback: if no explicit category, try common header names
    if (categoryIdx < 0) categoryIdx = header.indexWhere((h) => h.contains('category') || h.contains('หมวด'));

    final seen = <String>{};
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().isEmpty) continue;
      final cols = _splitCsvLine(line);
      if (nameIdx < 0 || nameIdx >= cols.length) continue;
      final name = cols[nameIdx].trim();
      if (name.isEmpty) continue;
      final key = name.toLowerCase();
      if (seen.contains(key)) continue;
      // determine category tokens
      final catText = (categoryIdx >= 0 && categoryIdx < cols.length) ? cols[categoryIdx].toLowerCase() : cols.join(' ').toLowerCase();
      bool isProtein = false, isVeg = false, isCarb = false;
      if (catText.contains('protein') || catText.contains('meat') || catText.contains('chicken') || catText.contains('fish') || catText.contains('egg') || catText.contains('pork') || catText.contains('beef') || catText.contains('seafood') || catText.contains('โปรตีน') || catText.contains('เนื้อ')) isProtein = true;
      if (catText.contains('vegetable') || catText.contains('ผัก') || catText.contains('fruit') || catText.contains('ผลไม้') || catText.contains('salad')) isVeg = true;
      if (catText.contains('carb') || catText.contains('carbo') || catText.contains('rice') || catText.contains('noodle') || catText.contains('pasta') || catText.contains('bread') || catText.contains('แป้ง') || catText.contains('ข้าว') || catText.contains('เส้น')) isCarb = true;

      // Priority assignment: protein > vegetable > carb
      if (isProtein) {
        result['protein']!.add(name);
        seen.add(key);
        continue;
      }
      if (isVeg) {
        result['vegetable']!.add(name);
        seen.add(key);
        continue;
      }
      if (isCarb) {
        result['carb']!.add(name);
        seen.add(key);
        continue;
      }
      // fallback token scan in row
      final combined = cols.join(' ').toLowerCase();
      if (combined.contains('protein') || combined.contains('meat') || combined.contains('chicken') || combined.contains('egg') || combined.contains('โปรตีน')) {
        result['protein']!.add(name);
        seen.add(key);
        continue;
      }
      if (combined.contains('vegetable') || combined.contains('ผัก') || combined.contains('ผลไม้') || combined.contains('fruit')) {
        result['vegetable']!.add(name);
        seen.add(key);
        continue;
      }
      if (combined.contains('rice') || combined.contains('noodle') || combined.contains('pasta') || combined.contains('bread') || combined.contains('ข้าว') || combined.contains('แป้ง')) {
        result['carb']!.add(name);
        seen.add(key);
        continue;
      }
    }

    // ensure dedupe and limit sizes
    result.forEach((k, list) {
      final uniq = <String>[];
      final seenLocal = <String>{};
      for (var n in list) {
        final kk = n.toLowerCase().trim();
        if (kk.isEmpty) continue;
        if (!seenLocal.contains(kk)) { seenLocal.add(kk); uniq.add(n.trim()); }
      }
      result[k] = uniq;
    });
    return result;
  }
  
  static Future<List<String>> loadVegetableMenus() async {
    final map = await _loadFoodNutritionCategories();
    return map['vegetable'] ?? [];
  }
  
  static Future<List<String>> loadCarbMenus() async {
    final map = await _loadFoodNutritionCategories();
    return map['carb'] ?? [];
  }
  
  static Future<List<String>> loadDessertMenus() async {
    // Use the Starbucks food nutrition file as the dessert source per mapping
    try {
      final raw = await _loadRaw('starbucks-menu-nutrition-food.csv');
      final lines = raw.split(RegExp(r'\r?\n'));
      if (lines.isEmpty) return [];
      final out = <String>[];
      for (var i = 1; i < lines.length; i++) {
        final line = lines[i];
        if (line.trim().isEmpty) continue;
        final cols = _splitCsvLine(line);
        final name = cols.isNotEmpty ? cols.first.trim() : '';
        if (name.isNotEmpty) out.add(name);
      }
      // dedupe and preserve insertion order
      final seen = <String>{};
      final finalOut = <String>[];
      for (var n in out) {
        final k = n.toLowerCase().trim();
        if (k.isEmpty) continue;
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
  
  static Future<List<String>> loadEnergyDrinks() async {
    final items = <String>{};
    // parse expanded file
    try {
      final raw = await _loadRaw('starbucks_drinkMenu_expanded.csv');
      final lines = raw.split(RegExp(r'\r?\n'));
      if (lines.length > 1) {
        final header = _splitCsvLine(lines.first);
        // prefer exact 'beverage' column, avoid matching 'beverage_category'
        int nameIdx = header.indexWhere((h) => h.toLowerCase().trim() == 'beverage');
        if (nameIdx < 0) {
          nameIdx = header.indexWhere((h) => h.toLowerCase().contains('beverage') && !h.toLowerCase().contains('category'));
        }
        final calIdx = header.indexWhere((h) => h.toLowerCase().contains('calor'));
        final cafIdx = header.indexWhere((h) => h.toLowerCase().contains('caffeine'));
        for (var i = 1; i < lines.length; i++) {
          final cols = _splitCsvLine(lines[i]);
          if (nameIdx < 0 || nameIdx >= cols.length) continue;
          final name = cols[nameIdx];
          final lower = name.toLowerCase();
          if (lower.contains('smoothie')) continue;
          double cal = 0; int caf = 0;
          try { if (calIdx >= 0 && calIdx < cols.length) cal = double.tryParse(cols[calIdx].replaceAll('"', '').trim()) ?? 0; } catch (_) {}
          try { if (cafIdx >= 0 && cafIdx < cols.length) caf = int.tryParse(cols[cafIdx].replaceAll('"', '').replaceAll('%', '').trim()) ?? 0; } catch (_) {}
          if (caf >= 150 || cal >= 200 || lower.contains('energy') || lower.contains('doubleshot')) items.add(name.trim());
        }
      }
    } catch (_) {}
    // parse starbucks-menu-nutrition-drinks.csv
    try {
      final raw2 = await _loadRaw('starbucks-menu-nutrition-drinks.csv');
      final lines2 = raw2.split(RegExp(r'\r?\n'));
      for (var line in lines2) {
        if (line.trim().isEmpty) continue;
        final cols = _splitCsvLine(line);
        final name = cols.first.trim();
        final lower = name.toLowerCase();
        if (lower.isEmpty) continue;
        if (lower.contains('smoothie')) continue;
        // try to parse calories if present
        if (cols.length > 1) {
          final cal = double.tryParse(cols[1].replaceAll('-', '').trim()) ?? -1;
          if (cal >= 200) items.add(name);
        }
      }
    } catch (_) {}
    return items.toList();
  }
  
  static Future<List<String>> loadWeightLossDrinks() async {
    final items = <String>{};
    try {
      final raw = await _loadRaw('starbucks_drinkMenu_expanded.csv');
      final lines = raw.split(RegExp(r'\r?\n'));
      if (lines.length > 1) {
        final header = _splitCsvLine(lines.first);
        int nameIdx = header.indexWhere((h) => h.toLowerCase().trim() == 'beverage');
        if (nameIdx < 0) {
          nameIdx = header.indexWhere((h) => h.toLowerCase().contains('beverage') && !h.toLowerCase().contains('category'));
        }
        final calIdx = header.indexWhere((h) => h.toLowerCase().contains('calor'));
        for (var i = 1; i < lines.length; i++) {
          final cols = _splitCsvLine(lines[i]);
          if (nameIdx < 0 || nameIdx >= cols.length) continue;
          final name = cols[nameIdx].trim();
          final lower = name.toLowerCase();
          if (lower.contains('smoothie')) continue;
          double cal = double.tryParse((calIdx >= 0 && calIdx < cols.length) ? cols[calIdx].replaceAll('"', '').trim() : '') ?? double.nan;
          if (!cal.isNaN && cal > -1 && cal <= 80) items.add(name);
        }
      }
    } catch (_) {}
    try {
      final raw2 = await _loadRaw('starbucks-menu-nutrition-drinks.csv');
      final lines2 = raw2.split(RegExp(r'\r?\n'));
      for (var line in lines2) {
        if (line.trim().isEmpty) continue;
        final cols = _splitCsvLine(line);
        final name = cols.first.trim();
        final lower = name.toLowerCase();
        if (lower.contains('smoothie')) continue;
        final cal = double.tryParse(cols.length > 1 ? cols[1].replaceAll('-', '').trim() : '') ?? double.nan;
        if (!cal.isNaN && cal > -1 && cal <= 80) items.add(name);
      }
    } catch (_) {}
    return items.toList();
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
