import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/summary_card.dart';
import '../widgets/quick_action.dart';
import 'scanner_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryGrid(context),

          const SizedBox(height: 24),

          // Acciones rápidas
          const Text(
            'Acciones rápidas',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildQuickActions(context),

          const SizedBox(height: 24),

          // Pedidos recientes
          const Text(
            'Pedidos recientes',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          for (var index = 0; index < 3; index++) ...[
            _RecentOrderTile(
              orderNumber: '#202400${index + 1}',
              school: 'Colegio Los Alamos',
              date: '25/03/2024',
              status: 'Pendiente',
              onTap: () {
                _showMessage(context, 'Ver detalle del pedido');
              },
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(BuildContext context) {
    final cards = [
      SummaryCard(
        title: 'Pedidos hoy',
        value: '24',
        icon: Icons.shopping_cart,
        color: AppColors.teal,
        onTap: () {
          _showMessage(context, 'Ver pedidos del día');
        },
      ),
      SummaryCard(
        title: 'Despachos',
        value: '18',
        icon: Icons.local_shipping,
        color: AppColors.leaf,
        onTap: () {
          _showMessage(context, 'Ver despachos');
        },
      ),
      SummaryCard(
        title: 'Stock bajo',
        value: '7',
        icon: Icons.warning,
        color: AppColors.amber,
        onTap: () {
          _showMessage(context, 'Ver productos con stock bajo');
        },
      ),
      SummaryCard(
        title: 'Ingresos',
        value: '\$12.4K',
        icon: Icons.attach_money,
        color: AppColors.coral,
        onTap: () {
          _showMessage(context, 'Ver reporte de ingresos');
        },
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 700 ? 4 : 2;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: constraints.maxWidth < 380 ? 1.05 : 1.35,
          children: cards,
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      QuickAction(
        title: 'Nuevo pedido',
        icon: Icons.add_shopping_cart,
        onTap: () {
          _showMessage(context, 'Crear nuevo pedido');
        },
      ),
      QuickAction(
        title: 'Escanear QR',
        icon: Icons.qr_code_scanner,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ScannerScreen(),
            ),
          );
        },
      ),
      QuickAction(
        title: 'Actualizar precios',
        icon: Icons.price_change,
        onTap: () {
          _showMessage(context, 'Actualizar precios');
        },
      ),
      QuickAction(
        title: 'Generar reporte',
        icon: Icons.picture_as_pdf,
        onTap: () {
          _showMessage(context, 'Generar reporte PDF');
        },
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth < 420
            ? (constraints.maxWidth - 12) / 2
            : 180.0;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: actions
              .map(
                (action) => SizedBox(width: itemWidth, child: action),
              )
              .toList(),
        );
      },
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _RecentOrderTile extends StatelessWidget {
  final String orderNumber;
  final String school;
  final String date;
  final String status;
  final VoidCallback onTap;

  const _RecentOrderTile({
    required this.orderNumber,
    required this.school,
    required this.date,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.shopping_cart, color: AppColors.teal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pedido $orderNumber',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$school - $date',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: Color(0xFF8A5A00),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
