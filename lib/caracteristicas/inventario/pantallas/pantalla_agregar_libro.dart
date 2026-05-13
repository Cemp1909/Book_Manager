import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:book_manager/aplicacion/tema/tema_app.dart';
import 'package:book_manager/datos/modelos/actividad_app.dart';
import 'package:book_manager/datos/modelos/libro.dart';
import 'package:book_manager/datos/modelos/usuario_app.dart';
import 'package:book_manager/caracteristicas/inventario/componentes/tarjeta_libro.dart';
import 'package:book_manager/caracteristicas/inventario/servicios/servicio_base_datos.dart';
import 'package:book_manager/compartido/servicios/servicio_historial.dart';

const _bookGradeOptions = [
  'Parvulos',
  'Prejardin',
  'Jardin',
  'Transicion',
  'Primero',
  'Segundo',
  'Tercero',
  'Cuarto',
  'Quinto',
  'General',
];

class AddBookScreen extends StatefulWidget {
  final Book? book;
  final String? initialIsbn;
  final bool persistOnSave;
  final bool embedded;
  final AppUser? currentUser;

  const AddBookScreen({
    super.key,
    this.book,
    this.initialIsbn,
    this.persistOnSave = false,
    this.embedded = false,
    this.currentUser,
  });

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _isbnController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _genreController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedGrade = 'General';
  String _coverUrl = '';
  bool _isSaving = false;

  bool get _isEditing => widget.book != null;

  @override
  void initState() {
    super.initState();

    final book = widget.book;
    if (book != null) {
      _titleController.text = book.title;
      _authorController.text = book.author;
      _isbnController.text = _formatIsbn(book.isbn);
      _priceController.text = _formatThousands(book.price);
      _stockController.text = book.stock.toString();
      _genreController.text = book.genre;
      _selectedGrade =
          _bookGradeOptions.contains(book.grade) ? book.grade : 'General';
      _descriptionController.text = book.description;
      _coverUrl = book.coverUrl;
      return;
    }

    final initialIsbn = widget.initialIsbn?.trim();
    if (initialIsbn != null) {
      _isbnController.text = _formatIsbn(initialIsbn);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 124,
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: AppShadows.lifted(AppColors.navy),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: BookCoverImage(coverUrl: _coverUrl, iconSize: 44),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Portada no requerida',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isEditing ? 'Editar ficha editorial' : 'Nueva ficha editorial',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Datos comerciales, disponibilidad e imagen visual.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 30),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Título del libro',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.title),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa el título';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _authorController,
            decoration: const InputDecoration(
              labelText: 'Autor',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa el autor';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _isbnController,
            keyboardType: TextInputType.text,
            inputFormatters: const [_IsbnInputFormatter()],
            decoration: const InputDecoration(
              labelText: 'ISBN',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.qr_code),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Por favor ingresa el ISBN';
              }
              if (_cleanIsbn(value).length < 8) {
                return 'Ingresa un ISBN válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedGrade,
            decoration: const InputDecoration(
              labelText: 'Grado',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.school_outlined),
            ),
            items: _bookGradeOptions
                .map(
                  (grade) => DropdownMenuItem(
                    value: grade,
                    child: Text(grade),
                  ),
                )
                .toList(),
            onChanged: (grade) {
              if (grade == null) return;
              setState(() => _selectedGrade = grade);
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Precio',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: const [_ThousandsInputFormatter()],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa el precio';
                    }
                    final price = _parseFormattedInt(value);
                    if (price == null || price < 0) {
                      return 'Precio inválido';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _stockController,
                  decoration: const InputDecoration(
                    labelText: 'Stock',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.inventory_2),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa stock';
                    }
                    final stock = int.tryParse(value);
                    if (stock == null || stock < 0) {
                      return 'Stock inválido';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _genreController,
            decoration: const InputDecoration(
              labelText: 'Género',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa el género';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Descripción',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.notes),
            ),
            minLines: 3,
            maxLines: 5,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Por favor ingresa la descripción';
              }
              return null;
            },
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    if (widget.embedded) {
                      _clearForm();
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _guardarLibro,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text(
                    _isSaving
                        ? 'Guardando...'
                        : _isEditing
                            ? 'Actualizar'
                            : 'Guardar',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar libro' : 'Agregar libro'),
      ),
      body: content,
    );
  }

  Future<void> _guardarLibro() async {
    if (_formKey.currentState!.validate()) {
      final book = Book(
        id: widget.book?.id,
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        isbn: _formatIsbn(_isbnController.text),
        price: _parseFormattedInt(_priceController.text) ?? 0,
        stock: int.parse(_stockController.text),
        genre: _genreController.text.trim(),
        grade: _selectedGrade,
        description: _descriptionController.text.trim(),
        coverUrl: _coverUrl,
      );

      if (widget.persistOnSave) {
        setState(() {
          _isSaving = true;
        });
        try {
          if (_isEditing) {
            await DatabaseService.instance.updateBook(book);
            await ActivityLogService.instance.record(
              type: ActivityType.inventory,
              title: 'Libro actualizado',
              detail: '${book.title} quedo con ${book.stock} unidades.',
              actor: widget.currentUser,
              entityType: 'libro',
              entityId: book.isbn,
              entityName: book.title,
            );
          } else {
            await DatabaseService.instance.insertBook(book);
            await ActivityLogService.instance.record(
              type: ActivityType.inventory,
              title: 'Libro creado',
              detail:
                  '${book.title} entro al inventario con ${book.stock} unidades.',
              actor: widget.currentUser,
              entityType: 'libro',
              entityId: book.isbn,
              entityName: book.title,
            );
          }
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Libro guardado: ${book.title}')),
          );
          _clearForm();
        } catch (error) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se pudo guardar el libro: $error')),
          );
        } finally {
          if (mounted) {
            setState(() {
              _isSaving = false;
            });
          }
        }
        return;
      }

      Navigator.pop(context, book);
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _titleController.clear();
    _authorController.clear();
    _isbnController.clear();
    _priceController.clear();
    _stockController.clear();
    _genreController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedGrade = 'General';
      _coverUrl = '';
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _isbnController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _genreController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

class _IsbnInputFormatter extends TextInputFormatter {
  const _IsbnInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = _formatIsbn(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ThousandsInputFormatter extends TextInputFormatter {
  const _ThousandsInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = _formatThousands(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

String _formatIsbn(String value) {
  final clean = _cleanIsbn(value);
  if (clean.length <= 3) return clean;

  final groups = clean.startsWith('978958') || clean.startsWith('979958')
      ? const [3, 3, 2, 4, 1]
      : clean.length <= 10
          ? const [1, 3, 5, 1]
          : const [3, 1, 5, 3, 1];
  return _splitGroups(clean, groups);
}

String _cleanIsbn(String value) {
  final clean = value.toUpperCase().replaceAll(RegExp(r'[^0-9X]'), '');
  return clean.length <= 13 ? clean : clean.substring(0, 13);
}

String _splitGroups(String value, List<int> groups) {
  final parts = <String>[];
  var start = 0;
  for (final groupSize in groups) {
    if (start >= value.length) break;
    final targetEnd = start + groupSize;
    final end = targetEnd > value.length ? value.length : targetEnd;
    parts.add(value.substring(start, end));
    start = end;
  }
  if (start < value.length) parts.add(value.substring(start));
  return parts.where((part) => part.isNotEmpty).join('-');
}

String _formatThousands(Object value) {
  final digits = value.toString().replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return '';

  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    final remaining = digits.length - index;
    buffer.write(digits[index]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write('.');
    }
  }
  return buffer.toString();
}

int? _parseFormattedInt(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return null;
  return int.tryParse(digits);
}
