import 'package:flutter/material.dart';
import 'package:book_manager/aplicacion/tema/tema_app.dart';
import 'package:book_manager/datos/modelos/usuario_app.dart';
import 'package:book_manager/caracteristicas/autenticacion/servicios/servicio_autenticacion.dart';

const _companyLogoAsset = 'assets/branding/logo.jpeg';

class AuthScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const AuthScreen({super.key, required this.onAuthenticated});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  AppRole _selectedRole = AppRole.administrator;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.aurora),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 760;

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 48 : 18,
                  vertical: 24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Expanded(flex: 11, child: _BrandPanel()),
                              const SizedBox(width: 28),
                              Expanded(flex: 9, child: _buildAuthPanel()),
                            ],
                          )
                        : Column(
                            children: [
                              const _BrandPanel(),
                              const SizedBox(height: 18),
                              _buildAuthPanel(),
                            ],
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAuthPanel() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white),
        boxShadow: AppShadows.lifted(AppColors.navy),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: _CompanyLogo(size: 68, darkBackground: false)),
            const SizedBox(height: 18),
            _buildModeSelector(),
            const SizedBox(height: 22),
            Text(
              _isLogin ? 'Iniciar sesión' : 'Crear usuario',
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isLogin
                  ? 'Ingresa a tu panel editorial.'
                  : 'Registra la cuenta y el rol de este dispositivo.',
              style: const TextStyle(color: AppColors.muted, fontSize: 14),
            ),
            const SizedBox(height: 24),
            if (!_isLogin) ...[
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (value) {
                  if (_isLogin) return null;
                  if (value == null || value.trim().length < 3) {
                    return 'Ingresa tu nombre completo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<AppRole>(
                initialValue: _selectedRole,
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
                onChanged: (role) {
                  if (role == null) return;
                  setState(() => _selectedRole = role);
                },
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Correo',
                prefixIcon: Icon(Icons.alternate_email),
              ),
              validator: (value) {
                if (_isLogin) return null;

                final email = value?.trim() ?? '';
                final isEmail =
                    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
                if (!isEmail) return 'Ingresa un correo válido';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction:
                  _isLogin ? TextInputAction.done : TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Clave',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) {
                if (_isLogin) return null;

                final password = value ?? '';
                if (password.length < 6) {
                  return 'La clave debe tener mínimo 6 caracteres';
                }
                return null;
              },
              onFieldSubmitted: (_) {
                if (_isLogin) _submit();
              },
            ),
            if (!_isLogin) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Confirmar clave',
                  prefixIcon: const Icon(Icons.verified_user_outlined),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) {
                  if (_isLogin) return null;
                  if (value != _passwordController.text) {
                    return 'Las claves no coinciden';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _isLoading ? null : _submit,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_isLogin ? Icons.login : Icons.person_add_alt_1),
              label: Text(_isLogin ? 'Entrar' : 'Crear cuenta'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isLoading ? null : _toggleMode,
              child: Text(
                _isLogin
                    ? 'No tengo cuenta, crear usuario'
                    : 'Ya tengo cuenta, iniciar sesión',
              ),
            ),
            if (_isLogin) ...[
              const Divider(height: 28),
              TextButton.icon(
                onPressed: _isLoading ? null : _showManualVerificationDialog,
                icon: const Icon(Icons.mark_email_read_outlined),
                label: const Text('Verificar correo'),
              ),
              TextButton.icon(
                onPressed: _showResetInfo,
                icon: const Icon(Icons.help_outline),
                label: const Text('Olvidé mi clave'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _buildModeButton(label: 'Entrar', isSelected: _isLogin),
          _buildModeButton(label: 'Registro', isSelected: !_isLogin),
        ],
      ),
    );
  }

  Widget _buildModeButton({required String label, required bool isSelected}) {
    return Expanded(
      child: InkWell(
        onTap: _isLoading
            ? null
            : () {
                if (isSelected) return;
                _toggleMode();
              },
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected ? AppGradients.action : null,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.teal.withValues(alpha: 0.22),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.muted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _formKey.currentState?.reset();
      _confirmPasswordController.clear();
      _selectedRole = AppRole.administrator;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final result = _isLogin
        ? await AuthService.instance.login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          )
        : await AuthService.instance.register(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            role: _selectedRole,
          );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
      return;
    }

    if (result.authenticated) {
      widget.onAuthenticated();
      return;
    }

    if (!_isLogin) {
      await _showVerificationDialog();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
  }

  Future<void> _showVerificationDialog() async {
    final codeController = TextEditingController();
    final email = _emailController.text.trim();

    final verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Verificar correo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enviamos un codigo a $email.'),
            const SizedBox(height: 12),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Codigo',
                prefixIcon: Icon(Icons.mark_email_read_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Luego'),
          ),
          FilledButton(
            onPressed: () async {
              final result = await AuthService.instance.verifyEmail(
                email: email,
                code: codeController.text,
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(result.message)),
              );
              if (result.success) Navigator.pop(context, true);
            },
            child: const Text('Verificar'),
          ),
        ],
      ),
    );

    codeController.dispose();
    if (verified == true && mounted) {
      setState(() {
        _isLogin = true;
        _passwordController.clear();
        _confirmPasswordController.clear();
      });
    }
  }

  Future<void> _showManualVerificationDialog() async {
    final codeController = TextEditingController();
    final emailController = TextEditingController(text: _emailController.text);

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verificar correo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo',
                prefixIcon: Icon(Icons.alternate_email),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Codigo',
                prefixIcon: Icon(Icons.mark_email_read_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final result = await AuthService.instance.verifyEmail(
                email: emailController.text.trim(),
                code: codeController.text,
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(result.message)),
              );
              if (result.success) Navigator.pop(context);
            },
            child: const Text('Verificar'),
          ),
        ],
      ),
    );

    codeController.dispose();
    emailController.dispose();
  }

  void _showResetInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recuperar clave'),
        content: const Text(
          'Las cuentas se guardan en la base de datos. '
          'Si olvidaste la clave, solicita al administrador actualizar tu usuario.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppGradients.command,
        borderRadius: BorderRadius.circular(8),
        boxShadow: AppShadows.lifted(AppColors.navy),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CompanyLogo(size: 72, darkBackground: true),
          SizedBox(height: 28),
          _StatusBadge(),
          SizedBox(height: 18),
          Text(
            'Editorial Manager',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Controla inventario, pedidos y escaneos con una experiencia mas clara y rapida.',
            style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.45),
          ),
          SizedBox(height: 28),
          _FeaturePill(
            icon: Icons.inventory_2_outlined,
            label: 'Inventario ',
          ),
          SizedBox(height: 10),
          _FeaturePill(
            icon: Icons.qr_code_scanner,
            label: 'Escaneo de códigos',
          ),
          SizedBox(height: 10),
          _FeaturePill(
            icon: Icons.local_shipping_outlined,
            label: 'Operación editorial',
          ),
          SizedBox(height: 24),
          _BrandStats(),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: const Text(
        'OPERACION EDITORIAL 360',
        style: TextStyle(
          color: AppColors.amber,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _BrandStats extends StatelessWidget {
  const _BrandStats();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _MiniStat(value: '3', label: 'roles')),
        SizedBox(width: 10),
        Expanded(child: _MiniStat(value: 'QR', label: 'scanner')),
        SizedBox(width: 10),
        Expanded(child: _MiniStat(value: 'D3', label: 'analytics')),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;

  const _MiniStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyLogo extends StatelessWidget {
  final double size;
  final bool darkBackground;

  const _CompanyLogo({required this.size, required this.darkBackground});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: darkBackground ? Colors.white : AppColors.ink,
        borderRadius: BorderRadius.circular(8),
        border: darkBackground ? null : Border.all(color: AppColors.border),
      ),
      child: Image.asset(
        _companyLogoAsset,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        isAntiAlias: true,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.menu_book,
            color: darkBackground ? AppColors.teal : Colors.white,
            size: size * 0.52,
          );
        },
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.amber, size: 20),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
