import 'dart:ui';

import 'package:flutter/foundation.dart';

@immutable
class Category {
  const Category({
    required this.id,
    required this.emoji,
    required this.color,
    required this.adult,
    required this.names,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    final hex = (json['color'] as String).replaceFirst('#', '');
    return Category(
      id: json['id'] as String,
      emoji: json['emoji'] as String,
      color: Color(int.parse('FF$hex', radix: 16)),
      adult: json['adult'] as bool? ?? false,
      names: Map<String, String>.from(json['name'] as Map),
    );
  }

  final String id;
  final String emoji;
  final Color color;
  final bool adult;
  final Map<String, String> names;

  /// Name in [languageCode], falling back to English, then to the id.
  String nameFor(String languageCode) => names[languageCode] ?? names['en'] ?? id;
}
