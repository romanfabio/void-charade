import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF14101F);
  static const surface = Color(0xFF211A33);
  static const surfaceHigh = Color(0xFF2D2445);
  static const onSurface = Color(0xFFF5F0FF);
  static const onSurfaceMuted = Color(0xFFB9AED6);

  static const magenta = Color(0xFFFF3D9A);
  static const orange = Color(0xFFFF8A3D);
  static const cyan = Color(0xFF22D3EE);
  static const violet = Color(0xFF7C4DFF);
  static const success = Color(0xFF2ECC71);
  static const skip = Color(0xFFFF9F1C);
  static const danger = Color(0xFFFF4D4D);

  static const partyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [magenta, orange],
  );

  static const coolGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cyan, violet],
  );
}
