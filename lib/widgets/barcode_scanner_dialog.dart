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
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      setState(() {
        _isCameraAvailable = false;
        _errorMessage = 'Camera scanning is not available on desktop. Please use manual entry or a USB barcode scanner.';
      });
      return;
    }

    try {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: _torchEnabled,
      );
      await _controller?.start();
    } catch (e) {
      debugPrint('Error initializing scanner: $e');
      setState(() {
        _isCameraAvailable = false;
        _errorMessage = 'Camera not available. Please use manual entry.';
      });
    }
  }

  Widget _buildDesktopBarcodeInput() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.barcode_reader,
          size: 48,
          color: Colors.grey,
        ),
        const SizedBox(height: 16),
        const Text(
          'Use a USB Barcode Scanner or Enter Code Manually',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _manualController,
          autofocus: true,  // Auto-focus for barcode scanner
          decoration: const InputDecoration(
            labelText: 'Barcode',
            hintText: 'Scan or type barcode',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.qr_code),
          ),
          onSubmitted: (value) async {
            if (value.isNotEmpty) {
              await _processBarcode(value);
            }
          },
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () async {
            if (_manualController.text.isNotEmpty) {
              await _processBarcode(_manualController.text);
            }
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }

  Future<void> _processBarcode(String barcode) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      // Play a success sound
      await _audioPlayer.play(AssetSource('sounds/beep.mp3'));
      
      // Process the barcode
      final result = await _barcodeService.processBarcode(barcode);
      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing barcode: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
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
                if (_isCameraAvailable && _controller != null)
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
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Platform.isWindows || Platform.isLinux || Platform.isMacOS
                  ? _buildDesktopBarcodeInput()
                  : _buildMobileScanner(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileScanner() {
    if (!_isCameraAvailable) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Camera not available',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: MobileScanner(
            controller: _controller,
            onDetect: (capture) async {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? code = barcodes.first.rawValue;
                if (code != null) {
                  await _processBarcode(code);
                }
              }
            },
          ),
        ),
        // Scanning overlay
        CustomPaint(
          painter: ScannerOverlayPainter(),
          child: const SizedBox(
            width: 200,
            height: 200,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    if (_controller != null && !Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      _controller?.stop();
      _controller?.dispose();
    }
    _manualController.dispose();
    super.dispose();
  }
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double borderWidth = 3.0;
    const double cornerLength = 20.0;
    final Paint borderPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    // Draw corners
    // Top left
    canvas.drawLine(
      const Offset(0, cornerLength),
      const Offset(0, 0),
      borderPaint,
    );
    canvas.drawLine(
      const Offset(0, 0),
      const Offset(cornerLength, 0),
      borderPaint,
    );

    // Top right
    canvas.drawLine(
      Offset(size.width - cornerLength, 0),
      Offset(size.width, 0),
      borderPaint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, cornerLength),
      borderPaint,
    );

    // Bottom left
    canvas.drawLine(
      const Offset(0, cornerLength),
      Offset(0, size.height - cornerLength),
      borderPaint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(cornerLength, size.height),
      borderPaint,
    );

    // Bottom right
    canvas.drawLine(
      Offset(size.width - cornerLength, size.height),
      Offset(size.width, size.height),
      borderPaint,
    );
    canvas.drawLine(
      Offset(size.width, size.height - cornerLength),
      Offset(size.width, size.height),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
