import 'package:flutter/material.dart';
import 'package:book_manager/aplicacion/tema/tema_app.dart';
import 'package:book_manager/caracteristicas/inventario/servicios/servicio_base_datos.dart';
import 'package:book_manager/compartido/servicios/servicio_datos_temporales.dart';
import 'package:book_manager/compartido/servicios/servicio_formato_moneda.dart';
import 'package:book_manager/compartido/servicios/servicio_historial.dart';
import 'package:book_manager/compartido/servicios/servicio_mapas.dart';
import 'package:book_manager/datos/modelos/actividad_app.dart';
import 'package:book_manager/datos/modelos/cliente_escolar.dart';
import 'package:book_manager/datos/modelos/combo_libros.dart';
import 'package:book_manager/datos/modelos/libro.dart';
import 'package:book_manager/datos/modelos/pedido_app.dart';

class SchoolsScreen extends StatefulWidget {
  final bool canManageSchools;

  const SchoolsScreen({
    super.key,
    this.canManageSchools = false,
  });

  @override
  State<SchoolsScreen> createState() => _SchoolsScreenState();
}

class _SchoolsScreenState extends State<SchoolsScreen> {
  final _dataService = TemporaryDataService.instance;
  final _databaseService = DatabaseService.instance;
  final _searchController = TextEditingController();

  List<Book> _books = [];
  String? _selectedCityId;
  String _query = '';
  bool _loadingBooks = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBooks() async {
    try {
      final books = await _databaseService.getBooks();
      if (!mounted) return;
      setState(() {
        _books = books;
        _loadingBooks = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingBooks = false);
    }
  }

  List<SchoolCustomer> _visibleSchools() {
    final cleanQuery = _query.trim().toLowerCase();
    return _dataService.schools.where((school) {
      final matchesCity =
          _selectedCityId == null || school.cityId == _selectedCityId;
      final cityName = _dataService.cityById(school.cityId)?.name ?? '';
      final matchesQuery = cleanQuery.isEmpty ||
          school.name.toLowerCase().contains(cleanQuery) ||
          cityName.toLowerCase().contains(cleanQuery) ||
          school.address.toLowerCase().contains(cleanQuery);
      return matchesCity && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dataService,
      builder: (context, _) {
        final schools = _visibleSchools();

        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: widget.canManageSchools
              ? FloatingActionButton.extended(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                  onPressed: _openSchoolSheet,
                  icon: const Icon(Icons.add_business_outlined),
                  label: const Text('Colegio'),
                )
              : null,
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              _buildFilters(),
              const SizedBox(height: 14),
              if (_loadingBooks)
                const LinearProgressIndicator()
              else if (schools.isEmpty)
                const _EmptySchools()
              else
                for (final school in schools) ...[
                  _SchoolCard(
                    school: school,
                    cityName: _cityName(school),
                    comboCount: _combosForSchool(school.id).length,
                    orderCount: _ordersForSchool(school).length,
                    onTap: () => _showSchoolDetail(school),
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilters() {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            labelText: 'Buscar colegio',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _selectedCityId,
                decoration: const InputDecoration(
                  labelText: 'Ciudad',
                  prefixIcon: Icon(Icons.location_city_outlined),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Todas las ciudades'),
                  ),
                  ..._dataService.cities.map(
                    (city) => DropdownMenuItem(
                      value: city.id,
                      child: Text(city.name),
                    ),
                  ),
                ],
                onChanged: (cityId) => setState(() {
                  _selectedCityId = cityId;
                }),
              ),
            ),
            if (widget.canManageSchools) ...[
              const SizedBox(width: 10),
              IconButton.outlined(
                tooltip: 'Crear ciudad',
                onPressed: _openCitySheet,
                icon: const Icon(Icons.add_location_alt_outlined),
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _showSchoolDetail(SchoolCustomer school) {
    final combos = _combosForSchool(school.id);
    final orders = _ordersForSchool(school);
    final history = ActivityLogService.instance.activitiesForEntity(
      entityType: 'colegio',
      entityId: school.id,
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.84,
        minChildSize: 0.5,
        maxChildSize: 0.94,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              school.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              _cityName(school),
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            _DetailRow(
              icon: Icons.location_on_outlined,
              label: 'Direccion',
              value: school.address,
            ),
            _DetailRow(
              icon: Icons.phone_outlined,
              label: 'Telefono',
              value: school.phone.isEmpty ? 'Sin telefono' : school.phone,
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: () async {
                final opened = await MapService.openAddress(
                  address: school.address,
                  city: _cityName(school),
                  label: school.name,
                );
                if (!opened && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No se pudo abrir el mapa')),
                  );
                }
              },
              icon: const Icon(Icons.map_outlined),
              label: const Text('Abrir mapa'),
            ),
            const Divider(height: 30),
            _SectionTitle(
              title: 'Combos asignados',
              count: combos.length,
            ),
            const SizedBox(height: 8),
            if (combos.isEmpty)
              const _MutedText('Este colegio todavia no tiene combos.')
            else
              for (final combo in combos)
                _CompactComboTile(
                  combo: combo,
                  currency: _dataService.settings.currencySymbol,
                ),
            const Divider(height: 30),
            _SectionTitle(
              title: 'Pedidos recientes',
              count: orders.length,
            ),
            const SizedBox(height: 8),
            if (orders.isEmpty)
              const _MutedText('No hay pedidos registrados para este colegio.')
            else
              for (final order in orders.take(5))
                _CompactOrderTile(
                  order: order,
                  currency: _dataService.settings.currencySymbol,
                ),
            const Divider(height: 30),
            _SectionTitle(
              title: 'Historial del colegio',
              count: history.length,
            ),
            const SizedBox(height: 8),
            if (history.isEmpty)
              const _MutedText(
                  'Aun no hay cambios registrados para este colegio.')
            else
              for (final activity in history.take(5))
                _CompactHistoryTile(
                  title: activity.title,
                  detail: activity.detail,
                ),
          ],
        ),
      ),
    );
  }

  List<BookCombo> _combosForSchool(String schoolId) {
    return _dataService.buildCombos(_books, schoolId: schoolId);
  }

  List<AppOrder> _ordersForSchool(SchoolCustomer school) {
    return _dataService.orders
        .where((order) =>
            order.customer.toLowerCase() == school.name.toLowerCase())
        .toList();
  }

  String _cityName(SchoolCustomer school) {
    return _dataService.cityById(school.cityId)?.name ?? 'Ciudad sin asignar';
  }

  Future<void> _openCitySheet() async {
    final controller = TextEditingController();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Nueva ciudad',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Nombre de la ciudad',
                prefixIcon: Icon(Icons.location_city_outlined),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                if (controller.text.trim().isEmpty) return;
                _dataService.addCity(controller.text);
                ActivityLogService.instance.record(
                  type: ActivityType.settings,
                  title: 'Ciudad creada',
                  detail: controller.text.trim(),
                  entityType: 'ciudad',
                  entityId: controller.text.trim().toLowerCase(),
                  entityName: controller.text.trim(),
                );
                Navigator.pop(context, true);
              },
              child: const Text('Guardar ciudad'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ciudad agregada')),
      );
    }
  }

  Future<void> _openSchoolSheet() async {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    var cityId = _selectedCityId ?? _dataService.cities.first.id;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Nuevo colegio',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: cityId,
                decoration: const InputDecoration(
                  labelText: 'Ciudad',
                  prefixIcon: Icon(Icons.location_city_outlined),
                ),
                items: _dataService.cities
                    .map(
                      (city) => DropdownMenuItem(
                        value: city.id,
                        child: Text(city.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setSheetState(() => cityId = value);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del colegio',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Direccion',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefono',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty) return;
                  _dataService.addSchool(
                    cityId: cityId,
                    name: nameController.text,
                    address: addressController.text,
                    phone: phoneController.text,
                  );
                  final school = _dataService.schools.last;
                  ActivityLogService.instance.record(
                    type: ActivityType.settings,
                    title: 'Colegio creado',
                    detail:
                        '${school.name} fue creado en ${_cityName(school)}.',
                    entityType: 'colegio',
                    entityId: school.id,
                    entityName: school.name,
                  );
                  Navigator.pop(context, true);
                },
                child: const Text('Guardar colegio'),
              ),
            ],
          ),
        ),
      ),
    );

    nameController.dispose();
    addressController.dispose();
    phoneController.dispose();
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Colegio agregado')),
      );
    }
  }
}

class _SchoolCard extends StatelessWidget {
  final SchoolCustomer school;
  final String cityName;
  final int comboCount;
  final int orderCount;
  final VoidCallback onTap;

  const _SchoolCard({
    required this.school,
    required this.cityName,
    required this.comboCount,
    required this.orderCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surface.withValues(alpha: 0.96),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.teal.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.school_outlined, color: AppColors.teal),
        ),
        title: Text(
          school.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '$cityName - ${school.address}\n$comboCount combos - $orderCount pedidos',
            style: const TextStyle(color: AppColors.muted),
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.teal),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final int count;

  const _SectionTitle({
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ),
        Chip(
          visualDensity: VisualDensity.compact,
          label: Text(count.toString()),
        ),
      ],
    );
  }
}

class _CompactComboTile extends StatelessWidget {
  final BookCombo combo;
  final String currency;

  const _CompactComboTile({
    required this.combo,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.grid_view_outlined),
      title: Text(combo.name),
      subtitle: Text('${combo.books.length} libros - ${combo.audience}'),
      trailing: Text(
        CurrencyFormatService.money(combo.total, currency),
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _CompactOrderTile extends StatelessWidget {
  final AppOrder order;
  final String currency;

  const _CompactOrderTile({
    required this.order,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.shopping_cart_outlined),
      title: Text('Pedido #${order.id}'),
      subtitle: Text(order.status.label),
      trailing: Text(
        CurrencyFormatService.money(order.total, currency),
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _CompactHistoryTile extends StatelessWidget {
  final String title;
  final String detail;

  const _CompactHistoryTile({
    required this.title,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.history_outlined),
      title: Text(title),
      subtitle: Text(detail),
    );
  }
}

class _MutedText extends StatelessWidget {
  final String text;

  const _MutedText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.muted,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _EmptySchools extends StatelessWidget {
  const _EmptySchools();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 80),
      child: Center(
        child: Text(
          'No hay colegios para este filtro.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
