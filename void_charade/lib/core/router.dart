import 'package:go_router/go_router.dart';

import '../features/categories/categories_screen.dart';
import '../features/settings/settings_screen.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const settings = '/settings';
}

GoRouter buildRouter() {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const CategoriesScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
