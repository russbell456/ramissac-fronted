import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sistema_ocs/core/config/api_config.dart';
import 'package:sistema_ocs/core/theme/app_theme.dart';
import 'package:sistema_ocs/data/network/dio_client.dart';
import 'package:sistema_ocs/features/login/auth_notifier.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    try {
      await ref
          .read(authNotifierProvider.notifier)
          .login(_emailController.text.trim(), _passwordController.text);
      TextInput.finishAutofillContext();
    } catch (e) {
      if (mounted) {
        setState(() => _error =
            'No se pudo iniciar sesión: $e');
      }
    }
  }

  void _autofillRole(String email) {
    FocusScope.of(context).unfocus();
    setState(() {
      _emailController.text = email;
      _passwordController.text = 'admin123';
      _error = null;
    });
  }

  void _showServerConfigDialog() {
    final currentUrl = ref.read(apiBaseUrlProvider);
    final controller = TextEditingController(text: currentUrl);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(LucideIcons.server, size: 20),
            SizedBox(width: 8),
            Text('Servidor Backend', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Selecciona o ingresa la URL del backend:',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'URL del servidor',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ActionChip(
                  label: const Text('Emulador (10.0.2.2)'),
                  onPressed: () => controller.text = 'http://10.0.2.2:8000',
                ),
                ActionChip(
                  label: const Text('USB/Local (127.0.0.1)'),
                  onPressed: () => controller.text = 'http://127.0.0.1:8000',
                ),
                ActionChip(
                  label: const Text('Wi-Fi Mac (192.168.1.69)'),
                  onPressed: () => controller.text = 'http://192.168.1.69:8000',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                ApiConfig.setBaseUrl(newUrl);
                ref.read(apiBaseUrlProvider.notifier).state = newUrl;
              }
              Navigator.pop(dialogCtx);
              setState(() {});
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(authNotifierProvider) == AuthStatus.loading;
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: AutofillGroup(
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Image.asset(
                          'assets/images/logo.jpg',
                          width: 120,
                          height: 70,
                          fit: BoxFit.contain,
                          semanticLabel: 'Corporación Ramis',
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('RamissApp', style: AppTheme.headlineLarge),
                      const SizedBox(height: 4),
                      const Text('Bienvenido a Ramis',
                          style: AppTheme.bodyMedium),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _emailController,
                        enabled: !busy,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.username],
                        autocorrect: false,
                        onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                        decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                            prefixIcon: Icon(LucideIcons.mail, size: 20)),
                        validator: (value) => (value ?? '').trim().contains('@')
                            ? null
                            : 'Ingresa un correo válido',
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        enabled: !busy,
                        obscureText: _obscure,
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) {
                          if (!busy) _login();
                        },
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(LucideIcons.lock, size: 20),
                          suffixIcon: IconButton(
                            tooltip: _obscure
                                ? 'Mostrar contraseña'
                                : 'Ocultar contraseña',
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                                _obscure ? LucideIcons.eye : LucideIcons.eyeOff,
                                size: 20),
                          ),
                        ),
                        validator: (value) => (value ?? '').isNotEmpty
                            ? null
                            : 'Ingresa tu contraseña',
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!,
                            style: AppTheme.bodySmall
                                .copyWith(color: AppTheme.error)),
                      ],
                      const SizedBox(height: 20),
                      // Fila de Iniciar Sesión + Botoncito blanco y negro para autocompletar
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: busy ? null : _login,
                                child: busy
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Iniciar sesión',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Botoncito blanco y negro: autocompleta los dos campos
                          PopupMenuButton<String>(
                            enabled: !busy,
                            tooltip: 'Autocompletar rol demo',
                            offset: const Offset(0, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Colors.black12),
                            ),
                            color: Colors.white,
                            elevation: 4,
                            onSelected: _autofillRole,
                            itemBuilder: (context) => [
                              const PopupMenuItem<String>(
                                enabled: false,
                                child: Text(
                                  'AUTOCOMPLETAR ROL',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const PopupMenuDivider(height: 1),
                              const PopupMenuItem<String>(
                                value: 'trabajador@example.com',
                                child: Row(
                                  children: [
                                    Icon(LucideIcons.hardHat,
                                        size: 18, color: Colors.black),
                                    SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Campo / Residente',
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black)),
                                        Text('Juan Pérez Quispe',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.black54)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'almacenero@example.com',
                                child: Row(
                                  children: [
                                    Icon(LucideIcons.package,
                                        size: 18, color: Colors.black),
                                    SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Almacén',
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black)),
                                        Text('Carlos Mamani',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.black54)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'logistica@example.com',
                                child: Row(
                                  children: [
                                    Icon(LucideIcons.truck,
                                        size: 18, color: Colors.black),
                                    SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Logística / Compras',
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black)),
                                        Text('María López Flores',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.black54)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'admin@example.com',
                                child: Row(
                                  children: [
                                    Icon(LucideIcons.shieldCheck,
                                        size: 18, color: Colors.black),
                                    SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Administrador General',
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black)),
                                        Text('Admin Principal',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.black54)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            child: Container(
                              height: 48,
                              width: 48,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Colors.black, width: 1.5),
                              ),
                              child: const Icon(
                                LucideIcons.users,
                                color: Colors.black,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: busy ? null : _showServerConfigDialog,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.server,
                                    size: 14, color: AppTheme.textSecondary),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Consumer(
                                    builder: (_, ref, __) {
                                      final currentUrl =
                                          ref.watch(apiBaseUrlProvider);
                                      return Text(
                                        currentUrl,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTheme.bodySmall.copyWith(
                                          color: AppTheme.textSecondary,
                                          fontSize: 11,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(LucideIcons.pencil,
                                    size: 12, color: AppTheme.textSecondary),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Corporación Ramis SAC',
                        textAlign: TextAlign.center,
                        style: AppTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
