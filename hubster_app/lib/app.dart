import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubster_app/viewmodels/auth_state.dart';
import 'package:hubster_app/viewmodels/auth_state_notifier.dart';
import 'package:hubster_app/views/screens/auth/login_screen.dart';
import 'package:hubster_app/views/screens/auth/signup_screen.dart';
import 'package:hubster_app/views/screens/home_screen.dart';
import 'package:hubster_app/views/screens/loading_screen.dart';

class HubsterApp extends ConsumerWidget {
  const HubsterApp({super.key});
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listener for performing navigations based on auth state changes.
    ref.listen<AuthState>(authStateNotifierProvider, (
      previousState,
      nextState,
    ) {
      final currentNavigator = navigatorKey.currentState;
      if (currentNavigator == null) {
        print("App.dart ref.listen: Navigator is null, cannot navigate.");
        return;
      }

      String? currentRouteName;
      if (navigatorKey.currentContext != null &&
          navigatorKey.currentContext!.mounted) {
        Navigator.popUntil(navigatorKey.currentContext!, (route) {
          currentRouteName = route.settings.name;
          return true; // Stop popping immediately
        });
      }

      print(
        "App.dart ref.listen: Current Route: $currentRouteName, Prev Status: ${previousState?.status}, Next Auth Status: ${nextState.status}",
      );

      if (nextState.status == AuthStatus.authenticated) {
        // Navigate to home only if not already there and previous state wasn't already authenticated (to avoid loops on other state changes)
        if (currentRouteName != '/home') {
          print(
            "App.dart ref.listen: Navigating to HOME from $currentRouteName",
          );
          currentNavigator.pushNamedAndRemoveUntil('/home', (route) => false);
        }
      } else if (nextState.status == AuthStatus.unauthenticated ||
          nextState.status == AuthStatus.error) {
        bool cameFromAuthenticated =
            previousState?.status == AuthStatus.authenticated ||
            (previousState?.status == AuthStatus.loading &&
                previousState?.currentUser != null);
        bool isInitialUnauthenticatedLoad =
            (previousState?.status == AuthStatus.loading ||
                previousState?.status == AuthStatus.unknown) &&
            nextState.currentUser == null &&
            currentRouteName == '/loading';

        if (cameFromAuthenticated || isInitialUnauthenticatedLoad) {
          if (currentRouteName != '/login' && currentRouteName != '/signup') {
            print(
              "App.dart ref.listen: Navigating to LOGIN from $currentRouteName (due to unauth/error from auth state or initial load)",
            );
            currentNavigator.pushNamedAndRemoveUntil(
              '/login',
              (route) => false,
            );
          } else if (nextState.status == AuthStatus.error) {
            print(
              "App.dart ref.listen: Error occurred, but already on login/signup. Letting screen handle error display.",
            );
          }
        } else if (nextState.status == AuthStatus.error &&
            (currentRouteName == '/login' || currentRouteName == '/signup')) {
          print(
            "App.dart ref.listen: Error occurred while on $currentRouteName. Screen will display error.",
          );
        } else if (currentRouteName != '/login' &&
            currentRouteName != '/signup' &&
            currentRouteName != '/loading' &&
            currentRouteName != null) {
          // Fallback: if unauthenticated from an unexpected screen, go to login
          print(
            "App.dart ref.listen: Fallback Navigating to LOGIN from unexpected $currentRouteName",
          );
          currentNavigator.pushNamedAndRemoveUntil('/login', (route) => false);
        }
      }
    });

    print(
      "App.dart BUILD: Setting initialRoute to /loading. AuthStateNotifier will trigger navigation.",
    );

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Hubster',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/loading',
      routes: {
        '/loading': (context) => const LoadingScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
