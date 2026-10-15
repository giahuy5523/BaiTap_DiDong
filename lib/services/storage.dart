import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class Storage {
  static Future<File> file(String name) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$name');
  }

  static Future<String?> read(String name) async {
    final f = await file(name);
    return await f.exists() ? f.readAsString() : null;
  }

  static Future<void> write(String name, String content) async {
    final f = await file(name);
    final temp = File('${f.path}.tmp');
    await temp.writeAsString(content, flush: true);
    await temp.rename(f.path);
  }

  static Future<List<Map<String, dynamic>>> loadJson(String name) async {
    final content = await read(name);
    if (content == null || content.trim().isEmpty) return [];
    return (jsonDecode(content) as List)
        .map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<void> saveJson(String name, List<Map<String, dynamic>> items) =>
      write(name, jsonEncode(items));
}
