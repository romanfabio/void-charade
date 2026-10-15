import 'package:go_router/go_router.dart';

import '../features/categories/categories_screen.dart';
import '../features/game/game_screen.dart';
import '../features/results/results_screen.dart';
import '../features/settings/settings_screen.dart';
import 'route_args.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const settings = '/settings';
  static const game = '/game';
  static const results = '/results';
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
      // The game and results need the objects passed as `extra`; without them
      // (e.g. after the process was restarted) go back to the home screen.
      GoRoute(
        path: AppRoutes.game,
        redirect: (context, state) =>
            state.extra is GameArgs ? null : AppRoutes.home,
        builder: (context, state) =>
            GameScreen(args: state.extra! as GameArgs),
      ),
      GoRoute(
        path: AppRoutes.results,
        redirect: (context, state) =>
            state.extra is ResultsArgs ? null : AppRoutes.home,
        builder: (context, state) =>
            ResultsScreen(args: state.extra! as ResultsArgs),
      ),
    ],
  );
}
