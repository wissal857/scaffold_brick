import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';

final appRouterProvider = Provider<GoRouter>(
  (ref) => GoRouter(
    initialLocation: AppRoutes.splashRoute,
    routes: <RouteBase>[
      // GoRoute(
      //   path: AppRoutes.splashRoute,
      //   builder: (BuildContext context, GoRouterState state) =>
      //       const SplashView(),
      // ),
      // GoRoute(
      //   path: AppRoutes.onboardingWelcomeRoute,
      //   builder: (BuildContext context, GoRouterState state) =>
      //       const OnboardingWelcomeScreen(),
      // ),
      // GoRoute(
      //   path: AppRoutes.onboardingPermissionsRoute,
      //   builder: (BuildContext context, GoRouterState state) =>
      //       const OnboardingPermissionsScreen(),
      // ),
      // GoRoute(
      //   path: AppRoutes.onboardingCompletionRoute,
      //   builder: (BuildContext context, GoRouterState state) =>
      //       const OnboardingCompletionScreen(),
      // ),
      // GoRoute(
      //   path: AppRoutes.signInRoute,
      //   builder: (BuildContext context, GoRouterState state) =>
      //       const SignInView(),
      // ),
      // GoRoute(
      //   path: AppRoutes.settingsRoute,
      //   builder: (BuildContext context, GoRouterState state) =>
      //       const SettingsView(),
      // ),
    ],
  ),
);
