import 'dart:io';

import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:void_charade/features/categories/category_repository.dart';
import 'package:void_charade/features/categories/word_repository.dart';

/// Reads the project's real `assets/` straight from disk (tests run from the
/// project root). Unlike `rootBundle`, nothing is cached across tests, so each
/// widget test's fake-time zone gets its own fresh, immediately-ready futures.
class FileAssetBundle extends AssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final file = File(key);
    if (!file.existsSync()) {
      throw FlutterError('Unable to load asset: "$key"');
    }
    return ByteData.sublistView(Uint8List.fromList(file.readAsBytesSync()));
  }
}

/// Provider overrides that make the app load its real categories and word
/// files from disk.
List<Override> realAssetOverrides() => [
      categoryRepositoryProvider.overrideWithValue(
        CategoryRepository(bundle: FileAssetBundle()),
      ),
      wordRepositoryProvider.overrideWithValue(
        WordRepository(bundle: FileAssetBundle()),
      ),
      wordAssetsProvider.overrideWith(
        (ref) async => {
          for (final entity in Directory('assets/words').listSync(recursive: true))
            if (entity is File && entity.path.endsWith('.txt'))
              entity.path.replaceAll(r'\', '/'),
        },
      ),
    ];
