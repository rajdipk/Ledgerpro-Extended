import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../screens/billing/add_bill_item_dialog.dart';
import '../widgets/barcode_scanner_dialog.dart';

class KeyboardShortcutsService {
  static final Map<LogicalKeySet, String> _shortcuts = {
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyB): 'Scan Barcode',
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyM): 'Multi-Scan',
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyI): 'Add Item',
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyP): 'Print Bill',
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS): 'Save Bill',
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyC): 'Cancel Bill',
  };

  static Map<LogicalKeySet, Intent> getShortcuts(BuildContext context) {
    return {
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyB):
          VoidCallbackIntent(() => _handleBarcodeScan(context, false)),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyM):
          VoidCallbackIntent(() => _handleBarcodeScan(context, true)),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyI):
          VoidCallbackIntent(() => _handleAddItem(context)),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyP):
          VoidCallbackIntent(() => _handlePrintBill(context)),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS):
          VoidCallbackIntent(() => _handleSaveBill(context)),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyC):
          VoidCallbackIntent(() => _handleCancelBill(context)),
    };
  }

  static String? getShortcutLabel(LogicalKeySet shortcut) {
    return _shortcuts[shortcut];
  }

  static void _handleBarcodeScan(BuildContext context, bool multiScan) {
    showDialog(
      context: context,
      builder: (context) => BarcodeScannerDialog(
        continuousMode: multiScan,
        onMultiScan: multiScan ? (barcodes) async {
          // Handle multi-scan result
          Navigator.pop(context);
          // Process barcodes...
        } : null,
      ),
    );
  }

  static void _handleAddItem(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddBillItemDialog(),
    );
  }

  static void _handlePrintBill(BuildContext context) {
    // Handle print bill action
  }

  static void _handleSaveBill(BuildContext context) {
    // Handle save bill action
  }

  static void _handleCancelBill(BuildContext context) {
    // Handle cancel bill action
  }
}
