import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Una sesión de enfoque terminada.
class FocusSession {
  const FocusSession({
    required this.end,
    required this.minutes,
    required this.label,
  });

  final DateTime end;
  final int minutes;
  final String label;

  Map<String, dynamic> toJson() => {
    'end': end.toIso8601String(),
    'minutes': minutes,
    'label': label,
  };

  static FocusSession fromJson(Map<String, dynamic> j) => FocusSession(
    end: DateTime.parse(j['end'] as String),
    minutes: j['minutes'] as int,
    label: (j['label'] as String?) ?? '',
  );
}

class Settings {
  const Settings({
    this.focus = 25,
    this.shortBreak = 5,
    this.longBreak = 15,
    this.cyclesBeforeLong = 4,
    this.autoStart = false,
    this.dailyGoal = 4,
  });

  final int focus;
  final int shortBreak;
  final int longBreak;
  final int cyclesBeforeLong;
  final bool autoStart;
  final int dailyGoal;

  Settings copyWith({
    int? focus,
    int? shortBreak,
    int? longBreak,
    int? cyclesBeforeLong,
    bool? autoStart,
    int? dailyGoal,
  }) => Settings(
    focus: focus ?? this.focus,
    shortBreak: shortBreak ?? this.shortBreak,
    longBreak: longBreak ?? this.longBreak,
    cyclesBeforeLong: cyclesBeforeLong ?? this.cyclesBeforeLong,
    autoStart: autoStart ?? this.autoStart,
    dailyGoal: dailyGoal ?? this.dailyGoal,
  );
}

DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

/// Estado compartido y persistido en el dispositivo (sin servidores).
class AppStore extends ChangeNotifier {
  AppStore._();
  static final instance = AppStore._();

  late SharedPreferences _prefs;
  Settings settings = const Settings();
  final List<FocusSession> sessions = [];

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    settings = Settings(
      focus: _prefs.getInt('focus') ?? 25,
      shortBreak: _prefs.getInt('short') ?? 5,
      longBreak: _prefs.getInt('long') ?? 15,
      cyclesBeforeLong: _prefs.getInt('cycles') ?? 4,
      autoStart: _prefs.getBool('auto') ?? false,
      dailyGoal: _prefs.getInt('goal') ?? 4,
    );
    if (const bool.fromEnvironment('DEMO')) {
      // Datos de ejemplo solo para tomar capturas de la ficha de tienda
      final now = DateTime.now();
      const labels = ['Estudiar cálculo', 'Proyecto final', 'Leer capítulo 4', ''];
      var i = 0;
      for (var d = 0; d < 9; d++) {
        for (var k = 0; k < (d == 0 ? 3 : 2 + (d % 3)); k++) {
          sessions.add(FocusSession(
            end: now.subtract(Duration(days: d, hours: k * 2)),
            minutes: 25,
            label: labels[i++ % labels.length],
          ));
        }
      }
      sessions.sort((a, b) => a.end.compareTo(b.end));
      return;
    }
    final raw = _prefs.getString('sessions');
    if (raw != null) {
      try {
        for (final e in jsonDecode(raw) as List) {
          sessions.add(FocusSession.fromJson(e as Map<String, dynamic>));
        }
      } catch (_) {}
    }
  }

  Future<void> saveSettings(Settings s) async {
    settings = s;
    await _prefs.setInt('focus', s.focus);
    await _prefs.setInt('short', s.shortBreak);
    await _prefs.setInt('long', s.longBreak);
    await _prefs.setInt('cycles', s.cyclesBeforeLong);
    await _prefs.setBool('auto', s.autoStart);
    await _prefs.setInt('goal', s.dailyGoal);
    notifyListeners();
  }

  Future<void> addSession(FocusSession s) async {
    sessions.add(s);
    // Se conservan solo los últimos 180 días
    final limit = DateTime.now().subtract(const Duration(days: 180));
    sessions.removeWhere((e) => e.end.isBefore(limit));
    await _prefs.setString(
      'sessions',
      jsonEncode([for (final e in sessions) e.toJson()]),
    );
    notifyListeners();
  }

  Future<void> clearHistory() async {
    sessions.clear();
    await _prefs.remove('sessions');
    notifyListeners();
  }

  int get todayCount =>
      sessions.where((s) => dayOf(s.end) == dayOf(DateTime.now())).length;

  int minutesOn(DateTime day) => sessions
      .where((s) => dayOf(s.end) == dayOf(day))
      .fold(0, (a, s) => a + s.minutes);

  /// Días consecutivos (terminando hoy o ayer) con al menos una sesión.
  int get streak {
    final days = {for (final s in sessions) dayOf(s.end)};
    var d = dayOf(DateTime.now());
    if (!days.contains(d)) d = d.subtract(const Duration(days: 1));
    var n = 0;
    while (days.contains(d)) {
      n++;
      d = d.subtract(const Duration(days: 1));
    }
    return n;
  }

  int get totalMinutes => sessions.fold(0, (a, s) => a + s.minutes);
}

String formatMinutes(int m) {
  final h = m ~/ 60;
  final r = m % 60;
  if (h == 0) return '$r min';
  return r == 0 ? '$h h' : '$h h $r min';
}
