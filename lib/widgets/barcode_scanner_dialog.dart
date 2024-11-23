import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/barcode_service.dart';

class BarcodeScannerDialog extends StatefulWidget {
  const BarcodeScannerDialog({super.key});

  @override
  State<BarcodeScannerDialog> createState() => _BarcodeScannerDialogState();
}

class _BarcodeScannerDialogState extends State<BarcodeScannerDialog> {
  final BarcodeService _barcodeService = BarcodeService();
  final TextEditingController _manualController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isProcessing = false;
  bool _isCameraAvailable = true;
  String? _errorMessage;
  MobileScannerController? _controller;
  bool _torchEnabled = false;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  Future<void> _initializeScanner() async {
    try {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: _torchEnabled,
      );
      
      if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
        await _controller?.start();
      } else {
        setState(() {
          _isCameraAvailable = false;
          _errorMessage = 'Camera scanning is not available on desktop. Please use manual entry or a USB barcode scanner.';
        });
      }
    } catch (e) {
      debugPrint('Error initializing scanner: $e');
      setState(() {
        _isCameraAvailable = false;
        _errorMessage = 'Camera not available. Please use manual entry.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Scan Barcode',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isCameraAvailable)
                  IconButton(
                    icon: Icon(_torchEnabled ? Icons.flash_on : Icons.flash_off),
                    onPressed: () {
                      setState(() {
                        _torchEnabled = !_torchEnabled;
                        _controller?.toggleTorch();
                      });
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _controller?.dispose();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isCameraAvailable) ...[
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: MobileScanner(
                        controller: _controller,
                        onDetect: (capture) => _handleBarcode(capture.barcodes),
                        errorBuilder: (context, error, child) {
                          debugPrint('Scanner error: $error');
                          return _buildManualEntry();
                        },
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.green,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      width: 200,
                      height: 200,
                    ),
                  ],
                ),
              ),
              const Text(
                'Position the barcode within the frame or use a USB scanner',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ] else
              _buildManualEntry(),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.orange),
                  textAlign: TextAlign.center,
                ),
              ),
            if (_isProcessing)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualEntry() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _manualController,
            decoration: const InputDecoration(
              labelText: 'Enter Barcode Manually',
              hintText: 'Type or scan barcode using USB scanner',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) => _processBarcode(value),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (_manualController.text.isNotEmpty) {
                _processBarcode(_manualController.text);
              }
            },
            child: const Text('Process Barcode'),
          ),
          const SizedBox(height: 8),
          const Text(
            'You can also use a USB barcode scanner',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBarcode(List<Barcode> barcodes) async {
    if (_isProcessing || barcodes.isEmpty) return;
    
    final String? code = barcodes.first.rawValue;
    if (code != null) {
      debugPrint('Barcode detected: $code');
      try {
        await _audioPlayer.play(AssetSource('sounds/beep.mp3'), volume: 0.5);
      } catch (e) {
        debugPrint('Error playing audio: $e');
      }
      _processBarcode(code);
    }
  }

  Future<void> _processBarcode(String code) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      debugPrint('Processing barcode: $code');
      final cleanedCode = _barcodeService.cleanBarcode(code);
      Navigator.of(context).pop(cleanedCode);
    } catch (e) {
      debugPrint('Error processing barcode: $e');
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Error processing barcode. Please try again.';
      });
    }
  }

  @override
  void dispose() {
    _controller?.stop().then((_) {
      _controller?.dispose();
    });
    _manualController.dispose();
    super.dispose();
  }
}
