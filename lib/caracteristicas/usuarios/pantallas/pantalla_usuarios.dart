import 'package:flutter/material.dart';
import 'package:book_manager/aplicacion/tema/tema_app.dart';
import 'package:book_manager/datos/modelos/actividad_app.dart';
import 'package:book_manager/datos/modelos/usuario_app.dart';
import 'package:book_manager/caracteristicas/autenticacion/servicios/servicio_autenticacion.dart';
import 'package:book_manager/compartido/servicios/servicio_historial.dart';

class UsersScreen extends StatefulWidget {
  final AppUser currentUser;

  const UsersScreen({super.key, required this.currentUser});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  late Future<List<AppUser>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    _usersFuture = AuthService.instance.users();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Usuario'),
        onPressed: () => _showUserForm(),
      ),
      body: FutureBuilder<List<AppUser>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return const Center(
              child: Text('No hay usuarios registrados.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: users.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final user = users[index];
              final isCurrentUser = _isCurrentUser(user);

              return Card(
                elevation: 0,
                color: AppColors.surface.withValues(alpha: 0.96),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  leading: CircleAvatar(
                    backgroundColor:
                        isCurrentUser ? AppColors.navy : AppColors.teal,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  title: Text(
                    user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Text(user.email),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Chip(
                            visualDensity: VisualDensity.compact,
                            label: Text(user.role.label),
                          ),
                          if (isCurrentUser)
                            const Chip(
                              visualDensity: VisualDensity.compact,
                              avatar: Icon(Icons.verified_user, size: 16),
                              label: Text('Sesión activa'),
                            ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: 'Editar usuario',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _showUserForm(user: user),
                      ),
                      IconButton(
                        tooltip: 'Eliminar usuario',
                        icon: const Icon(Icons.delete_outline),
                        color: Theme.of(context).colorScheme.error,
                        onPressed:
                            isCurrentUser ? null : () => _confirmDelete(user),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  bool _isCurrentUser(AppUser user) {
    return user.email.toLowerCase() == widget.currentUser.email.toLowerCase();
  }

  Future<void> _showUserForm({AppUser? user}) async {
    final isEditing = user != null;
    final isCurrentUser = user != null && _isCurrentUser(user);
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user?.name ?? '');
    final emailController = TextEditingController(text: user?.email ?? '');
    final passwordController = TextEditingController();
    var selectedRole = user?.role ?? AppRole.seller;
    var isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        isEditing ? 'Editar usuario' : 'Nuevo usuario',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: nameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Nombre completo',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().length < 3) {
                            return 'Ingresa un nombre válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Correo',
                          prefixIcon: Icon(Icons.alternate_email),
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          final isEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                              .hasMatch(email);
                          if (!isEmail) return 'Ingresa un correo válido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<AppRole>(
                        initialValue: selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'Rol',
                          prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                        ),
                        items: AppRole.values
                            .map(
                              (role) => DropdownMenuItem(
                                value: role,
                                child: Text(role.label),
                              ),
                            )
                            .toList(),
                        onChanged: isCurrentUser
                            ? null
                            : (role) {
                                if (role == null) return;
                                setSheetState(() => selectedRole = role);
                              },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: isEditing ? 'Nueva clave' : 'Clave',
                          helperText: isEditing
                              ? 'Déjala vacía para conservar la actual.'
                              : null,
                          prefixIcon: const Icon(Icons.lock_outline),
                        ),
                        validator: (value) {
                          final password = value ?? '';
                          if (!isEditing && password.length < 6) {
                            return 'La clave debe tener mínimo 6 caracteres';
                          }
                          if (isEditing &&
                              password.isNotEmpty &&
                              password.length < 6) {
                            return 'La clave debe tener mínimo 6 caracteres';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _saveUser(
                          sheetContext: sheetContext,
                          setSheetState: setSheetState,
                          formKey: formKey,
                          user: user,
                          nameController: nameController,
                          emailController: emailController,
                          passwordController: passwordController,
                          selectedRole: selectedRole,
                          setSaving: (value) => isSaving = value,
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: isSaving
                            ? null
                            : () => _saveUser(
                                  sheetContext: sheetContext,
                                  setSheetState: setSheetState,
                                  formKey: formKey,
                                  user: user,
                                  nameController: nameController,
                                  emailController: emailController,
                                  passwordController: passwordController,
                                  selectedRole: selectedRole,
                                  setSaving: (value) => isSaving = value,
                                ),
                        icon: isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined),
                        label: const Text('Guardar'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    // El bottom sheet puede reconstruirse durante la animacion de cierre.
    // Mantener estos controladores vivos evita que el campo use uno ya liberado.
  }

  Future<void> _saveUser({
    required BuildContext sheetContext,
    required StateSetter setSheetState,
    required GlobalKey<FormState> formKey,
    required AppUser? user,
    required TextEditingController nameController,
    required TextEditingController emailController,
    required TextEditingController passwordController,
    required AppRole selectedRole,
    required ValueChanged<bool> setSaving,
  }) async {
    if (!formKey.currentState!.validate()) return;

    setSheetState(() => setSaving(true));

    final result = user == null
        ? await AuthService.instance.createUser(
            name: nameController.text.trim(),
            email: emailController.text.trim(),
            password: passwordController.text,
            role: selectedRole,
          )
        : await AuthService.instance.updateUser(
            originalEmail: user.email,
            name: nameController.text.trim(),
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
            role: selectedRole,
          );

    if (!mounted || !sheetContext.mounted) return;

    setSheetState(() => setSaving(false));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );

    if (!result.success) return;

    await ActivityLogService.instance.record(
      type: ActivityType.users,
      title: user == null ? 'Usuario creado' : 'Usuario actualizado',
      detail: '${nameController.text.trim()} quedo como ${selectedRole.label}.',
      actor: widget.currentUser,
    );
    if (!mounted || !sheetContext.mounted) return;

    Navigator.of(sheetContext).pop();
    setState(_loadUsers);
  }

  Future<void> _confirmDelete(AppUser user) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text('¿Eliminar la cuenta de ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    final result = await AuthService.instance.deleteUser(user.email);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );

    if (result.success) {
      await ActivityLogService.instance.record(
        type: ActivityType.users,
        title: 'Usuario eliminado',
        detail: '${user.name} fue retirado del acceso local.',
        actor: widget.currentUser,
      );
      if (!mounted) return;
      setState(_loadUsers);
    }
  }
}
