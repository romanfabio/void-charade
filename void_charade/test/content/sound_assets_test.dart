import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_charade/services/sound_service.dart';

/// Every sound effect the app references must exist and be a sane short WAV:
/// 16-bit mono PCM, audible but not clipping, and starting/ending at silence
/// (no clicks).
void main() {
  for (final effect in SoundEffect.values) {
    test('${effect.fileName}.wav is a valid short sound', () {
      final file = File('assets/${effect.assetPath}');
      expect(file.existsSync(), isTrue, reason: '${file.path} is missing');

      final bytes = file.readAsBytesSync();
      final data = ByteData.sublistView(bytes);
      String tag(int offset) => String.fromCharCodes(bytes.sublist(offset, offset + 4));

      expect(tag(0), 'RIFF');
      expect(tag(8), 'WAVE');
      expect(tag(12), 'fmt ');
      expect(data.getUint16(20, Endian.little), 1, reason: 'PCM');
      expect(data.getUint16(22, Endian.little), 1, reason: 'mono');
      expect(data.getUint32(24, Endian.little), 44100, reason: 'sample rate');
      expect(data.getUint16(34, Endian.little), 16, reason: 'bit depth');
      expect(tag(36), 'data');

      final sampleCount = data.getUint32(40, Endian.little) ~/ 2;
      expect(bytes.length, 44 + sampleCount * 2);

      final seconds = sampleCount / 44100;
      expect(seconds, inInclusiveRange(0.03, 1.2));

      var peak = 0;
      for (var i = 0; i < sampleCount; i++) {
        peak = peak < data.getInt16(44 + i * 2, Endian.little).abs()
            ? data.getInt16(44 + i * 2, Endian.little).abs()
            : peak;
      }
      expect(peak / 32767, inInclusiveRange(0.4, 0.95), reason: 'loudness');

      expect(data.getInt16(44, Endian.little).abs(), lessThan(1500));
      expect(
        data.getInt16(44 + (sampleCount - 1) * 2, Endian.little).abs(),
        lessThan(1500),
      );
    });
  }
}
