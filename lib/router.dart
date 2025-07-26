import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:models/models.dart';
import 'package:trottstr/screens/auth_screen.dart';
import 'package:trottstr/screens/home_screen.dart';
import 'package:trottstr/screens/profile_screen.dart';
import 'package:trottstr/screens/record_stay_screen.dart';
import 'package:trottstr/screens/plan_stay_screen.dart';
import 'package:trottstr/screens/tax_residency_dashboard_screen.dart';
import 'package:trottstr/screens/country_entry_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final pubkey = ref.watch(Signer.activePubkeyProvider);
      final isAuthRoute = state.matchedLocation == '/auth';
      final isRootRoute = state.matchedLocation == '/';

      // If user is signed in
      if (pubkey != null) {
        // Redirect from auth or root to home
        if (isAuthRoute || isRootRoute) {
          return '/home';
        }
      } else {
        // If user is not signed in and not on auth page, redirect to auth
        if (!isAuthRoute) {
          return '/auth';
        }
      }

      return null; // No redirect needed
    },
    routes: [
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/record',
        builder: (context, state) => const RecordStayScreen(),
      ),
      GoRoute(
        path: '/plan',
        builder: (context, state) => const PlanStayScreen(),
      ),
      GoRoute(
        path: '/tax-dashboard',
        builder: (context, state) => const TaxResidencyDashboardScreen(),
      ),
      GoRoute(
        path: '/add-entry',
        builder: (context, state) => const CountryEntryScreen(),
      ),
    ],
  );
});
