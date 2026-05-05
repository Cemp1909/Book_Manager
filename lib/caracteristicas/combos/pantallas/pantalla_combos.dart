import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:book_manager/aplicacion/tema/tema_app.dart';
import 'package:book_manager/datos/modelos/combo_libros.dart';
import 'package:book_manager/datos/modelos/libro.dart';
import 'package:book_manager/caracteristicas/inventario/servicios/servicio_base_datos.dart';
import 'package:book_manager/compartido/servicios/servicio_datos_temporales.dart';
import 'package:book_manager/compartido/servicios/servicio_formato_moneda.dart';

class CombosScreen extends StatefulWidget {
  final bool canEditCombos;

  const CombosScreen({
    super.key,
    this.canEditCombos = false,
  });

  @override
  State<CombosScreen> createState() => _CombosScreenState();
}

class _CombosScreenState extends State<CombosScreen> {
  final _databaseService = DatabaseService.instance;
  final _dataService = TemporaryDataService.instance;

  List<Book> _books = [];
  bool _isLoading = true;
  String? _selectedCityId;
  String? _selectedSchoolId;

  List<BookCombo> get _combos => _dataService.buildCombos(
        _books,
        cityId: _selectedCityId,
        schoolId: _selectedSchoolId,
      );

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dataService,
      builder: (context, _) {
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final combos = _combos;

        if (_books.length < 2) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Agrega mas libros al inventario para armar combos temporales.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Combos por colegio',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                ),
                if (widget.canEditCombos)
                  IconButton.filled(
                    onPressed: () => _openComboSheet(),
                    icon: const Icon(Icons.add),
                    tooltip: 'Crear combo',
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              widget.canEditCombos
                  ? 'Asigna cada combo a una ciudad y colegio para manejar listas diferentes.'
                  : 'Filtra por ciudad y colegio para ver la lista comercial correspondiente.',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            _buildFilters(),
            const SizedBox(height: 16),
            if (combos.isEmpty)
              const _EmptyFilteredCombos()
            else
              for (final combo in combos) ...[
                _ComboCard(
                  combo: combo,
                  currency: _dataService.settings.currencySymbol,
                  onTap: () => _showComboDetail(combo),
                ),
                const SizedBox(height: 12),
              ],
          ],
        );
      },
    );
  }

  Widget _buildFilters() {
    final schools = _dataService.schoolsForCity(_selectedCityId);

    return Column(
      children: [
        DropdownButtonFormField<String>(
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
          onChanged: (cityId) {
            setState(() {
              _selectedCityId = cityId;
              _selectedSchoolId = null;
            });
          },
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _selectedSchoolId,
          decoration: const InputDecoration(
            labelText: 'Colegio',
            prefixIcon: Icon(Icons.school_outlined),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Todos los colegios'),
            ),
            ...schools.map(
              (school) => DropdownMenuItem(
                value: school.id,
                child: Text(school.name),
              ),
            ),
          ],
          onChanged: (schoolId) {
            setState(() {
              _selectedSchoolId = schoolId;
            });
          },
        ),
        if (widget.canEditCombos) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'Las ciudades y colegios se administran desde la seccion Colegios.',
              style: TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (_selectedSchoolId != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openBookPricesSheet,
                icon: const Icon(Icons.price_change_outlined),
                label: Text('Precios ${_dataService.currentSchoolYear()}'),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Future<void> _openBookPricesSheet() async {
    final schoolId = _selectedSchoolId;
    if (schoolId == null) return;
    final school = _dataService.schoolById(schoolId);
    final year = _dataService.currentSchoolYear();
    final controllers = {
      for (final book in _books)
        book.isbn: TextEditingController(
          text: _dataService
              .priceForBook(book: book, schoolId: schoolId, year: year)
              .toString(),
        ),
    };

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.82,
        minChildSize: 0.5,
        maxChildSize: 0.94,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          children: [
            Text(
              'Precios $year',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              school?.name ?? 'Colegio seleccionado',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            for (final book in _books) ...[
              TextField(
                controller: controllers[book.isbn],
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: book.title,
                  helperText:
                      'Precio base: ${CurrencyFormatService.money(book.price, _dataService.settings.currencySymbol)}',
                  prefixIcon: const Icon(Icons.menu_book_outlined),
                ),
              ),
              const SizedBox(height: 12),
            ],
            FilledButton.icon(
              onPressed: () {
                for (final book in _books) {
                  final value =
                      int.tryParse(controllers[book.isbn]?.text ?? '');
                  if (value == null || value < 0) return;
                  _dataService.setBookPriceForSchool(
                    bookIsbn: book.isbn,
                    schoolId: schoolId,
                    year: year,
                    price: value,
                  );
                }
                Navigator.pop(context, true);
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Guardar precios'),
            ),
          ],
        ),
      ),
    );

    for (final controller in controllers.values) {
      controller.dispose();
    }
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Precios del colegio actualizados')),
      );
    }
  }

  Future<void> _loadBooks() async {
    try {
      final books = await _databaseService.getBooks();
      if (!mounted) return;
      setState(() {
        _books = books;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showComboDetail(BookCombo combo) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            combo.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            '${combo.cityName} - ${combo.schoolName}',
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 4),
          Text(combo.audience, style: const TextStyle(color: AppColors.muted)),
          const Divider(height: 28),
          for (final book in combo.books)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.menu_book_outlined),
              title: Text(book.title),
              subtitle: Text(book.author),
              trailing: Text(
                CurrencyFormatService.money(
                  book.price,
                  _dataService.settings.currencySymbol,
                ),
              ),
            ),
          const Divider(height: 28),
          Text(
            'Precio combo: ${CurrencyFormatService.money(combo.total, _dataService.settings.currencySymbol)}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          if (widget.canEditCombos) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _openComboSheet(initialCombo: combo);
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar combo'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openComboSheet({BookCombo? initialCombo}) async {
    final citiesWithSchools = _dataService.cities
        .where((city) => _dataService.schoolsForCity(city.id).isNotEmpty)
        .toList();
    if (citiesWithSchools.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Crea primero una ciudad y un colegio en Colegios.'),
        ),
      );
      return;
    }

    final isEditing = initialCombo != null;
    final nameController = TextEditingController(text: initialCombo?.name);
    final audienceController =
        TextEditingController(text: initialCombo?.audience);
    final discountController =
        TextEditingController(text: initialCombo?.discountPercent.toString());
    final priceController = TextEditingController(
      text: initialCombo?.customPrice?.toString() ?? '',
    );
    final selectedIsbns =
        initialCombo?.books.map((book) => book.isbn).toSet() ?? <String>{};
    var selectedCityId = initialCombo?.cityId ?? citiesWithSchools.first.id;
    if (_dataService.schoolsForCity(selectedCityId).isEmpty) {
      selectedCityId = citiesWithSchools.first.id;
    }
    var selectedSchoolId = initialCombo?.schoolId ??
        _dataService.schoolsForCity(selectedCityId).first.id;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          minChildSize: 0.6,
          maxChildSize: 0.96,
          builder: (context, scrollController) => ListView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.viewInsetsOf(context).bottom + 20,
            ),
            children: [
              Text(
                isEditing ? 'Editar combo' : 'Nuevo combo',
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedCityId,
                decoration: const InputDecoration(
                  labelText: 'Ciudad',
                  prefixIcon: Icon(Icons.location_city_outlined),
                ),
                items: citiesWithSchools
                    .map(
                      (city) => DropdownMenuItem(
                        value: city.id,
                        child: Text(city.name),
                      ),
                    )
                    .toList(),
                onChanged: (cityId) {
                  if (cityId == null) return;
                  final schools = _dataService.schoolsForCity(cityId);
                  setSheetState(() {
                    selectedCityId = cityId;
                    selectedSchoolId = schools.first.id;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedSchoolId,
                decoration: const InputDecoration(
                  labelText: 'Colegio',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
                items: _dataService
                    .schoolsForCity(selectedCityId)
                    .map(
                      (school) => DropdownMenuItem(
                        value: school.id,
                        child: Text(school.name),
                      ),
                    )
                    .toList(),
                onChanged: (schoolId) {
                  if (schoolId == null) return;
                  setSheetState(() {
                    selectedSchoolId = schoolId;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del combo',
                  prefixIcon: Icon(Icons.grid_view),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: audienceController,
                decoration: const InputDecoration(
                  labelText: 'Publico, grado o segmento',
                  prefixIcon: Icon(Icons.groups_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: discountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Descuento (%) si no hay precio fijo',
                  prefixIcon: Icon(Icons.percent),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Precio fijo para este colegio',
                  prefixIcon: Icon(Icons.price_change_outlined),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Libros del combo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              for (final book in _books)
                CheckboxListTile(
                  value: selectedIsbns.contains(book.isbn),
                  onChanged: (selected) {
                    setSheetState(() {
                      if (selected ?? false) {
                        selectedIsbns.add(book.isbn);
                      } else {
                        selectedIsbns.remove(book.isbn);
                      }
                    });
                  },
                  title: Text(book.title),
                  subtitle: Text(book.author),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  final discount = int.tryParse(discountController.text);
                  final customPrice = priceController.text.trim().isEmpty
                      ? null
                      : int.tryParse(priceController.text);
                  if (nameController.text.trim().isEmpty ||
                      audienceController.text.trim().isEmpty ||
                      discount == null ||
                      discount < 0 ||
                      discount > 99 ||
                      selectedIsbns.length < 2) {
                    return;
                  }

                  if (isEditing) {
                    _dataService.updateCombo(
                      comboId: initialCombo.id,
                      name: nameController.text.trim(),
                      audience: audienceController.text.trim(),
                      cityId: selectedCityId,
                      schoolId: selectedSchoolId,
                      discountPercent: discount,
                      customPrice: customPrice,
                      bookIsbns: selectedIsbns.toList(),
                    );
                  } else {
                    _dataService.addCombo(
                      name: nameController.text.trim(),
                      audience: audienceController.text.trim(),
                      cityId: selectedCityId,
                      schoolId: selectedSchoolId,
                      discountPercent: discount,
                      customPrice: customPrice,
                      bookIsbns: selectedIsbns.toList(),
                    );
                  }
                  Navigator.pop(context, true);
                },
                child: Text(isEditing ? 'Guardar cambios' : 'Crear combo'),
              ),
            ],
          ),
        ),
      ),
    );

    nameController.dispose();
    audienceController.dispose();
    discountController.dispose();
    priceController.dispose();

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(isEditing ? 'Combo actualizado' : 'Combo creado')),
      );
    }
  }
}

class _ComboCard extends StatelessWidget {
  final BookCombo combo;
  final String currency;
  final VoidCallback onTap;

  const _ComboCard({
    required this.combo,
    required this.currency,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.violet.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.grid_view, color: AppColors.violet),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          combo.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '${combo.cityName} - ${combo.schoolName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ChipText('${combo.books.length} libros'),
                  _ChipText('${combo.discountPercent}% descuento'),
                  if (combo.customPrice != null) const _ChipText('Precio fijo'),
                  _ChipText('Stock ${combo.stock}'),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                CurrencyFormatService.money(combo.total, currency),
                style: const TextStyle(
                  color: AppColors.tealDark,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyFilteredCombos extends StatelessWidget {
  const _EmptyFilteredCombos();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 60),
      child: Center(
        child: Text(
          'No hay combos para ese filtro de ciudad y colegio.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _ChipText extends StatelessWidget {
  final String text;

  const _ChipText(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.tealDark,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
