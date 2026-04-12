import 'package:flutter/material.dart';
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
          // Tarjetas de resumen
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              SummaryCard(
                title: 'Pedidos hoy',
                value: '24',
                icon: Icons.shopping_cart,
                color: Colors.blue,
                onTap: () {
                  _showMessage(context, 'Ver pedidos del día');
                },
              ),
              SummaryCard(
                title: 'Despachos',
                value: '18',
                icon: Icons.local_shipping,
                color: Colors.green,
                onTap: () {
                  _showMessage(context, 'Ver despachos');
                },
              ),
              SummaryCard(
                title: 'Stock bajo',
                value: '7',
                icon: Icons.warning,
                color: Colors.orange,
                onTap: () {
                  _showMessage(context, 'Ver productos con stock bajo');
                },
              ),
              SummaryCard(
                title: 'Ingresos',
                value: '\$12,450',
                icon: Icons.attach_money,
                color: Colors.purple,
                onTap: () {
                  _showMessage(context, 'Ver reporte de ingresos');
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Acciones rápidas
          const Text(
            'Acciones rápidas',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
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
            ],
          ),

          const SizedBox(height: 24),

          // Pedidos recientes
          const Text(
            'Pedidos recientes',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: const Icon(Icons.shopping_cart, color: Colors.blue),
                ),
                title: const Text('Pedido #2024001'),
                subtitle: const Text('Colegio Los Álamos - 25/03/2024'),
                trailing: const Chip(
                  label: Text('Pendiente'),
                  backgroundColor: Colors.orange,
                  labelStyle: TextStyle(color: Colors.white, fontSize: 12),
                ),
                onTap: () {
                  _showMessage(context, 'Ver detalle del pedido');
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
