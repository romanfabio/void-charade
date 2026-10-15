import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/settings_controller.dart';
import 'category.dart';
import 'round_setup.dart';
import 'word_repository.dart';

class CategoryRepository {
  CategoryRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  Future<List<Category>> loadAll() async {
    final raw = await _bundle.loadString('assets/categories.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return [
      for (final c in json['categories'] as List<dynamic>)
        Category.fromJson(c as Map<String, dynamic>),
    ];
  }
}

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepository(),
);

final allCategoriesProvider = FutureProvider<List<Category>>(
  (ref) => ref.watch(categoryRepositoryProvider).loadAll(),
);

/// Paths of every word file bundled in the app.
final wordAssetsProvider = FutureProvider<Set<String>>((ref) async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  return {
    for (final path in manifest.listAssets())
      if (path.startsWith('assets/words/')) path,
  };
});

/// Categories the player can pick for the current word language, honouring the
/// "Show 18+" setting. A category only appears once its word file exists.
final playableCategoriesProvider = Provider<AsyncValue<List<Category>>>((ref) {
  final showAdult = ref.watch(settingsProvider.select((s) => s.showAdult));
  final languageCode = ref.watch(wordLanguageProvider);
  final all = ref.watch(allCategoriesProvider);
  final assets = ref.watch(wordAssetsProvider);

  if (all.hasError) return AsyncValue.error(all.error!, all.stackTrace!);
  if (assets.hasError) {
    return AsyncValue.error(assets.error!, assets.stackTrace!);
  }
  if (!all.hasValue || !assets.hasValue) return const AsyncValue.loading();

  return AsyncValue.data(
    playableCategories(
      all: all.requireValue,
      assetPaths: assets.requireValue,
      languageCode: languageCode,
      showAdult: showAdult,
    ),
  );
});

final roundSetupServiceProvider = Provider<RoundSetupService>(
  (ref) => RoundSetupService(ref.watch(wordRepositoryProvider)),
);
