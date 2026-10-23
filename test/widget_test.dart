import 'package:enfoque_pomodoro/store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final s = AppStore.instance;
    s.sessions.clear();
    await s.load();
  });

  FocusSession at(int daysAgo, {int min = 25}) => FocusSession(
        end: DateTime.now().subtract(Duration(days: daysAgo)),
        minutes: min,
        label: '',
      );

  test('racha cuenta días consecutivos', () async {
    final s = AppStore.instance;
    await s.addSession(at(0));
    await s.addSession(at(1));
    await s.addSession(at(2));
    await s.addSession(at(4));
    expect(s.streak, 3);
  });

  test('racha sigue viva si lo último fue ayer', () async {
    final s = AppStore.instance;
    await s.addSession(at(1));
    expect(s.streak, 1);
  });

  test('minutos por día y total', () async {
    final s = AppStore.instance;
    await s.addSession(at(0, min: 25));
    await s.addSession(at(0, min: 50));
    await s.addSession(at(3, min: 25));
    expect(s.minutesOn(DateTime.now()), 75);
    expect(s.totalMinutes, 100);
    expect(s.todayCount, 2);
  });

  test('formato de minutos', () {
    expect(formatMinutes(45), '45 min');
    expect(formatMinutes(120), '2 h');
    expect(formatMinutes(135), '2 h 15 min');
  });

  test('ajustes se guardan', () async {
    final s = AppStore.instance;
    await s.saveSettings(s.settings.copyWith(focus: 50));
    expect(s.settings.focus, 50);
  });
}
