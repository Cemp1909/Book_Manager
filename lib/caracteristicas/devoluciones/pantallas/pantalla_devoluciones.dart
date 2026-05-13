import 'package:flutter/material.dart';
import 'package:book_manager/aplicacion/tema/tema_app.dart';
import 'package:book_manager/compartido/servicios/servicio_datos_temporales.dart';
import 'package:book_manager/datos/modelos/devolucion_app.dart';

class ReturnsScreen extends StatelessWidget {
  const ReturnsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataService = TemporaryDataService.instance;

    return AnimatedBuilder(
      animation: dataService,
      builder: (context, _) {
        final returns = dataService.returns;
        final restocked = returns
            .where((record) => record.status == ReturnStatus.restocked)
            .length;
        final pending = returns
            .where((record) => record.status == ReturnStatus.registered)
            .length;
        final notRestockable = returns
            .where((record) => record.status == ReturnStatus.notRestockable)
            .length;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SummaryCard(
              total: returns.length,
              restocked: restocked,
              pending: pending,
              notRestockable: notRestockable,
            ),
            const SizedBox(height: 16),
            if (returns.isEmpty)
              const _EmptyReturns()
            else
              for (final record in returns) ...[
                _ReturnCard(record: record),
                const SizedBox(height: 12),
              ],
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int total;
  final int restocked;
  final int pending;
  final int notRestockable;

  const _SummaryCard({
    required this.total,
    required this.restocked,
    required this.pending,
    required this.notRestockable,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 620;
            final metrics = [
              _MetricData('Total', total.toString(), AppColors.teal),
              _MetricData('Registradas', pending.toString(), AppColors.amber),
              _MetricData('Reintegradas', restocked.toString(), AppColors.leaf),
              _MetricData(
                'No reintegrables',
                notRestockable.toString(),
                AppColors.coral,
              ),
            ];

            if (compact) {
              return Column(
                children: [
                  for (final metric in metrics) _SummaryMetric(metric: metric),
                ],
              );
            }

            return Row(
              children: [
                for (final metric in metrics)
                  Expanded(child: _SummaryMetric(metric: metric)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final _MetricData metric;

  const _SummaryMetric({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: metric.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              metric.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            metric.value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _ReturnCard extends StatelessWidget {
  final ReturnRecord record;

  const _ReturnCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(record.status);

    return Card(
      elevation: 0,
      color: AppColors.surface.withValues(alpha: 0.96),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.itemTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${record.customer} - Pedido #${record.orderId}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Chip(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: color.withValues(alpha: 0.12),
                  label: Text(record.status.label),
                  labelStyle: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.event_outlined,
                  label: _dateLabel(record.date),
                ),
                _InfoChip(
                  icon: Icons.inventory_2_outlined,
                  label: '${record.quantity} unidad(es)',
                ),
                _InfoChip(
                  icon: record.restock
                      ? Icons.assignment_returned_outlined
                      : Icons.assignment_return_outlined,
                  label:
                      record.restock ? 'Reintegra inventario' : 'Sin reintegro',
                ),
              ],
            ),
            if (record.reason.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                record.reason,
                style: const TextStyle(height: 1.35),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.tealDark),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _EmptyReturns extends StatelessWidget {
  const _EmptyReturns();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.assignment_return_outlined,
              color: AppColors.teal,
              size: 38,
            ),
            SizedBox(height: 10),
            Text(
              'No hay devoluciones registradas',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricData {
  final String label;
  final String value;
  final Color color;

  const _MetricData(this.label, this.value, this.color);
}

Color _statusColor(ReturnStatus status) {
  return switch (status) {
    ReturnStatus.registered => AppColors.amber,
    ReturnStatus.restocked => AppColors.leaf,
    ReturnStatus.notRestockable => AppColors.coral,
  };
}

String _dateLabel(DateTime date) {
  return '${_two(date.day)}/${_two(date.month)}/${date.year}';
}

String _two(int value) => value.toString().padLeft(2, '0');
