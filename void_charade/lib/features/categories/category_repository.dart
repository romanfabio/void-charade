import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/settings_controller.dart';
import 'category.dart';

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

/// Categories the player can pick, honouring the "Show 18+" setting.
final visibleCategoriesProvider = Provider<AsyncValue<List<Category>>>((ref) {
  final showAdult = ref.watch(settingsProvider.select((s) => s.showAdult));
  return ref.watch(allCategoriesProvider).whenData(
        (all) => [for (final c in all) if (showAdult || !c.adult) c],
      );
});
