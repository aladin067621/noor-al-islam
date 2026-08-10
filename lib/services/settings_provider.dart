import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

/// مزوّد الإعدادات — يدير الوضع الليلي، حجم الخط، وإعدادات التذكير
class SettingsProvider extends ChangeNotifier {
  SharedPreferences? _prefs;

  bool _darkMode = false;
  double _fontSize = AppConstants.defaultFontSize;

  bool _morningReminder = false;
  String _morningTime = AppConstants.defaultMorningTime;
  bool _eveningReminder = false;
  String _eveningTime = AppConstants.defaultEveningTime;

  bool _popupEnabled = false;
  int _popupInterval = AppConstants.defaultPopupInterval;
  List<String> _popupAdhkar = const ['سبحان الله', 'الحمد لله', 'الله أكبر', 'لا إله إلا الله'];

  bool get darkMode => _darkMode;
  double get fontSize => _fontSize;
  bool get morningReminder => _morningReminder;
  String get morningTime => _morningTime;
  bool get eveningReminder => _eveningReminder;
  String get eveningTime => _eveningTime;
  bool get popupEnabled => _popupEnabled;
  int get popupInterval => _popupInterval;
  List<String> get popupAdhkar => _popupAdhkar;

  ThemeMode get themeMode => _darkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    _darkMode = p.getBool(AppConstants.keyDarkMode) ?? false;
    _fontSize = p.getDouble(AppConstants.keyFontSize) ?? AppConstants.defaultFontSize;
    _morningReminder = p.getBool(AppConstants.keyMorningReminder) ?? false;
    _morningTime = p.getString(AppConstants.keyMorningTime) ?? AppConstants.defaultMorningTime;
    _eveningReminder = p.getBool(AppConstants.keyEveningReminder) ?? false;
    _eveningTime = p.getString(AppConstants.keyEveningTime) ?? AppConstants.defaultEveningTime;
    _popupEnabled = p.getBool(AppConstants.keyPopupEnabled) ?? false;
    _popupInterval = p.getInt(AppConstants.keyPopupInterval) ?? AppConstants.defaultPopupInterval;
    final stored = p.getStringList(AppConstants.keyPopupAdhkar);
    if (stored != null && stored.isNotEmpty) _popupAdhkar = stored;
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    await _prefs?.setBool(AppConstants.keyDarkMode, value);
    notifyListeners();
  }

  Future<void> setFontSize(double value) async {
    _fontSize = value;
    await _prefs?.setDouble(AppConstants.keyFontSize, value);
    notifyListeners();
  }

  Future<void> setMorningReminder(bool enabled, {String? time}) async {
    _morningReminder = enabled;
    if (time != null) _morningTime = time;
    await _prefs?.setBool(AppConstants.keyMorningReminder, enabled);
    await _prefs?.setString(AppConstants.keyMorningTime, _morningTime);
    notifyListeners();
  }

  Future<void> setEveningReminder(bool enabled, {String? time}) async {
    _eveningReminder = enabled;
    if (time != null) _eveningTime = time;
    await _prefs?.setBool(AppConstants.keyEveningReminder, enabled);
    await _prefs?.setString(AppConstants.keyEveningTime, _eveningTime);
    notifyListeners();
  }

  Future<void> setPopupEnabled(bool value) async {
    _popupEnabled = value;
    await _prefs?.setBool(AppConstants.keyPopupEnabled, value);
    notifyListeners();
  }

  Future<void> setPopupInterval(int minutes) async {
    _popupInterval = minutes;
    await _prefs?.setInt(AppConstants.keyPopupInterval, minutes);
    notifyListeners();
  }

  Future<void> setPopupAdhkar(List<String> list) async {
    _popupAdhkar = list;
    await _prefs?.setStringList(AppConstants.keyPopupAdhkar, list);
    notifyListeners();
  }

  Future<void> addCustomDhikr(String text) async {
    if (text.trim().isEmpty) return;
    final list = List<String>.from(_popupAdhkar)..add(text.trim());
    await setPopupAdhkar(list);
  }

  Future<void> removePopupDhikr(String text) async {
    final list = List<String>.from(_popupAdhkar)..remove(text);
    await setPopupAdhkar(list);
  }

  /// تحويل "HH:mm" إلى TimeOfDay
  TimeOfDay parseTime(String hhmm) {
    final parts = hhmm.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
