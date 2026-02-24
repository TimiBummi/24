import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../recognition/card_recognizer.dart';
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
  bool _isProcessing = false;
  String? _error;
  bool _cameraReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
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
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }

      _controller = controller;
      setState(() => _cameraReady = true);

      controller.startImageStream(_onFrame);
    } catch (e) {
      setState(() => _error = 'Camera error: $e');
    }
  }

  void _onFrame(CameraImage image) async {
    if (_isProcessing || _controller == null) return;
    _isProcessing = true;
    try {
      final detected = await _recognizer.processFrame(image, _controller!);
      if (mounted && detected.isNotEmpty) {
        setState(() {
          // Fill empty slots with newly detected values
          for (int i = 0; i < detected.length && i < 4; i++) {
            if (_cards[i] == null) {
              _cards[i] = detected[i];
            }
          }
        });
      }
    } finally {
      _isProcessing = false;
    }
  }

  void _onSlotTapped(int index) {
    showCardPicker(context, (value) {
      setState(() => _cards[index] = value);
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
    setState(() => _cards = [null, null, null, null]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: _buildPreview()),
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
      return const Center(child: CircularProgressIndicator());
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
}
