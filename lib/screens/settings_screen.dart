import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/company_settings.dart';
import '../services/temporary_data_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _currencyController = TextEditingController();
  final _lowStockController = TextEditingController();
  final _dataService = TemporaryDataService.instance;

  @override
  void initState() {
    super.initState();
    final settings = _dataService.settings;
    _companyController.text = settings.companyName;
    _currencyController.text = settings.currencySymbol;
    _lowStockController.text = settings.lowStockLimit.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuracion')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppColors.teal.withValues(alpha: 0.2)),
              ),
              child: const Text(
                'Esta configuracion queda local por ahora. Cuando conectes la base de datos, solo cambiamos el servicio.',
                style: TextStyle(
                  color: AppColors.tealDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _companyController,
              decoration: const InputDecoration(
                labelText: 'Nombre de empresa',
                prefixIcon: Icon(Icons.business_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Escribe el nombre de la empresa';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _currencyController,
              decoration: const InputDecoration(
                labelText: 'Moneda',
                prefixIcon: Icon(Icons.attach_money),
              ),
              maxLength: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Escribe el simbolo de moneda';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _lowStockController,
              decoration: const InputDecoration(
                labelText: 'Limite de stock bajo',
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                final stock = int.tryParse(value ?? '');
                if (stock == null || stock < 1) {
                  return 'Escribe un numero mayor a 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Guardar configuracion'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    await _dataService.saveSettings(
      CompanySettings(
        companyName: _companyController.text.trim(),
        currencySymbol: _currencyController.text.trim(),
        lowStockLimit: int.parse(_lowStockController.text),
      ),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuracion guardada')),
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _companyController.dispose();
    _currencyController.dispose();
    _lowStockController.dispose();
    super.dispose();
  }
}
