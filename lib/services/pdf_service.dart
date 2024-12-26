import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/purchase_order_model.dart';
import '../models/supplier_model.dart';
import '../models/inventory_item_model.dart';
import 'package:intl/intl.dart';

class PdfService {
  static Future<Uint8List> generatePurchaseOrderPdf({
    required PurchaseOrder order,
    required Supplier supplier,
    required List<InventoryItem> items,
    required String businessName,
    required String currency,
  }) async {
    final pdf = pw.Document();

    // Load custom font
    final font = await PdfGoogleFonts.nunitoRegular();
    final boldFont = await PdfGoogleFonts.nunitoBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _buildHeader(
            businessName: businessName,
            orderNumber: order.orderNumber,
            font: font,
            boldFont: boldFont,
          ),
          pw.SizedBox(height: 20),
          _buildSupplierInfo(supplier, font, boldFont),
          pw.SizedBox(height: 20),
          _buildOrderInfo(order, font, boldFont),
          pw.SizedBox(height: 20),
          _buildItemsTable(order.items, items, currency, font, boldFont),
          pw.SizedBox(height: 20),
          if (order.notes?.isNotEmpty ?? false)
            _buildNotes(order.notes!, font, boldFont),
          pw.SizedBox(height: 20),
          _buildTotal(order.items, currency, font, boldFont),
        ],
      ),
    );

    return pdf.save();
  }

  static Future<void> printPurchaseOrder({
    required PurchaseOrder order,
    required Supplier supplier,
    required List<InventoryItem> items,
    required String businessName,
    required String currency,
  }) async {
    final pdfBytes = await generatePurchaseOrderPdf(
      order: order,
      supplier: supplier,
      items: items,
      businessName: businessName,
      currency: currency,
    );

    await Printing.layoutPdf(
      onLayout: (_) => Future.value(pdfBytes),
    );
  }

  static pw.Widget _buildHeader({
    required String businessName,
    required String orderNumber,
    required pw.Font font,
    required pw.Font boldFont,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.teal),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      padding: const pw.EdgeInsets.all(10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                businessName,
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 24,
                  color: PdfColors.teal,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Purchase Order',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 16,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Order #',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 16,
                  color: PdfColors.grey700,
                ),
              ),
              pw.Text(
                orderNumber,
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 16,
                  color: PdfColors.teal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSupplierInfo(
      Supplier supplier, pw.Font font, pw.Font boldFont) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      padding: const pw.EdgeInsets.all(10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Supplier Information',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 14,
              color: PdfColors.teal,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            supplier.name,
            style: pw.TextStyle(font: boldFont, fontSize: 12),
          ),
          pw.Text(
            supplier.phone,
            style: pw.TextStyle(font: font, fontSize: 12),
          ),
          if (supplier.address.isNotEmpty)
            pw.Text(
              supplier.address,
              style: pw.TextStyle(font: font, fontSize: 12),
            ),
        ],
      ),
    );
  }

  static pw.Widget _buildOrderInfo(
      PurchaseOrder order, pw.Font font, pw.Font boldFont) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      padding: const pw.EdgeInsets.all(10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildInfoRow(
                  'Order Date:',
                  DateFormat('MMM dd, yyyy')
                      .format(DateTime.parse(order.orderDate)),
                  font,
                  boldFont),
              if (order.expectedDate != null)
                _buildInfoRow(
                    'Expected Delivery:',
                    DateFormat('MMM dd, yyyy')
                        .format(DateTime.parse(order.expectedDate!)),
                    font,
                    boldFont),
              _buildInfoRow(
                  'Status:', order.status.toUpperCase(), font, boldFont),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoRow(
      String label, String value, pw.Font font, pw.Font boldFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(font: font, color: PdfColors.grey700),
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(font: boldFont),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildItemsTable(
    List<PurchaseOrderItem> orderItems,
    List<InventoryItem> items,
    String currency,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(4),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableHeader('Item', boldFont),
            _buildTableHeader('Quantity', boldFont),
            _buildTableHeader('Unit Price', boldFont),
            _buildTableHeader('Total', boldFont),
          ],
        ),
        ...orderItems.map((orderItem) {
          final item = items.firstWhere((i) => i.id == orderItem.itemId);
          final total = orderItem.quantity * orderItem.unitPrice;

          return pw.TableRow(
            children: [
              _buildTableCell(item.name, font),
              _buildTableCell(orderItem.quantity.toString(), font),
              _buildTableCell(
                  '$currency ${orderItem.unitPrice.toStringAsFixed(2)}', font),
              _buildTableCell('$currency ${total.toStringAsFixed(2)}', font),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildTableHeader(String text, pw.Font boldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: boldFont),
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text, style: pw.TextStyle(font: font)),
    );
  }

  static pw.Widget _buildNotes(String notes, pw.Font font, pw.Font boldFont) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      padding: const pw.EdgeInsets.all(10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Notes',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 14,
              color: PdfColors.teal,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            notes,
            style: pw.TextStyle(font: font, fontSize: 12),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTotal(List<PurchaseOrderItem> items, String currency,
      pw.Font font, pw.Font boldFont) {
    final total = items.fold<double>(
      0,
      (sum, item) => sum + (item.quantity * item.unitPrice),
    );

    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.teal),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        ),
        padding: const pw.EdgeInsets.all(10),
        child: pw.Row(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Text(
              'Total: ',
              style: pw.TextStyle(font: boldFont, fontSize: 14),
            ),
            pw.Text(
              '$currency ${total.toStringAsFixed(2)}',
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 14,
                color: PdfColors.teal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
