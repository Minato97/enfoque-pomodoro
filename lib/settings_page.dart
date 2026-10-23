import 'package:flutter/material.dart';

import 'store.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _store = AppStore.instance;

  Widget _stepper(
    String title,
    int value,
    int min,
    int max,
    ValueChanged<int> onChanged, {
    String unit = 'min',
  }) {
    return ListTile(
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          SizedBox(
            width: 64,
            child: Text(
              '$value $unit',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _store.settings;
    void save(Settings n) async {
      await _store.saveSettings(n);
      if (mounted) setState(() {});
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            'Duraciones',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        _stepper('Enfoque', s.focus, 5, 90, (v) => save(s.copyWith(focus: v))),
        _stepper(
          'Descanso corto',
          s.shortBreak,
          1,
          30,
          (v) => save(s.copyWith(shortBreak: v)),
        ),
        _stepper(
          'Descanso largo',
          s.longBreak,
          5,
          60,
          (v) => save(s.copyWith(longBreak: v)),
        ),
        _stepper(
          'Sesiones antes del descanso largo',
          s.cyclesBeforeLong,
          2,
          8,
          (v) => save(s.copyWith(cyclesBeforeLong: v)),
          unit: '',
        ),
        const Divider(),
        _stepper(
          'Meta diaria',
          s.dailyGoal,
          1,
          16,
          (v) => save(s.copyWith(dailyGoal: v)),
          unit: 'ses.',
        ),
        SwitchListTile(
          title: const Text('Iniciar la siguiente fase automáticamente'),
          value: s.autoStart,
          onChanged: (v) => save(s.copyWith(autoStart: v)),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.delete_outline),
          title: const Text('Borrar historial'),
          subtitle: const Text(
            'Elimina las estadísticas guardadas en este teléfono',
          ),
          onTap: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text('¿Borrar historial?'),
                content: const Text('Esta acción no se puede deshacer.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: const Text('Borrar'),
                  ),
                ],
              ),
            );
            if (ok == true) await _store.clearHistory();
          },
        ),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'La app mantiene la pantalla encendida mientras el temporizador corre. Todos tus datos se guardan solo en este dispositivo.',
            style: TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
