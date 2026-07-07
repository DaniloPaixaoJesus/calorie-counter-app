import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:calorie_counter_app/design_system/app_spacing.dart';
import 'package:calorie_counter_app/design_system/layout_breakpoints.dart';
import 'package:calorie_counter_app/features/home/view_model.dart';
import 'package:calorie_counter_app/models/app_settings.dart';
import 'package:calorie_counter_app/models/macronutrients.dart';
import 'package:calorie_counter_app/services/auth/google_auth_service.dart';
import 'package:calorie_counter_app/services/subscription/subscription_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ProfileInsightsPage extends StatefulWidget {
  const ProfileInsightsPage({super.key});

  @override
  State<ProfileInsightsPage> createState() => _ProfileInsightsPageState();
}

class _ProfileInsightsPageState extends State<ProfileInsightsPage> {
  late final TextEditingController _goalController;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SubscriptionService>().settings;
    _goalController = TextEditingController(
      text: settings.dailyCalorieGoal.toString(),
    );
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _saveGoal() async {
    final goal = int.tryParse(_goalController.text.trim());
    if (goal == null) return;
    await context.read<SubscriptionService>().updateDailyCalorieGoal(goal);
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Meta diaria atualizada.')),
    );
  }

  Future<void> _logout() async {
    try {
      await GoogleAuthService().signOut();
    } catch (_) {}
    if (!mounted) return;
    await context.read<SubscriptionService>().logout();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final settings = context.watch<SubscriptionService>().settings;
    final days = _lastFiveDays(vm);
    final horizontalPadding =
        LayoutBreakpoints.isSmall(context) ? AppSpacing.md : AppSpacing.lg;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil Premium')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: LayoutBreakpoints.contentMaxWidth(context),
            ),
            child: ListView(
              padding: EdgeInsets.all(horizontalPadding),
              children: [
                _UserSummary(settings: settings),
                const SizedBox(height: AppSpacing.md),
                _GoalCard(
                  controller: _goalController,
                  onSave: _saveGoal,
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sair da conta'),
                ),
                const SizedBox(height: AppSpacing.md),
                _LineChartCard(
                  title: 'Calorias dos ultimos 5 dias',
                  subtitle: 'Consumo diario',
                  series: [
                    _ChartSeries(
                      label: 'Calorias',
                      values:
                          days.map((day) => day.calories.toDouble()).toList(),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                  labels: days.map((day) => day.label).toList(),
                  valueSuffix: 'kcal',
                ),
                const SizedBox(height: AppSpacing.md),
                _MacroLineChartCard(days: days),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<_DailyInsight> _lastFiveDays(HomeViewModel vm) {
    final now = DateTime.now();
    final dates = List<DateTime>.generate(5, (index) {
      final day = now.subtract(Duration(days: 4 - index));
      return DateTime(day.year, day.month, day.day);
    });
    final formatter = DateFormat('dd/MM', 'pt_BR');

    return [
      for (final date in dates)
        _DailyInsight(
          label: formatter.format(date),
          calories: vm.meals
              .where((meal) =>
                  meal.timestamp.year == date.year &&
                  meal.timestamp.month == date.month &&
                  meal.timestamp.day == date.day)
              .fold(0, (sum, meal) => sum + meal.calorias),
          macronutrients: vm.meals
              .where((meal) =>
                  meal.timestamp.year == date.year &&
                  meal.timestamp.month == date.month &&
                  meal.timestamp.day == date.day)
              .fold(
                Macronutrients.zero,
                (sum, meal) =>
                    sum + (meal.macronutrients ?? Macronutrients.zero),
              ),
        ),
    ];
  }
}

class _DailyInsight {
  final String label;
  final int calories;
  final Macronutrients macronutrients;

  const _DailyInsight({
    required this.label,
    required this.calories,
    required this.macronutrients,
  });
}

class _UserSummary extends StatelessWidget {
  final AppSettings settings;

  const _UserSummary({required this.settings});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _ProfilePhoto(settings: settings),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    settings.userName ?? 'Usuario Premium',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    settings.userEmail ?? 'E-mail nao informado',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Row(
                    children: [
                      Icon(
                        Icons.workspace_premium_rounded,
                        color: Color(0xFFF2BE1A),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Text('Plano Premium'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilePhoto extends StatelessWidget {
  final AppSettings settings;

  const _ProfilePhoto({required this.settings});

  @override
  Widget build(BuildContext context) {
    final photoPath = settings.userPhotoAssetPath;
    final hasPhoto = photoPath != null && photoPath.isNotEmpty;
    final hasRemotePhoto = hasPhoto && photoPath.startsWith('http');

    return CircleAvatar(
      radius: 32,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      backgroundImage: hasPhoto
          ? (hasRemotePhoto
              ? NetworkImage(photoPath)
              : AssetImage(photoPath) as ImageProvider)
          : null,
      child: hasPhoto
          ? null
          : Icon(
              Icons.person_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSave;

  const _GoalCard({
    required this.controller,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Meta de calorias diaria',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Meta em kcal',
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                FilledButton(
                  onPressed: onSave,
                  child: const Text('Salvar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroLineChartCard extends StatelessWidget {
  final List<_DailyInsight> days;

  const _MacroLineChartCard({required this.days});

  @override
  Widget build(BuildContext context) {
    final labels = days.map((day) => day.label).toList();

    return _LineChartCard(
      title: 'Macros dos ultimos 5 dias',
      subtitle: 'Gramas por dia',
      series: [
        _ChartSeries(
          label: 'Proteinas',
          values: days
              .map((day) => day.macronutrients.protein.grams.toDouble())
              .toList(),
          color: days.first.macronutrients.protein.color,
        ),
        _ChartSeries(
          label: 'Gorduras',
          values: days
              .map((day) => day.macronutrients.fat.grams.toDouble())
              .toList(),
          color: days.first.macronutrients.fat.color,
        ),
        _ChartSeries(
          label: 'Carboidratos',
          values: days
              .map((day) => day.macronutrients.carbs.grams.toDouble())
              .toList(),
          color: days.first.macronutrients.carbs.color,
        ),
      ],
      labels: labels,
      valueSuffix: 'g',
    );
  }
}

class _LineChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_ChartSeries> series;
  final List<String> labels;
  final String valueSuffix;

  const _LineChartCard({
    required this.title,
    required this.subtitle,
    required this.series,
    required this.labels,
    required this.valueSuffix,
  });

  @override
  Widget build(BuildContext context) {
    final primarySeries = series.first;
    final latest =
        primarySeries.values.isEmpty ? 0 : primarySeries.values.last.round();
    final average = primarySeries.values.isEmpty
        ? 0
        : (primarySeries.values.reduce((a, b) => a + b) /
                primarySeries.values.length)
            .round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                _ChartValuePill(
                  value: '$latest $valueSuffix',
                  color: primarySeries.color,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '$subtitle - media $average $valueSuffix',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 210,
              child: _ProfileChartSurface(
                series: series,
                labels: labels,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final item in series)
                  _LegendChip(
                    color: item.color,
                    label: item.label,
                    value: '${item.latest.round()} $valueSuffix',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileChartSurface extends StatelessWidget {
  final List<_ChartSeries> series;
  final List<String> labels;

  const _ProfileChartSurface({
    required this.series,
    required this.labels,
  });

  bool get _hasData {
    return series.any((item) => item.values.any((value) => value > 0));
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasData) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'Sem dados no período',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      );
    }

    return CustomPaint(
      painter: _ProfileLineChartPainter(
        series: series,
        labels: labels,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _ChartValuePill extends StatelessWidget {
  final String value;
  final Color color;

  const _ChartValuePill({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendChip({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(width: AppSpacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _ChartSeries {
  final String label;
  final List<double> values;
  final Color color;

  const _ChartSeries({
    required this.label,
    required this.values,
    required this.color,
  });

  double get latest => values.isEmpty ? 0 : values.last;
}

class _ProfileLineChartPainter extends CustomPainter {
  final List<_ChartSeries> series;
  final List<String> labels;

  const _ProfileLineChartPainter({
    required this.series,
    required this.labels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const left = 36.0;
    const top = 10.0;
    const right = 6.0;
    const bottom = 32.0;
    final chartRect = Rect.fromLTWH(
      left,
      top,
      math.max(size.width - left - right, 1),
      math.max(size.height - top - bottom, 1),
    );
    final axisPaint = Paint()
      ..color = const Color(0xFFD8DED4)
      ..strokeWidth = 1;

    final allValues = [
      for (final item in series)
        for (final value in item.values) value,
    ];
    final rawMax = allValues.fold<double>(
      0,
      (max, value) => math.max(max, value),
    );
    final maxValue = _niceMax(math.max(rawMax, 1));

    final labelPainter = TextPainter(
      textAlign: TextAlign.right,
      textDirection: ui.TextDirection.ltr,
    );
    final yTicks = [maxValue, maxValue * 0.5, 0.0];
    for (final tick in yTicks) {
      final y = chartRect.bottom -
          (tick / maxValue).clamp(0.0, 1.0) * chartRect.height;
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        Paint()
          ..color = const Color(0xFFD8DED4).withValues(alpha: 0.55)
          ..strokeWidth = 1,
      );
      labelPainter.text = TextSpan(
        text: tick.round().toString(),
        style: const TextStyle(color: Color(0xFF6B7280), fontSize: 10),
      );
      labelPainter.layout(minWidth: 24, maxWidth: 24);
      labelPainter.paint(
        canvas,
        Offset(chartRect.left - labelPainter.width - 5, y - 6),
      );
    }

    canvas.drawLine(chartRect.bottomLeft, chartRect.bottomRight, axisPaint);
    canvas.drawLine(chartRect.bottomLeft, chartRect.topLeft, axisPaint);

    for (final item in series) {
      if (item.values.isEmpty) continue;
      final points = [
        for (var i = 0; i < item.values.length; i++)
          Offset(
            item.values.length == 1
                ? chartRect.center.dx
                : chartRect.left +
                    (chartRect.width / (item.values.length - 1)) * i,
            chartRect.bottom -
                (item.values[i] / maxValue).clamp(0.0, 1.0) * chartRect.height,
          ),
      ];
      final path = Path();
      for (var i = 0; i < points.length; i++) {
        final point = points[i];
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      if (series.length == 1 && points.length > 1) {
        final fillPath = Path.from(path)
          ..lineTo(points.last.dx, chartRect.bottom)
          ..lineTo(points.first.dx, chartRect.bottom)
          ..close();
        canvas.drawPath(
          fillPath,
          Paint()
            ..color = item.color.withValues(alpha: 0.08)
            ..style = PaintingStyle.fill,
        );
      }
      final linePaint = Paint()
        ..color = item.color
        ..strokeWidth = series.length == 1 ? 3.5 : 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, linePaint);

      final dotPaint = Paint()..color = item.color;
      final dotBorderPaint = Paint()..color = const Color(0xFFFFFFFF);
      for (final point in points) {
        canvas.drawCircle(point, 4.5, dotBorderPaint);
        canvas.drawCircle(point, 3.2, dotPaint);
      }
    }

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
    );
    final labelIndexes = _visibleLabelIndexes(labels.length);
    for (final i in labelIndexes) {
      final x = labels.length == 1
          ? chartRect.center.dx
          : chartRect.left + (chartRect.width / (labels.length - 1)) * i;
      textPainter.text = TextSpan(
        text: labels[i],
        style: const TextStyle(color: Color(0xFF6B7280), fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, chartRect.bottom + 10),
      );
    }
  }

  List<int> _visibleLabelIndexes(int count) {
    if (count <= 0) return const [];
    if (count <= 3) return [for (var i = 0; i < count; i++) i];
    return [0, count ~/ 2, count - 1];
  }

  double _niceMax(double value) {
    if (value <= 10) return 10;
    if (value <= 50) return (value / 10).ceil() * 10;
    if (value <= 200) return (value / 25).ceil() * 25;
    if (value <= 1000) return (value / 100).ceil() * 100;
    return (value / 250).ceil() * 250;
  }

  @override
  bool shouldRepaint(covariant _ProfileLineChartPainter oldDelegate) {
    return oldDelegate.series != series || oldDelegate.labels != labels;
  }
}
