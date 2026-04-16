import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../widgets/zwilling_logo.dart';
import '../services/api_service.dart';
import 'login_webview.dart';
import 'register_screen.dart';

/// First screen: Login and Register buttons.
/// Login → card login WebView (card login first, toggle to login).
/// Register → password popup (must be boldrocchi@zwill2025) → Register page.
class LoginLandingScreen extends StatelessWidget {
  const LoginLandingScreen({super.key});

  Future<void> _onRegisterPressed(BuildContext context) async {
    final controller = TextEditingController();
    String? error;
    bool obscure = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> validateAndSubmit() async {
            final typed = controller.text.trim();
            final currentPassword = await ApiService.getRegisterPassword();
            if (typed == currentPassword) {
              if (ctx.mounted) Navigator.pop(ctx, true);
            } else {
              setDialogState(() => error = 'Wrong password');
            }
          }

          return AlertDialog(
            title: const Text('Register', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Enter password to access Register:'),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: controller.text.trim().isEmpty
                        ? null
                        : IconButton(
                            tooltip: obscure ? 'Show password' : 'Hide password',
                            icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setDialogState(() => obscure = !obscure),
                          ),
                  ),
                  onChanged: (_) => setDialogState(() {
                    error = null;
                  }),
                  onSubmitted: (_) => validateAndSubmit(),
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    error!,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              if (controller.text.trim().isNotEmpty)
                TextButton(
                  onPressed: () async {
                    final typed = controller.text.trim();
                    final currentPassword = await ApiService.getRegisterPassword();
                    if (typed != currentPassword) {
                      setDialogState(() => error = 'Enter correct current password first');
                      return;
                    }

                    final newController = TextEditingController();
                    bool newObscure = true;
                    String? changeError;

                    final changed = await showDialog<bool>(
                      context: ctx,
                      builder: (changeCtx) => StatefulBuilder(
                        builder: (context, setChangeState) {
                          return AlertDialog(
                            title: const Text('Change Password',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text('Enter a new password:'),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: newController,
                                  obscureText: newObscure,
                                  decoration: InputDecoration(
                                    labelText: 'New password',
                                    border: const OutlineInputBorder(),
                                    suffixIcon: newController.text.trim().isEmpty
                                        ? null
                                        : IconButton(
                                            tooltip: newObscure
                                                ? 'Show password'
                                                : 'Hide password',
                                            icon: Icon(newObscure
                                                ? Icons.visibility
                                                : Icons.visibility_off),
                                            onPressed: () => setChangeState(
                                                () => newObscure = !newObscure),
                                          ),
                                  ),
                                  onChanged: (_) => setChangeState(() {
                                    changeError = null;
                                  }),
                                ),
                                if (changeError != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    changeError!,
                                    style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(changeCtx, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final newPassword = newController.text.trim();
                                  if (newPassword.isEmpty) {
                                    setChangeState(() =>
                                        changeError = 'New password can’t be empty');
                                    return;
                                  }
                                  await ApiService.setRegisterPassword(newPassword);
                                  if (changeCtx.mounted) {
                                    Navigator.pop(changeCtx, true);
                                  }
                                },
                                child: const Text('Save',
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          );
                        },
                      ),
                    );

                    if (changed == true && ctx.mounted) {
                      setDialogState(() {
                        controller.clear();
                        obscure = true;
                        error = 'Password changed. Please enter new password.';
                      });
                    }
                  },
                  child: const Text('Change Password',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              TextButton(
                onPressed: () => validateAndSubmit(),
                child: const Text('Submit', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    ).then((result) {
      if (result == true && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const RegisterScreen(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Zwilling Labs logo (place zwilling_logo.png in assets/images/)
                const ZwillingLogo(height: 80),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginWebViewScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('Login'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _onRegisterPressed(context),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Register'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
