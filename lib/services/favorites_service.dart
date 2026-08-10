import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// عنصر مفضّل موحّد (ذكر، آية، فصل كتاب...)
class FavoriteItem {
  final String key; // مفتاح فريد
  final String type; // dhikr / ayah / chapter
  final String typeLabel; // وصف النوع بالعربية
  final String preview; // معاينة نصية
  final String? subtitle; // المصدر أو القسم

  FavoriteItem({
    required this.key,
    required this.type,
    required this.typeLabel,
    required this.preview,
    this.subtitle,
  });

  Map<String, dynamic> toJson() => {
        'key': key,
        'type': type,
        'typeLabel': typeLabel,
        'preview': preview,
        'subtitle': subtitle,
      };

  factory FavoriteItem.fromJson(Map<String, dynamic> j) => FavoriteItem(
        key: j['key'],
        type: j['type'],
        typeLabel: j['typeLabel'] ?? '',
        preview: j['preview'] ?? '',
        subtitle: j['subtitle'],
      );
}

/// خدمة المفضلة — قائمة موحّدة محفوظة في shared_preferences
class FavoritesService extends ChangeNotifier {
  static const String _prefsKey = 'favorites_v1';
  SharedPreferences? _prefs;
  final Map<String, FavoriteItem> _items = {};

  List<FavoriteItem> get items => _items.values.toList().reversed.toList();

  bool isFavorite(String key) => _items.containsKey(key);

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_prefsKey);
    if (raw != null) {
      final list = json.decode(raw) as List;
      for (final e in list) {
        final item = FavoriteItem.fromJson(e as Map<String, dynamic>);
        _items[item.key] = item;
      }
    }
    notifyListeners();
  }

  Future<void> toggle(FavoriteItem item) async {
    if (_items.containsKey(item.key)) {
      _items.remove(item.key);
    } else {
      _items[item.key] = item;
    }
    await _persist();
    notifyListeners();
  }

  Future<void> remove(String key) async {
    _items.remove(key);
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final list = _items.values.map((e) => e.toJson()).toList();
    await _prefs?.setString(_prefsKey, json.encode(list));
  }
}
