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
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submitSignUp() {
    if (_formKey.currentState!.validate()) {
      print(
        "SignUpScreen: Calling authNotifier.signup with email: ${_emailController.text.trim()}, fullName: ${_fullNameController.text.trim()}",
      );
      ref
          .read(authStateNotifierProvider.notifier)
          .signup(
            _emailController.text.trim(),
            _passwordController.text.trim(),
            _fullNameController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateNotifierProvider);
    print(
      "SignUpScreen BUILD: Status: ${authState.status}, Message: ${authState.operationMessage}",
    );

    ref.listen<AuthState>(authStateNotifierProvider, (
      previousState,
      nextState,
    ) {
      if (nextState.status == AuthStatus.unauthenticated &&
          nextState.operationMessage != null &&
          nextState.operationMessage!.startsWith("Signup successful!")) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(nextState.operationMessage!),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        ref.read(authStateNotifierProvider.notifier).clearOperationMessage();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        });
      }
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

                // Full Name TextFormField
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your full name';
                    }
                    if (value.trim().length < 2) {
                      return 'Full name is too short';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Email TextFormField
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
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

                // Password TextFormField
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
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

                // Confirm Password TextFormField
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
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

                // Signup Button
                if (authState.status == AuthStatus.loading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: _submitSignUp,
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                const SizedBox(height: 10),

                // Error Message Display
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

                // Link to Login Screen
                TextButton(
                  onPressed: () {
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
