import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const AudioEqualizerApp());
}

class AudioEqualizerApp extends StatelessWidget {
  const AudioEqualizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Audio Equalizer Studio',
      theme: ThemeData.dark(useMaterial3: true),
      home: const EqualizerScreen(),
    );
  }
}

class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  double _phase = 0.0;
  bool _isPlaying = true;
  String _activePreset = 'Bass Boost';

  final List<String> _bandLabels = const [
    '60Hz',
    '230Hz',
    '910Hz',
    '3.6kHz',
    '14kHz',
  ];
  List<double> _bandGains = [0.85, 0.70, 0.45, 0.60, 0.75]; // 0.0 - 1.0

  final Map<String, List<double>> _presets = const {
    'Flat': [0.50, 0.50, 0.50, 0.50, 0.50],
    'Bass Boost': [0.90, 0.75, 0.40, 0.55, 0.65],
    'Vocal': [0.35, 0.55, 0.85, 0.80, 0.45],
    'Electronic': [0.85, 0.65, 0.35, 0.75, 0.90],
  };

  @override
  void initState() {
    super.initState();
    _animController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..addListener(() {
            if (_isPlaying) {
              setState(() {
                _phase += 0.14;
              });
            }
          });
    _animController.repeat();
  }

  void _applyPreset(String name) {
    setState(() {
      _activePreset = name;
      _bandGains = List<double>.from(_presets[name]!);
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0D15),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Audio Equalizer Studio',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => setState(() => _isPlaying = !_isPlaying),
            icon: Icon(
              _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
            ),
            tooltip: _isPlaying ? 'Pause Wave' : 'Play Wave',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 190,
              decoration: BoxDecoration(
                color: const Color(0xFF121725),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.cyanAccent.withValues(alpha: 0.3),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: CustomPaint(
                  painter: _SoundwavePainter(
                    gains: _bandGains,
                    phase: _phase,
                    isPlaying: _isPlaying,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
            const SizedBox(height: 18),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _presets.keys.map((preset) {
                  final selected = _activePreset == preset;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(preset),
                      selected: selected,
                      onSelected: (_) => _applyPreset(preset),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF121725),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(_bandLabels.length, (i) {
                    final db = ((_bandGains[i] - 0.5) * 24).round();
                    final dbText = db >= 0 ? '+${db}dB' : '${db}dB';

                    return Column(
                      children: [
                        Text(
                          dbText,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Colors.cyanAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: RotatedBox(
                            quarterTurns: -1,
                            child: Slider(
                              value: _bandGains[i],
                              min: 0.0,
                              max: 1.0,
                              activeColor: Colors.cyanAccent,
                              onChanged: (val) {
                                setState(() {
                                  _activePreset = 'Custom';
                                  _bandGains[i] = val;
                                });
                              },
                            ),
                          ),
                        ),
                        Text(
                          _bandLabels[i],
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoundwavePainter extends CustomPainter {
  final List<double> gains;
  final double phase;
  final bool isPlaying;

  _SoundwavePainter({
    required this.gains,
    required this.phase,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;

    // Фондағы спектр бағандары
    const barCount = 28;
    final barWidth = size.width / barCount;
    for (int i = 0; i < barCount; i++) {
      final bandIdx = (i * gains.length / barCount).floor().clamp(
        0,
        gains.length - 1,
      );
      final gain = gains[bandIdx];
      final pulse = isPlaying
          ? (0.65 + 0.35 * sin(phase * 1.4 + i * 0.5))
          : 0.4;
      final barHeight = (size.height * 0.65) * gain * pulse;

      final barPaint = Paint()
        ..color = Colors.purpleAccent.withValues(alpha: 0.22);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(i * barWidth + barWidth / 2, midY),
            width: barWidth * 0.6,
            height: barHeight,
          ),
          const Radius.circular(4),
        ),
        barPaint,
      );
    }

    // Негізгі синусоидалы неон толқын
    final wavePath = Path();
    for (double x = 0; x <= size.width; x += 3) {
      final normX = x / size.width;
      final bandIdx = (normX * (gains.length - 1)).round().clamp(
        0,
        gains.length - 1,
      );
      final amp = gains[bandIdx] * (size.height * 0.36);
      final y =
          midY +
          sin(normX * 4 * pi + phase) * amp * 0.7 +
          cos(normX * 9 * pi - phase * 1.3) * amp * 0.3;

      if (x == 0) {
        wavePath.moveTo(x, y);
      } else {
        wavePath.lineTo(x, y);
      }
    }

    final glowPaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final linePaint = Paint()
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6;

    canvas.drawPath(wavePath, glowPaint);
    canvas.drawPath(wavePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SoundwavePainter oldDelegate) => true;
}
