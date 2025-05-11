import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubster_app/viewmodels/auth_state.dart';
import 'package:hubster_app/viewmodels/auth_state_notifier.dart';
import 'package:hubster_app/views/screens/auth/login_screen.dart';
import 'package:hubster_app/views/screens/auth/signup_screen.dart';
import 'package:hubster_app/views/screens/loading_screen.dart';
import 'package:hubster_app/core/theme/app_theme.dart';
import 'package:hubster_app/views/screens/main_screen.dart';

// Root widget of the application, managed by Riverpod.
class HubsterApp extends ConsumerWidget {
  const HubsterApp({super.key});

  // Global key for accessing the Navigator's state.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to authentication state changes for side-effects like navigation.
    ref.listen<AuthState>(authStateNotifierProvider, (
      previousState,
      nextState,
    ) {
      // Schedule navigation actions after the current frame to ensure navigator is stable.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final currentNavigator = navigatorKey.currentState;
        if (currentNavigator == null || !currentNavigator.mounted) {
          print(
            "App.dart ref.listen (post_frame): Navigator not ready. Skipping navigation.",
          );
          return;
        }

        String? currentRouteName;
        // Safely get current route name by inspecting the top-most route.
        currentNavigator.popUntil((route) {
          currentRouteName = route.settings.name;
          return true; // Stop immediately, just inspecting.
        });

        print(
          "App.dart ref.listen (post_frame): Current Route: $currentRouteName, Prev: ${previousState?.status}, Next: ${nextState.status}",
        );

        // Navigate to MainScreen (which contains BottomNavBar and HomeScreen) if authenticated.
        if (nextState.status == AuthStatus.authenticated) {
          if (currentRouteName != '/main') {
            print(
              "App.dart ref.listen (post_frame): Navigating to MAIN SCREEN from $currentRouteName",
            );
            currentNavigator.pushNamedAndRemoveUntil('/main', (route) => false);
          }
        }
        // Navigate to LoginScreen if unauthenticated or error, under appropriate conditions.
        else if (nextState.status == AuthStatus.unauthenticated ||
            nextState.status == AuthStatus.error) {
          bool cameFromAuthenticatedOrMain =
              previousState?.status == AuthStatus.authenticated ||
              (previousState?.status == AuthStatus.loading &&
                  previousState?.currentUser != null) ||
              currentRouteName == '/main';

          bool isInitialUnauthenticatedLoad =
              (previousState?.status == AuthStatus.loading ||
                  previousState?.status == AuthStatus.unknown) &&
              nextState.currentUser == null &&
              (currentRouteName == '/loading' || currentRouteName == null);

          if (cameFromAuthenticatedOrMain || isInitialUnauthenticatedLoad) {
            if (currentRouteName != '/login' && currentRouteName != '/signup') {
              print(
                "App.dart ref.listen (post_frame): Navigating to LOGIN from $currentRouteName (unauth/error or initial)",
              );
              currentNavigator.pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            } else if (nextState.status == AuthStatus.error) {
              print(
                "App.dart ref.listen (post_frame): Error occurred, but already on login/signup.",
              );
            }
          } else if (nextState.status == AuthStatus.error &&
              (currentRouteName == '/login' || currentRouteName == '/signup')) {
            print(
              "App.dart ref.listen (post_frame): Error on $currentRouteName. Screen handles display.",
            );
          } else if (currentRouteName != '/login' &&
              currentRouteName != '/signup' &&
              currentRouteName != '/loading' &&
              currentRouteName != null) {
            print(
              "App.dart ref.listen (post_frame): Fallback Navigating to LOGIN from unexpected $currentRouteName",
            );
            currentNavigator.pushNamedAndRemoveUntil(
              '/login',
              (route) => false,
            );
          }
        }
      });
    });

    // Initial build information.
    print(
      "App.dart BUILD: Setting initialRoute to /loading. AuthStateNotifier will trigger navigation.",
    );

    // Main application widget.
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Hubster',
      theme: AppTheme.lightTheme,
      // darkTheme: AppTheme.darkTheme,
      // themeMode: ThemeMode.system,
      initialRoute: '/loading',
      routes: {
        '/loading': (context) => const LoadingScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/main': (context) => const MainScreen(),
      },
    );
  }
}
