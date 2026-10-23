import 'package:flutter/material.dart';

import 'store.dart';

const _red = Color(0xFFEF4444);

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    final theme = Theme.of(context);
    final today = dayOf(DateTime.now());
    final week = [
      for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i)),
    ];
    final minutes = [for (final d in week) store.minutesOn(d)];
    final weekTotal = minutes.fold(0, (a, b) => a + b);
    final recent = store.sessions.reversed.take(12).toList();
    const names = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: _Tile(
                icon: Icons.local_fire_department,
                label: 'Racha',
                value: '${store.streak} d',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Tile(
                icon: Icons.timer,
                label: 'Esta semana',
                value: formatMinutes(weekTotal),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Tile(
                icon: Icons.emoji_events,
                label: 'Total',
                value: formatMinutes(store.totalMinutes),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
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
                'Últimos 7 días',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 160,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _BarsPainter(
                    values: minutes,
                    labels: [for (final d in week) names[d.weekday - 1]],
                    track: theme.colorScheme.surfaceContainerHighest,
                    text: theme.textTheme.bodySmall?.color ?? Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
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
                'Sesiones recientes',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              if (recent.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Aún no hay sesiones. Completa un pomodoro y aparecerá aquí.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              for (final s in recent)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.check_circle, color: _red),
                  title: Text(s.label.isEmpty ? 'Sesión de enfoque' : s.label),
                  subtitle: Text(_when(s.end)),
                  trailing: Text('${s.minutes} min'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  static String _when(DateTime d) {
    final t =
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    final diff = dayOf(DateTime.now()).difference(dayOf(d)).inDays;
    if (diff == 0) return 'Hoy, $t';
    if (diff == 1) return 'Ayer, $t';
    return '${d.day}/${d.month}, $t';
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: _red),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({
    required this.values,
    required this.labels,
    required this.track,
    required this.text,
  });

  final List<int> values;
  final List<String> labels;
  final Color track;
  final Color text;

  @override
  void paint(Canvas canvas, Size size) {
    final maxV = values.fold<int>(0, (m, v) => v > m ? v : m);
    final scale = maxV == 0 ? 1 : maxV;
    final chartH = size.height - 22;
    final slot = size.width / values.length;
    final barW = slot * 0.5;
    for (var i = 0; i < values.length; i++) {
      final x = slot * i + (slot - barW) / 2;
      final h = chartH * values[i] / scale;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 0, barW, chartH),
          const Radius.circular(8),
        ),
        Paint()..color = track,
      );
      if (h > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, chartH - h, barW, h),
            const Radius.circular(8),
          ),
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF97316), _red],
            ).createShader(Rect.fromLTWH(x, chartH - h, barW, h)),
        );
      }
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(color: text, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x + (barW - tp.width) / 2, chartH + 4));
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) => true;
}
