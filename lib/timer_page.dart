import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'ads.dart';
import 'store.dart';

enum Phase { focus, shortBreak, longBreak }

extension PhaseText on Phase {
  String get label => switch (this) {
    Phase.focus => 'Enfoque',
    Phase.shortBreak => 'Descanso corto',
    Phase.longBreak => 'Descanso largo',
  };

  Color get color => switch (this) {
    Phase.focus => const Color(0xFFEF4444),
    Phase.shortBreak => const Color(0xFF10B981),
    Phase.longBreak => const Color(0xFF3B82F6),
  };

  IconData get icon => switch (this) {
    Phase.focus => Icons.local_fire_department,
    Phase.shortBreak => Icons.coffee,
    Phase.longBreak => Icons.self_improvement,
  };
}

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> with WidgetsBindingObserver {
  final _store = AppStore.instance;
  final _label = TextEditingController();
  Phase _phase = Phase.focus;
  int _doneInCycle = 0;
  bool _running = false;
  DateTime? _endAt;
  Duration _remaining = Duration.zero;
  Timer? _ticker;

  Duration get _total => Duration(
    minutes: switch (_phase) {
      Phase.focus => _store.settings.focus,
      Phase.shortBreak => _store.settings.shortBreak,
      Phase.longBreak => _store.settings.longBreak,
    },
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _remaining = _total;
    _store.addListener(_onSettings);
    if (const bool.fromEnvironment('DEMO')) {
      // Solo para capturas de la ficha: arranca con el reloj ya avanzado
      _remaining = _total - const Duration(minutes: 7, seconds: 18);
      WidgetsBinding.instance.addPostFrameCallback((_) => _start());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _store.removeListener(_onSettings);
    _ticker?.cancel();
    _label.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  void _onSettings() {
    if (!_running && mounted) setState(() => _remaining = _total);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _running) _tick();
  }

  void _start() {
    _endAt = DateTime.now().add(_remaining);
    _running = true;
    WakelockPlus.enable();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
    HapticFeedback.lightImpact();
    setState(() {});
  }

  void _pause() {
    _ticker?.cancel();
    _running = false;
    WakelockPlus.disable();
    setState(() {});
  }

  void _reset() {
    _pause();
    setState(() => _remaining = _total);
  }

  void _tick() {
    final left = _endAt!.difference(DateTime.now());
    if (left <= Duration.zero) {
      _finish();
    } else {
      setState(() => _remaining = left);
    }
  }

  Future<void> _finish() async {
    _ticker?.cancel();
    _running = false;
    WakelockPlus.disable();
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
    if (_phase == Phase.focus) {
      _doneInCycle++;
      await _store.addSession(
        FocusSession(
          end: DateTime.now(),
          minutes: _store.settings.focus,
          label: _label.text.trim(),
        ),
      );
      AdService.instance.maybeShowInterstitial(every: 3);
    }
    if (!mounted) return;
    final next = _phase == Phase.focus
        ? (_doneInCycle >= _store.settings.cyclesBeforeLong
              ? Phase.longBreak
              : Phase.shortBreak)
        : Phase.focus;
    if (next == Phase.longBreak) _doneInCycle = 0;
    setState(() {
      _phase = next;
      _remaining = _total;
    });
    if (_store.settings.autoStart) _start();
  }

  void _skip() {
    _pause();
    final next = _phase == Phase.focus ? Phase.shortBreak : Phase.focus;
    setState(() {
      _phase = next;
      _remaining = _total;
    });
  }

  String get _clock {
    final s =
        _remaining.inSeconds + (_remaining.inMilliseconds % 1000 > 0 ? 1 : 0);
    final m = s ~/ 60;
    return '${m.toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _phase.color;
    final total = _total.inMilliseconds;
    final progress = total == 0 ? 0.0 : 1 - _remaining.inMilliseconds / total;
    final goal = _store.settings.dailyGoal;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            for (final p in Phase.values)
              ChoiceChip(
                label: Text(switch (p) {
                  Phase.focus => 'Enfoque',
                  Phase.shortBreak => 'Pausa corta',
                  Phase.longBreak => 'Pausa larga',
                }),
                selected: _phase == p,
                onSelected: _running
                    ? null
                    : (_) => setState(() {
                        _phase = p;
                        _remaining = _total;
                      }),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Center(
          child: SizedBox(
            width: 280,
            height: 280,
            child: CustomPaint(
              painter: _RingPainter(
                progress: progress,
                color: color,
                track: theme.colorScheme.surfaceContainerHighest,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_phase.icon, color: color, size: 30),
                    Text(
                      _clock,
                      style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w800,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(_phase.label, style: theme.textTheme.titleMedium),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filledTonal(
              onPressed: _reset,
              icon: const Icon(Icons.replay),
              tooltip: 'Reiniciar',
            ),
            const SizedBox(width: 20),
            SizedBox(
              width: 150,
              height: 64,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: color),
                onPressed: _running ? _pause : _start,
                icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                label: Text(
                  _running ? 'Pausa' : 'Iniciar',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            IconButton.filledTonal(
              onPressed: _skip,
              icon: const Icon(Icons.skip_next),
              tooltip: 'Saltar',
            ),
          ],
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _label,
          decoration: InputDecoration(
            labelText: '¿En qué te vas a enfocar?',
            prefixIcon: const Icon(Icons.edit_note),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Meta de hoy: ${_store.todayCount} de $goal',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < max(goal, _store.todayCount); i++)
                    Icon(
                      Icons.circle,
                      size: 22,
                      color: i < _store.todayCount
                          ? const Color(0xFFEF4444)
                          : theme.colorScheme.surfaceContainerHighest,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Racha: ${_store.streak} ${_store.streak == 1 ? 'día' : 'días'} seguidos',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
  });

  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 18.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * pi, false, base..color = track);
    final sweep = 2 * pi * progress.clamp(0.0, 1.0);
    if (sweep > 0) {
      canvas.drawArc(
        rect,
        -pi / 2,
        sweep,
        false,
        base
          ..shader = SweepGradient(
            startAngle: -pi / 2,
            endAngle: 3 * pi / 2,
            colors: [color.withValues(alpha: 0.55), color],
            transform: const GradientRotation(-pi / 2),
          ).createShader(rect),
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
