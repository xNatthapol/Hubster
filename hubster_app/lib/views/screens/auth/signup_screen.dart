import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubster_app/viewmodels/auth_state.dart';
import 'package:hubster_app/viewmodels/auth_state_notifier.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submitSignUp() {
    if (_formKey.currentState!.validate()) {
      print(
        "SignUpScreen: Calling authNotifier.signup with email: ${_emailController.text.trim()}",
      );
      // Use ref.read to call methods on the notifier
      ref
          .read(authStateNotifierProvider.notifier)
          .signup(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use ref.watch to listen to state changes for UI rebuilds (e.g., loading, error messages)
    final authState = ref.watch(authStateNotifierProvider);
    print(
      "SignUpScreen BUILD: Status: ${authState.status}, Message: ${authState.operationMessage}",
    );

    // Use ref.listen for side-effects like navigation or showing SnackBars
    // that should not happen during the build method itself.
    ref.listen<AuthState>(authStateNotifierProvider, (
      previousState,
      nextState,
    ) {
      // Check if signup was successful (status unauthenticated with specific message)
      if (nextState.status == AuthStatus.unauthenticated &&
          nextState.operationMessage != null &&
          nextState.operationMessage!.startsWith("Signup successful!")) {
        // Show SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(nextState.operationMessage!),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        // Clear the message from the notifier so it doesn't reappear
        ref.read(authStateNotifierProvider.notifier).clearOperationMessage();

        // Navigate to login screen after showing SnackBar
        // Ensure navigation happens after current build cycle
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // Check if widget is still mounted
            Navigator.pushReplacementNamed(context, '/login');
          }
        });
      }
      // else if (nextState.status == AuthStatus.error && nextState.operationMessage != null) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text(nextState.operationMessage!), backgroundColor: Colors.red)
      //   );
      //  ref.read(authStateNotifierProvider.notifier).clearOperationMessage();
      // }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Hubster Sign Up')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  'Create Account',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        !value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                if (authState.status == AuthStatus.loading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: _submitSignUp,
                    child: const Text('Sign Up'),
                  ),
                const SizedBox(height: 10),
                // Display error messages (excluding the signup success message handled by ref.listen)
                if (authState.status == AuthStatus.error &&
                    authState.operationMessage != null &&
                    !authState.operationMessage!.startsWith(
                      "Signup successful!",
                    ))
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      authState.operationMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    // Clear any lingering error messages before navigating
                    ref
                        .read(authStateNotifierProvider.notifier)
                        .clearOperationMessage();
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: const Text('Already have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
