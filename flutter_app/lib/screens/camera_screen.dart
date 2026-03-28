import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../recognition/card_parser.dart';
import '../recognition/card_recognizer.dart';
import '../recognition/ml_pipeline.dart';
import '../widgets/card_slots.dart';
import 'results_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  final CardRecognizer _recognizer = CardRecognizer();
  List<int?> _cards = [null, null, null, null];
  List<double> _confidences = [0, 0, 0, 0];
  bool _isCapturing = false;
  String? _error;
  bool _cameraReady = false;
  bool _modelsLoaded = false;

  /// Last pipeline result for debug overlay.
  PipelineResult? _lastResult;
  bool _showDebug = false;
  String _pipelineStatus = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    _loadModels();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _recognizer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _loadModels() async {
    try {
      await _recognizer.load();
      if (mounted) setState(() => _modelsLoaded = true);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Failed to load ML models: $e');
      }
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = 'No camera available on this device.');
        return;
      }

      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }

      _controller = controller;
      setState(() => _cameraReady = true);
    } catch (e) {
      setState(() => _error = 'Camera error: $e');
    }
  }

  // ── Capture ──────────────────────────────────────────────────────────

  Future<void> _onCapture() async {
    if (_controller == null || _isCapturing || !_modelsLoaded) return;

    setState(() {
      _isCapturing = true;
      _pipelineStatus = 'Detecting cards...';
    });

    try {
      final file = await _controller!.takePicture();

      if (mounted) setState(() => _pipelineStatus = 'Classifying...');
      final result = await _recognizer.processCapture(file.path);

      if (!mounted) return;

      setState(() {
        _lastResult = result;
        _pipelineStatus = result.hasCards
            ? 'Found ${result.cards.length} card(s) (${result.detectionsFound} detected)'
            : 'No cards found (${result.detectionsFound} detected)';

        for (int i = 0; i < result.cards.length && i < 4; i++) {
          _cards[i] = result.cards[i].value;
          _confidences[i] = result.cards[i].confidence;
        }
      });

      // Clean up temp file.
      try {
        File(file.path).deleteSync();
      } catch (_) {}
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Capture failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  // ── Slot actions ──────────────────────────────────────────────────

  void _onSlotTapped(int index) {
    showCardPicker(context, (value) {
      setState(() {
        _cards[index] = value;
        _confidences[index] = 1.0;
      });
    });
  }

  void _onSolve() {
    final filled = _cards.whereType<int>().toList();
    if (filled.length != 4) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ResultsScreen(cards: filled)),
    );
  }

  void _onClear() {
    setState(() {
      _cards = [null, null, null, null];
      _confidences = [0, 0, 0, 0];
      _lastResult = null;
      _pipelineStatus = '';
    });
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildPreview(),
                _buildGuideOverlay(),
                _buildDetectionOverlay(),
                _buildStatusBanner(),
                _buildDebugToggle(),
                _buildCaptureButton(),
              ],
            ),
          ),
          CardSlots(
            cards: _cards,
            onSlotTapped: _onSlotTapped,
            onSolve: _onSolve,
            onClear: _onClear,
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              const Text(
                'You can still enter cards manually by tapping the slots below.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (!_cameraReady || _controller == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (!_modelsLoaded) ...[
              const SizedBox(height: 16),
              const Text('Loading ML models...', style: TextStyle(color: Colors.grey)),
            ],
          ],
        ),
      );
    }

    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller!.value.previewSize!.height,
            height: _controller!.value.previewSize!.width,
            child: CameraPreview(_controller!),
          ),
        ),
      ),
    );
  }

  Widget _buildGuideOverlay() {
    if (!_cameraReady) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        const cardCount = 4;
        final totalPadding = w * 0.1;
        final spacing = w * 0.03;
        final cardWidth =
            (w - totalPadding - spacing * (cardCount - 1)) / cardCount;
        final cardHeight = cardWidth / 0.714;
        final startX = totalPadding / 2;
        final startY = (h - cardHeight) / 2;

        return CustomPaint(
          size: Size(w, h),
          painter: _GuideOverlayPainter(
            cardWidth: cardWidth,
            cardHeight: cardHeight,
            startX: startX,
            startY: startY,
            spacing: spacing,
            cardCount: cardCount,
            filledSlots: _cards,
          ),
        );
      },
    );
  }

  Widget _buildDetectionOverlay() {
    final result = _lastResult;
    if (result == null ||
        result.cards.isEmpty ||
        !_cameraReady ||
        _controller == null) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _DetectionOverlayPainter(
            result: result,
            widgetSize: Size(constraints.maxWidth, constraints.maxHeight),
            cards: _cards,
            confidences: _confidences,
            showDebug: _showDebug,
          ),
        );
      },
    );
  }

  Widget _buildStatusBanner() {
    if (_pipelineStatus.isEmpty) return const SizedBox.shrink();

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        color: Colors.black.withValues(alpha: 0.6),
        child: SafeArea(
          bottom: false,
          child: Text(
            _pipelineStatus,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
      ),
    );
  }

  Widget _buildDebugToggle() {
    if (!_cameraReady) return const SizedBox.shrink();

    return Positioned(
      top: 8,
      right: 8,
      child: SafeArea(
        child: GestureDetector(
          onTap: () => setState(() => _showDebug = !_showDebug),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _showDebug
                  ? Colors.deepPurple.withValues(alpha: 0.8)
                  : Colors.black.withValues(alpha: 0.4),
            ),
            child: Icon(
              Icons.bug_report,
              size: 20,
              color: _showDebug ? Colors.white : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCaptureButton() {
    if (!_cameraReady) return const SizedBox.shrink();

    final canCapture = _modelsLoaded && !_isCapturing;

    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: canCapture ? _onCapture : null,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: canCapture
                  ? Colors.white.withValues(alpha: 0.9)
                  : Colors.grey,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _isCapturing
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : Icon(
                    _modelsLoaded ? Icons.camera_alt : Icons.hourglass_empty,
                    size: 32,
                    color: canCapture ? Colors.deepPurple : Colors.white54,
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Guide Overlay ────────────────────────────────────────────────

class _GuideOverlayPainter extends CustomPainter {
  final double cardWidth, cardHeight, startX, startY, spacing;
  final int cardCount;
  final List<int?> filledSlots;

  _GuideOverlayPainter({
    required this.cardWidth,
    required this.cardHeight,
    required this.startX,
    required this.startY,
    required this.spacing,
    required this.cardCount,
    required this.filledSlots,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final guidePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final filledPaint = Paint()
      ..color = Colors.green.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final cornerLength = cardWidth * 0.2;

    for (int i = 0; i < cardCount; i++) {
      final x = startX + i * (cardWidth + spacing);
      final y = startY;
      final rect = Rect.fromLTWH(x, y, cardWidth, cardHeight);
      final paint = filledSlots[i] != null ? filledPaint : guidePaint;
      _drawCornerBrackets(canvas, rect, paint, cornerLength);
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Place 4 cards in view, then tap capture',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.8),
          fontSize: 14,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.7),
              blurRadius: 4,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size.width - textPainter.width) / 2, startY - 30),
    );
  }

  void _drawCornerBrackets(Canvas canvas, Rect rect, Paint paint, double len) {
    final path = Path()
      ..moveTo(rect.left, rect.top + len)
      ..lineTo(rect.left, rect.top)
      ..lineTo(rect.left + len, rect.top)
      ..moveTo(rect.right - len, rect.top)
      ..lineTo(rect.right, rect.top)
      ..lineTo(rect.right, rect.top + len)
      ..moveTo(rect.right, rect.bottom - len)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.right - len, rect.bottom)
      ..moveTo(rect.left + len, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.bottom - len);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_GuideOverlayPainter old) =>
      old.filledSlots != filledSlots;
}

// ── Detection Overlay ────────────────────────────────────────────

class _DetectionOverlayPainter extends CustomPainter {
  final PipelineResult result;
  final Size widgetSize;
  final List<int?> cards;
  final List<double> confidences;
  final bool showDebug;

  _DetectionOverlayPainter({
    required this.result,
    required this.widgetSize,
    required this.cards,
    required this.confidences,
    required this.showDebug,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final imgW = result.imageWidth.toDouble();
    final imgH = result.imageHeight.toDouble();
    if (imgW == 0 || imgH == 0) return;

    final imageAspect = imgW / imgH;
    final widgetAspect = widgetSize.width / widgetSize.height;

    double scale, offsetX, offsetY;
    if (imageAspect > widgetAspect) {
      scale = widgetSize.height / imgH;
      offsetX = (widgetSize.width - imgW * scale) / 2;
      offsetY = 0;
    } else {
      scale = widgetSize.width / imgW;
      offsetX = 0;
      offsetY = (widgetSize.height - imgH * scale) / 2;
    }

    Rect mapNormalized(double nx, double ny, double nw, double nh) {
      return Rect.fromLTWH(
        nx * imgW * scale + offsetX,
        ny * imgH * scale + offsetY,
        nw * imgW * scale,
        nh * imgH * scale,
      );
    }

    final bboxPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    for (int i = 0; i < result.cards.length && i < 4; i++) {
      final card = result.cards[i];
      final recognized = i < cards.length && cards[i] != null;

      bboxPaint.color = recognized
          ? Colors.green.withValues(alpha: 0.8)
          : Colors.orange.withValues(alpha: 0.8);

      final rect = mapNormalized(card.x, card.y, card.width, card.height);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        bboxPaint,
      );

      // Label
      if (recognized && i < confidences.length) {
        final conf = (confidences[i] * 100).round();
        final label = CardParser.valueToLabel[cards[i]] ?? '?';
        final textPainter = TextPainter(
          text: TextSpan(
            text: '$label ($conf%)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              backgroundColor: bboxPaint.color,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(rect.left, rect.top - 16));
      }

      // Debug info
      if (showDebug) {
        final debugText = 'YOLO conf: ${(card.confidence * 100).round()}%\n'
            'Rank conf: ${(confidences[i] * 100).round()}%';
        final tp = TextPainter(
          text: TextSpan(
            text: debugText,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              backgroundColor: Colors.black.withValues(alpha: 0.6),
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        tp.layout(maxWidth: rect.width + 40);
        tp.paint(canvas, Offset(rect.left, rect.bottom + 4));
      }
    }
  }

  @override
  bool shouldRepaint(_DetectionOverlayPainter old) => true;
}
