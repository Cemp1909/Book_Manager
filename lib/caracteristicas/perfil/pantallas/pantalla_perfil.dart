import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:book_manager/aplicacion/tema/tema_app.dart';
import 'package:book_manager/datos/modelos/usuario_app.dart';
import 'package:book_manager/caracteristicas/autenticacion/servicios/servicio_autenticacion.dart';

class ProfileScreen extends StatelessWidget {
  final AppUser user;
  final VoidCallback onLogout;

  const ProfileScreen({
    super.key,
    required this.user,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.soft(AppColors.teal),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.teal,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                user.name,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                user.email,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Chip(
                label: Text(user.role.label),
                backgroundColor: AppColors.teal.withValues(alpha: 0.12),
                labelStyle: const TextStyle(
                  color: AppColors.tealDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: 0.08),
        const SizedBox(height: 16),
        _ProfileAction(
          icon: Icons.security_outlined,
          title: 'Permisos',
          subtitle: _permissionsLabel(user),
        ),
        const SizedBox(height: 10),
        _ProfileAction(
          icon: Icons.logout,
          title: 'Cerrar sesion',
          subtitle: 'Salir de Book Manager',
          color: AppColors.coral,
          onTap: () async {
            await AuthService.instance.logout();
            onLogout();
          },
        ),
      ],
    );
  }

  String _permissionsLabel(AppUser user) {
    final permissions = <String>[
      if (user.canUseScanner) 'Escaner',
      if (user.canManageSettings) 'Configuracion',
    ];
    return permissions.isEmpty ? 'Acceso basico' : permissions.join(' · ');
  }
}

class _ProfileAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _ProfileAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.color = AppColors.teal,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null) Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.06);
  }
}
