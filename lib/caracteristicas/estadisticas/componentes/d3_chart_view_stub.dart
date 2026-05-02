import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:book_manager/aplicacion/tema/tema_app.dart';
import 'package:book_manager/caracteristicas/estadisticas/componentes/d3_chart_data.dart';

class D3ChartView extends StatelessWidget {
  final String title;
  final String? subtitle;
  final D3ChartKind kind;
  final List<D3ChartDatum> data;
  final double height;

  const D3ChartView({
    super.key,
    required this.title,
    this.subtitle,
    required this.kind,
    required this.data,
    this.height = 280,
  });

  @override
  Widget build(BuildContext context) {
    final visibleData = data.where((datum) => datum.value > 0).toList();

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: visibleData.isEmpty
            ? null
            : () => _showExpandedChart(
                  context: context,
                  title: title,
                  subtitle: subtitle,
                  kind: kind,
                  data: visibleData,
                ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                height: height - 92,
                child: visibleData.isEmpty
                    ? const Center(
                        child: Text(
                          'Sin datos para graficar',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )
                    : _NativeChart(kind: kind, data: visibleData),
              ),
              if (visibleData.isNotEmpty) ...[
                const SizedBox(height: 12),
                _ChartLegend(data: visibleData),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

void _showExpandedChart({
  required BuildContext context,
  required String title,
  required String? subtitle,
  required D3ChartKind kind,
  required List<D3ChartDatum> data,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.86,
        minChildSize: 0.56,
        maxChildSize: 0.96,
        builder: (context, scrollController) {
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                height: 320,
                child: _NativeChart(kind: kind, data: data),
              ),
              const SizedBox(height: 18),
              _ExpandedChartSummary(kind: kind, data: data),
            ],
          );
        },
      );
    },
  );
}

class _NativeChart extends StatelessWidget {
  final D3ChartKind kind;
  final List<D3ChartDatum> data;

  const _NativeChart({required this.kind, required this.data});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: switch (kind) {
        D3ChartKind.donut => _DonutChartPainter(data),
        D3ChartKind.bars => _BarChartPainter(data),
        D3ChartKind.bubble => _BubbleChartPainter(data),
      },
      child: const SizedBox.expand(),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final List<D3ChartDatum> data;

  const _ChartLegend({required this.data});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        for (final datum in data.take(5))
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _chartColor(datum.color),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Text(
                  '${datum.label}: ${_formatNumber(datum.value)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _ExpandedChartSummary extends StatelessWidget {
  final D3ChartKind kind;
  final List<D3ChartDatum> data;

  const _ExpandedChartSummary({required this.kind, required this.data});

  @override
  Widget build(BuildContext context) {
    final total = data.fold<num>(0, (sum, datum) => sum + datum.value);
    final strongest = List<D3ChartDatum>.of(data)
      ..sort((a, b) => b.value.compareTo(a.value));
    final mainDatum = strongest.first;
    final mainShare = total <= 0 ? 0 : (mainDatum.value / total * 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            kind == D3ChartKind.bubble
                ? 'El punto mas alto es ${mainDatum.label}, con valor ${_formatNumber(mainDatum.value)}.'
                : '${mainDatum.label} concentra ${_formatNumber(mainDatum.value)} de ${_formatNumber(total)} (${mainShare.toStringAsFixed(1)}%).',
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Categorias',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        for (final datum in strongest)
          _ExpandedChartRow(datum: datum, total: total),
      ],
    );
  }
}

class _ExpandedChartRow extends StatelessWidget {
  final D3ChartDatum datum;
  final num total;

  const _ExpandedChartRow({required this.datum, required this.total});

  @override
  Widget build(BuildContext context) {
    final share = total <= 0 ? 0 : datum.value / total;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: _chartColor(datum.color),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          datum.label,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        _formatNumber(datum.value),
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: share.toDouble().clamp(0, 1),
                      minHeight: 6,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _chartColor(datum.color),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${(share * 100).toStringAsFixed(1)}% del total'
                    '${datum.detail == null ? '' : '. ${datum.detail}'}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                  if (datum.secondaryValue != null || datum.size != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (datum.secondaryValue != null)
                          'Stock: ${_formatNumber(datum.secondaryValue!)}',
                        if (datum.size != null)
                          'Valor total: ${_formatNumber(datum.size!)}',
                      ].join(' · '),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<D3ChartDatum> data;

  _DonutChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.fold<num>(0, (sum, datum) => sum + datum.value);
    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.38;
    final strokeWidth = math.max(18.0, radius * 0.34);
    final rect = Rect.fromCircle(center: center, radius: radius);
    var start = -math.pi / 2;

    final backgroundPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(rect, 0, math.pi * 2, false, backgroundPaint);

    for (final datum in data) {
      final sweep = (datum.value / total) * math.pi * 2;
      final paint = Paint()
        ..color = _chartColor(datum.color)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }

    _drawCenteredText(
      canvas,
      center,
      _formatNumber(total),
      'Total',
      AppColors.ink,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

class _BarChartPainter extends CustomPainter {
  final List<D3ChartDatum> data;

  _BarChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = data.fold<num>(0, (max, datum) {
      return datum.value > max ? datum.value : max;
    });
    if (maxValue <= 0) return;

    const labelHeight = 34.0;
    final chartRect = Rect.fromLTWH(
      0,
      4,
      size.width,
      math.max(0, size.height - labelHeight),
    );
    final count = data.length;
    final gap = count > 1 ? 10.0 : 0.0;
    final barWidth = (chartRect.width - gap * (count - 1)) / count;
    final baselinePaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(chartRect.left, chartRect.bottom),
      Offset(chartRect.right, chartRect.bottom),
      baselinePaint,
    );

    for (var index = 0; index < count; index++) {
      final datum = data[index];
      final left = chartRect.left + index * (barWidth + gap);
      final barHeight = (datum.value / maxValue) * (chartRect.height - 12);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          left,
          chartRect.bottom - barHeight,
          math.max(6, barWidth),
          barHeight,
        ),
        const Radius.circular(6),
      );
      final paint = Paint()..color = _chartColor(datum.color);
      canvas.drawRRect(rect, paint);

      _drawSmallText(
        canvas,
        _formatNumber(datum.value),
        Offset(left + barWidth / 2, chartRect.bottom - barHeight - 16),
        AppColors.ink,
        align: TextAlign.center,
      );
      _drawSmallText(
        canvas,
        _shortLabel(datum.label),
        Offset(left + barWidth / 2, chartRect.bottom + 8),
        AppColors.muted,
        align: TextAlign.center,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

class _BubbleChartPainter extends CustomPainter {
  final List<D3ChartDatum> data;

  _BubbleChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final maxX = data.fold<num>(0, (max, datum) {
      return datum.value > max ? datum.value : max;
    });
    final maxY = data.fold<num>(0, (max, datum) {
      final value = datum.secondaryValue ?? datum.value;
      return value > max ? value : max;
    });
    final maxSize = data.fold<num>(0, (max, datum) {
      final value = datum.size ?? datum.value;
      return value > max ? value : max;
    });
    if (maxX <= 0 || maxY <= 0) return;

    const leftPadding = 28.0;
    const bottomPadding = 24.0;
    final plot = Rect.fromLTWH(
      leftPadding,
      8,
      math.max(0, size.width - leftPadding - 8),
      math.max(0, size.height - bottomPadding - 12),
    );
    final axisPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    canvas.drawLine(plot.bottomLeft, plot.bottomRight, axisPaint);
    canvas.drawLine(plot.bottomLeft, plot.topLeft, axisPaint);

    for (final datum in data) {
      final yValue = datum.secondaryValue ?? datum.value;
      final sizeValue = datum.size ?? datum.value;
      final x = plot.left + (datum.value / maxX) * plot.width;
      final y = plot.bottom - (yValue / maxY) * plot.height;
      final radius =
          maxSize <= 0 ? 12.0 : 8.0 + (math.sqrt(sizeValue / maxSize) * 20.0);
      final color = _chartColor(datum.color);
      canvas.drawCircle(
        Offset(x.toDouble(), y.toDouble()),
        radius,
        Paint()..color = color.withValues(alpha: 0.22),
      );
      canvas.drawCircle(
        Offset(x.toDouble(), y.toDouble()),
        radius,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    _drawSmallText(
      canvas,
      'Precio',
      Offset(plot.center.dx, plot.bottom + 8),
      AppColors.muted,
      align: TextAlign.center,
    );
    _drawSmallText(
      canvas,
      'Stock',
      Offset(14, plot.center.dy),
      AppColors.muted,
      align: TextAlign.center,
    );
  }

  @override
  bool shouldRepaint(covariant _BubbleChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

Color _chartColor(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  final value = int.tryParse(cleaned, radix: 16);
  if (value == null) return AppColors.teal;
  return Color(0xFF000000 | value);
}

String _formatNumber(num value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
  return value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
}

String _shortLabel(String label) {
  if (label.length <= 10) return label;
  return '${label.substring(0, 9)}.';
}

void _drawCenteredText(
  Canvas canvas,
  Offset center,
  String value,
  String label,
  Color color,
) {
  final valuePainter = TextPainter(
    text: TextSpan(
      text: value,
      style: TextStyle(
        color: color,
        fontSize: 24,
        fontWeight: FontWeight.w900,
      ),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout(maxWidth: 130);
  final labelPainter = TextPainter(
    text: TextSpan(
      text: label,
      style: const TextStyle(
        color: AppColors.muted,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout(maxWidth: 130);

  final top = center.dy - (valuePainter.height + labelPainter.height) / 2;
  valuePainter.paint(
    canvas,
    Offset(center.dx - valuePainter.width / 2, top),
  );
  labelPainter.paint(
    canvas,
    Offset(center.dx - labelPainter.width / 2, top + valuePainter.height),
  );
}

void _drawSmallText(
  Canvas canvas,
  String text,
  Offset offset,
  Color color, {
  TextAlign align = TextAlign.left,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.w800,
      ),
    ),
    textAlign: align,
    textDirection: TextDirection.ltr,
    maxLines: 1,
    ellipsis: '.',
  )..layout(maxWidth: 70);

  painter.paint(
    canvas,
    align == TextAlign.center
        ? Offset(offset.dx - painter.width / 2, offset.dy)
        : offset,
  );
}
