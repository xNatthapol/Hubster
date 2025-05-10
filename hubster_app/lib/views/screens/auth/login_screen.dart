import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubster_app/viewmodels/auth_state.dart';
import 'package:hubster_app/viewmodels/auth_state_notifier.dart';

// Change to ConsumerStatefulWidget if you need local state like controllers
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitLogin() {
    if (_formKey.currentState!.validate()) {
      print(
        "LoginScreen: Calling authNotifier.login with email: ${_emailController.text.trim()}",
      );
      // Use ref.read to call methods on the notifier (doesn't listen for rebuilds)
      ref
          .read(authStateNotifierProvider.notifier)
          .login(_emailController.text.trim(), _passwordController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use ref.watch to listen to state changes for UI rebuilds
    final authState = ref.watch(authStateNotifierProvider);
    print(
      "LoginScreen BUILD: Status: ${authState.status}, Message: ${authState.operationMessage}",
    );

    // Listen for specific state changes for side-effects like SnackBars or navigation
    // ref.listen<AuthState>(authStateNotifierProvider, (previous, next) {
    //   if (next.status == AuthStatus.error && next.operationMessage != null) {
    //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.operationMessage!)));
    //     ref.read(authStateNotifierProvider.notifier).clearOperationMessage();
    //   }
    // });

    return Scaffold(
      appBar: AppBar(title: const Text('Hubster Login')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  'HUBSTER',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
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
                const SizedBox(height: 30),
                if (authState.status == AuthStatus.loading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: _submitLogin,
                    child: const Text('Login'),
                  ),
                const SizedBox(height: 10),
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
                    ref
                        .read(authStateNotifierProvider.notifier)
                        .clearOperationMessage();
                    Navigator.pushReplacementNamed(context, '/signup');
                  },
                  child: const Text("Don't have an account? Sign Up"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
