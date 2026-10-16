// Synthesises the game's sound effects into assets/sounds/*.wav
// (16-bit mono PCM, 44.1 kHz). The sounds are original, generated here, so
// there is nothing to license. Run:
//
//   dart run tool/generate_sounds.dart
//
// To use other sounds instead, drop WAV files with the same names into
// assets/sounds/ (keep them short: under ~1 s).
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const sampleRate = 44100;

/// A single decaying note. [harmonics] are the relative levels of the
/// fundamental and its overtones (more overtones = brighter / buzzier).
List<double> note(
  double frequency,
  double duration, {
  double decay = 5,
  double attack = 0.004,
  List<double> harmonics = const [1, 0.25, 0.08],
  double? slideTo,
}) {
  final n = (duration * sampleRate).round();
  final out = List<double>.filled(n, 0);
  var phase = 0.0;
  for (var i = 0; i < n; i++) {
    final t = i / sampleRate;
    final progress = i / n;
    final f = slideTo == null ? frequency : frequency + (slideTo - frequency) * progress;
    phase += 2 * math.pi * f / sampleRate;

    var sample = 0.0;
    for (var h = 0; h < harmonics.length; h++) {
      sample += harmonics[h] * math.sin(phase * (h + 1));
    }

    final env = (t < attack ? t / attack : 1.0) * math.exp(-decay * progress);
    // Short fade-out so the file never ends on a click.
    final fadeOut = math.min(1.0, (n - i) / (sampleRate * 0.004));
    out[i] = sample * env * fadeOut;
  }
  return out;
}

/// Mixes [parts], each starting at its offset in seconds.
List<double> mix(List<(double, List<double>)> parts) {
  var length = 0;
  for (final (offset, samples) in parts) {
    length = math.max(length, (offset * sampleRate).round() + samples.length);
  }
  final out = List<double>.filled(length, 0);
  for (final (offset, samples) in parts) {
    final start = (offset * sampleRate).round();
    for (var i = 0; i < samples.length; i++) {
      out[start + i] += samples[i];
    }
  }
  return out;
}

/// Scales so the loudest sample is [peak] (0..1).
List<double> normalise(List<double> samples, {double peak = 0.8}) {
  final max = samples.fold<double>(0, (m, s) => math.max(m, s.abs()));
  if (max == 0) return samples;
  return [for (final s in samples) s / max * peak];
}

Uint8List wav(List<double> samples) {
  final data = ByteData(44 + samples.length * 2);
  void ascii(int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      data.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  data.setUint32(4, 36 + samples.length * 2, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  data.setUint32(16, 16, Endian.little); // PCM header size
  data.setUint16(20, 1, Endian.little); // PCM
  data.setUint16(22, 1, Endian.little); // mono
  data.setUint32(24, sampleRate, Endian.little);
  data.setUint32(28, sampleRate * 2, Endian.little); // byte rate
  data.setUint16(32, 2, Endian.little); // block align
  data.setUint16(34, 16, Endian.little); // bits per sample
  ascii(36, 'data');
  data.setUint32(40, samples.length * 2, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    data.setInt16(44 + i * 2, (samples[i].clamp(-1.0, 1.0) * 32767).round(), Endian.little);
  }
  return data.buffer.asUint8List();
}

void main() {
  const buzz = [1.0, 0.55, 0.35, 0.2];

  final sounds = <String, List<double>>{
    // Happy rising arpeggio: G5 - C6 - E6.
    'correct': mix([
      (0.00, note(783.99, 0.30, decay: 4)),
      (0.08, note(1046.50, 0.32, decay: 4)),
      (0.16, note(1318.51, 0.40, decay: 5)),
    ]),
    // Sad falling "bwomp".
    'skip': note(330, 0.34, decay: 3, harmonics: buzz, slideTo: 150),
    // Dry little click for the last seconds.
    'tick': mix([
      (0.0, note(1800, 0.04, decay: 9, harmonics: const [1, 0.3])),
      (0.0, note(900, 0.04, decay: 9, harmonics: const [1])),
    ]),
    'countdown_beep': note(660, 0.14, decay: 2.5, harmonics: const [1, 0.15]),
    // Higher double beep: start!
    'go': mix([
      (0.00, note(880, 0.10, decay: 2, harmonics: const [1, 0.2])),
      (0.12, note(1320, 0.32, decay: 4, harmonics: const [1, 0.2])),
    ]),
    // Three falling tones, then a low buzz: time is up.
    'time_up': mix([
      (0.00, note(880, 0.16, decay: 2, harmonics: buzz)),
      (0.18, note(660, 0.16, decay: 2, harmonics: buzz)),
      (0.36, note(440, 0.50, decay: 4, harmonics: buzz)),
    ]),
  };

  final dir = Directory('assets/sounds')..createSync(recursive: true);
  sounds.forEach((name, samples) {
    final bytes = wav(normalise(samples));
    File('${dir.path}/$name.wav').writeAsBytesSync(bytes);
    final seconds = (samples.length / sampleRate).toStringAsFixed(2);
    stdout.writeln('$name.wav  ${seconds}s  ${bytes.length} bytes');
  });
}
