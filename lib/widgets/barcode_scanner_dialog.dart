// ignore_for_file: library_private_types_in_public_api

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/barcode_service.dart';

class BarcodeScannerDialog extends StatefulWidget {
  final bool continuousMode;
  final Function(List<String>)? onMultiScan;

  const BarcodeScannerDialog({
    super.key,
    this.continuousMode = false,
    this.onMultiScan,
  });

  @override
  _BarcodeScannerDialogState createState() => _BarcodeScannerDialogState();
}

class _BarcodeScannerDialogState extends State<BarcodeScannerDialog> with SingleTickerProviderStateMixin {
  MobileScannerController? _controller;
  bool _isProcessing = false;
  bool _torchEnabled = false;
  final List<String> _scannedBarcodes = [];
  final _audioPlayer = AudioPlayer();
  final _barcodeService = BarcodeService();
  final _manualController = TextEditingController();
  String _scannedInput = '';
  DateTime? _lastKeyTime;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
    
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    // Create a curved animation
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  Future<void> _initializeScanner() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      setState(() {});
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
      setState(() {});
    }
  }

  Future<void> _processBarcode(String barcode) async {
    debugPrint('Processing barcode: $barcode');
    if (_isProcessing) {
      debugPrint('Already processing a barcode, skipping...');
      return;
    }

    setState(() => _isProcessing = true);
    debugPrint('Started processing barcode...');

    try {
      // Play beep sound
      await _audioPlayer.play(AssetSource('sounds/beep.mp3'));

      final processedBarcode = await _barcodeService.processBarcode(barcode);
      debugPrint('Processed barcode: $processedBarcode');

      if (widget.continuousMode) {
        setState(() {
          if (!_scannedBarcodes.contains(processedBarcode)) {
            _scannedBarcodes.add(processedBarcode);
          }
        });
      } else {
        if (mounted) {
          Navigator.of(context).pop(processedBarcode);
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error processing barcode: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        _processBarcode(barcode.rawValue!);
      }
    }
  }

  void _onManualEntry(String barcode) {
    _processBarcode(barcode);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        Platform.isWindows || Platform.isLinux || Platform.isMacOS;

    return Dialog(
      child: Container(
        width: 600,
        height: isDesktop ? 300 : 500,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ScaleTransition(
                  scale: _animation,
                  child: Icon(
                    isDesktop ? Icons.keyboard : Icons.qr_code_scanner,
                    color: Theme.of(context).colorScheme.primary,
                    size: 40,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isDesktop ? 'Enter Barcode' : 'Scan Barcode',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                IconButton.filledTonal(
                  onPressed: () {
                    _controller?.stop();
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!isDesktop) ...[
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: MobileScanner(
                        controller: _controller,
                        onDetect: _onDetect,
                      ),
                    ),
                    CustomPaint(
                      painter: ScannerOverlayPainter(
                        borderColor: Theme.of(context).colorScheme.primary,
                        scanLineColor: Theme.of(context).colorScheme.secondary,
                      ),
                      child: Container(),
                    ),
                    if (widget.continuousMode && _scannedBarcodes.isNotEmpty)
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surface
                                .withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: [
                                    Text(
                                      'Scanned Items (${_scannedBarcodes.length})',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall,
                                    ),
                                    const Spacer(),
                                    TextButton.icon(
                                      onPressed: _scannedBarcodes.isEmpty
                                          ? null
                                          : () {
                                              setState(() {
                                                _scannedBarcodes.clear();
                                              });
                                            },
                                      icon: const Icon(Icons.clear_all),
                                      label: const Text('Clear All'),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  itemCount: _scannedBarcodes.length,
                                  itemBuilder: (context, index) {
                                    final item = _scannedBarcodes[index];
                                    return Card(
                                      margin: const EdgeInsets.only(right: 8),
                                      child: Container(
                                        width: 200,
                                        padding: const EdgeInsets.all(8),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    item,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.close,
                                                      size: 16),
                                                  onPressed: () {
                                                    setState(() {
                                                      _scannedBarcodes
                                                          .removeAt(index);
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (isDesktop) ...[
              const SizedBox(height: 16),
              Text(
                'Use a barcode scanner or enter manually',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Simply scan your barcode - it will be detected automatically',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
            ],
            RawKeyboardListener(
              focusNode: FocusNode()..requestFocus(),
              onKey: (RawKeyEvent event) {
                if (event is RawKeyDownEvent) {
                  // Accumulate input if it's coming rapidly (likely from a scanner)
                  if (_lastKeyTime != null &&
                      DateTime.now().difference(_lastKeyTime!) <
                          const Duration(milliseconds: 100)) {
                    _scannedInput += event.character ?? '';
                  } else {
                    _scannedInput = event.character ?? '';
                  }
                  _lastKeyTime = DateTime.now();

                  // Process accumulated input when Enter is pressed
                  if (event.logicalKey.keyLabel == 'Enter' &&
                      _scannedInput.isNotEmpty) {
                    _onManualEntry(_scannedInput);
                    _scannedInput = '';
                  }
                }
              },
              child: TextFormField(
                controller: _manualController,
                autofocus: isDesktop,
                decoration: InputDecoration(
                  labelText:
                      isDesktop ? 'Scan or Enter Barcode' : 'Manual Entry',
                  hintText: isDesktop
                      ? 'Use scanner or type barcode/SKU'
                      : 'Enter barcode/SKU',
                  prefixIcon: const Icon(Icons.keyboard),
                  border: const OutlineInputBorder(),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_manualController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _manualController.clear();
                            setState(() {});
                          },
                        ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _manualController.text.isEmpty
                            ? null
                            : () => _onManualEntry(_manualController.text),
                        icon: const Icon(Icons.search),
                        label: const Text('Search'),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
                onFieldSubmitted: _onManualEntry,
              ),
            ),
            const SizedBox(height: 16),
            if (!isDesktop)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _controller?.toggleTorch();
                        setState(() {
                          _torchEnabled = !_torchEnabled;
                        });
                      },
                      icon: Icon(
                          _torchEnabled ? Icons.flash_on : Icons.flash_off),
                      label: Text(_torchEnabled ? 'Torch On' : 'Torch Off'),
                    ),
                  ),
                  if (widget.continuousMode) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _scannedBarcodes.isEmpty
                            ? null
                            : () {
                                Navigator.of(context).pop(_scannedBarcodes);
                              },
                        icon: const Icon(Icons.check),
                        label: const Text('Done'),
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioPlayer.dispose();
    if (_controller != null &&
        !Platform.isWindows &&
        !Platform.isLinux &&
        !Platform.isMacOS) {
      _controller?.stop();
    }
    _controller?.dispose();
    super.dispose();
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final Color borderColor;
  final Color scanLineColor;

  ScannerOverlayPainter({
    required this.borderColor,
    required this.scanLineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    // Draw scanning area border
    final scanAreaSize = size.width * 0.7;
    final left = (size.width - scanAreaSize) / 2;
    final top = (size.height - scanAreaSize) / 2;
    final rect = Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    canvas.drawRRect(rrect, paint);

    // Draw corner highlights
    final cornerLength = scanAreaSize * 0.2;
    paint.color = scanLineColor;
    paint.strokeWidth = 6.0;

    // Top left corner
    canvas.drawLine(
      Offset(left, top + cornerLength),
      Offset(left, top),
      paint,
    );
    canvas.drawLine(
      Offset(left, top),
      Offset(left + cornerLength, top),
      paint,
    );

    // Top right corner
    canvas.drawLine(
      Offset(left + scanAreaSize - cornerLength, top),
      Offset(left + scanAreaSize, top),
      paint,
    );
    canvas.drawLine(
      Offset(left + scanAreaSize, top),
      Offset(left + scanAreaSize, top + cornerLength),
      paint,
    );

    // Bottom left corner
    canvas.drawLine(
      Offset(left, top + scanAreaSize - cornerLength),
      Offset(left, top + scanAreaSize),
      paint,
    );
    canvas.drawLine(
      Offset(left, top + scanAreaSize),
      Offset(left + cornerLength, top + scanAreaSize),
      paint,
    );

    // Bottom right corner
    canvas.drawLine(
      Offset(left + scanAreaSize - cornerLength, top + scanAreaSize),
      Offset(left + scanAreaSize, top + scanAreaSize),
      paint,
    );
    canvas.drawLine(
      Offset(left + scanAreaSize, top + scanAreaSize - cornerLength),
      Offset(left + scanAreaSize, top + scanAreaSize),
      paint,
    );

    // Draw scan line
    final scanLinePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          scanLineColor.withOpacity(0),
          scanLineColor.withOpacity(0.5),
          scanLineColor.withOpacity(0),
        ],
      ).createShader(rect);

    final scanLineRect = Rect.fromLTWH(
      left,
      top + (scanAreaSize * _getScanLinePosition()),
      scanAreaSize,
      6,
    );
    canvas.drawRect(scanLineRect, scanLinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  double _getScanLinePosition() {
    const duration = Duration(milliseconds: 1500);
    final time = DateTime.now().millisecondsSinceEpoch;
    return ((time % duration.inMilliseconds) / duration.inMilliseconds);
  }
}
