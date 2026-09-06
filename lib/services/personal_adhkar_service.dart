import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة "أذكاري": قائمة شخصية من مراجع الأذكار.
/// تُحفظ المفاتيح المرجعية فقط (دون نسخ نص الذكر المصدر)،
/// فلا وجود لبيانات مكررة ولا خسارة عند الحذف.
class PersonalAdhkarService extends ChangeNotifier {
  static const String _prefsKey = 'personal_adhkar_v1';
  SharedPreferences? _prefs;
  final List<String> _refKeys = [];

  /// قائمة المفاتيح المرجعية بترتيب المستخدم
  List<String> get refKeys => List.unmodifiable(_refKeys);

  bool contains(String refKey) => _refKeys.contains(refKey);

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _refKeys
      ..clear()
      ..addAll(_prefs?.getStringList(_prefsKey) ?? const []);
    notifyListeners();
  }

  Future<void> toggle(String refKey) async {
    if (_refKeys.contains(refKey)) {
      _refKeys.remove(refKey);
    } else {
      _refKeys.add(refKey);
    }
    await _persist();
    notifyListeners();
  }

  Future<void> remove(String refKey) async {
    _refKeys.remove(refKey);
    await _persist();
    notifyListeners();
  }

  Future<void> move(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final k = _refKeys.removeAt(oldIndex);
    _refKeys.insert(newIndex, k);
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    await _prefs?.setStringList(_prefsKey, _refKeys);
  }
}