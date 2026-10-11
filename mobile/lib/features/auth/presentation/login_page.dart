import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import 'auth_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authControllerProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final isLoading = auth.isLoading;
    final error = auth.hasError
        ? _messageFor(
            auth.error,
            ref.read(apiClientProvider).baseUrl,
          )
        : null;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.handyman_outlined,
                        size: 34,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text('FieldTask Pro',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(
                      'Connectez-vous pour retrouver vos interventions.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Adresse e-mail',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty) {
                          return 'Saisissez votre adresse e-mail.';
                        }
                        if (!email.contains('@')) return 'Adresse e-mail invalide.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                        ),
                      ),
                      validator: (value) => (value?.isEmpty ?? true)
                          ? 'Saisissez votre mot de passe.'
                          : null,
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 16),
                      Text(error,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          )),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: isLoading ? null : _submit,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: isLoading
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Se connecter'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _messageFor(Object? error, String apiBaseUrl) {
    if (error is DioException) {
      if (error.response?.statusCode == 401) {
        return 'Adresse e-mail ou mot de passe incorrect.';
      }
      if (error.response?.statusCode == 422) {
        return 'Vérifiez les informations saisies.';
      }
      final statusCode = error.response?.statusCode;
      if (statusCode == 404) {
        return 'Route API introuvable (HTTP 404). URL utilisée : $apiBaseUrl';
      }
      if (statusCode != null && statusCode >= 500) {
        return 'Le serveur Laravel a renvoyé une erreur HTTP $statusCode. Consultez le terminal de Laravel ou backend/storage/logs/laravel.log.';
      }
      if (statusCode == 429) {
        return 'Trop de tentatives de connexion. Attendez une minute avant de réessayer.';
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError) {
        return 'Serveur inaccessible à $apiBaseUrl. Vérifiez que Laravel tourne et que cette adresse est joignable depuis l’appareil.';
      }
      if (statusCode != null) {
        return 'Erreur HTTP $statusCode renvoyée par l’API.';
      }
      if (kDebugMode && error.message != null) {
        return 'Erreur réseau : ${error.message}';
      }
    }
    if (error is FormatException || error is TypeError) {
      return 'La réponse du serveur ne respecte pas le format attendu. Vérifiez POST /api/auth/login.';
    }
    return kDebugMode
        ? 'Erreur inattendue (${error?.runtimeType ?? 'inconnue'}). Consultez la console Flutter.'
        : 'La connexion a échoué. Réessayez.';
  }
}
