// ignore_for_file: prefer_typing_uninitialized_variables

import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/bill_model.dart';
import 'package:intl/intl.dart';

import '../models/customer_model.dart';

class PrintService {
  static final PrintService instance = PrintService._();
  PrintService._();

  Future<void> printBill(Bill bill) async {
    try {
      if (kDebugMode) {
        print('Starting to generate PDF...');
      }

      final pdf = pw.Document();

      // Load custom font
      final font = await PdfGoogleFonts.nunitoRegular();
      final boldFont = await PdfGoogleFonts.nunitoBold();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            _buildHeader(
              businessName: bill.business?.name ?? 'Business Name',
              billNumber: bill.id.toString(),
              font: font,
              boldFont: boldFont,
              bill: bill,
            ),
            pw.SizedBox(height: 20),
            _buildCustomerInfo(bill.customer, font, boldFont),
            pw.SizedBox(height: 20),
            _buildBillInfo(bill, font, boldFont),
            pw.SizedBox(height: 20),
            _buildItemsTable(bill, font, boldFont),
            pw.SizedBox(height: 20),
            if (bill.notes?.isNotEmpty ?? false)
              _buildNotes(bill.notes!, font, boldFont),
            pw.SizedBox(height: 20),
            _buildTotal(bill, font, boldFont),
          ],
        ),
      );

      // Show print dialog
      await Printing.layoutPdf(
        onLayout: (_) => pdf.save(),
        name: 'Invoice_${bill.id}_${DateFormat('yyyyMMdd').format(bill.createdAt)}',
        format: PdfPageFormat.a4,
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in printBill:');
        print('Error: $e');
        print('Stack trace:');
        print(stackTrace);
      }
      rethrow;
    }
  }

  pw.Widget _buildHeader({
    required String businessName,
    required String billNumber,
    required pw.Font font,
    required pw.Font boldFont,
    required Bill bill,
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
          pw.Expanded(
            child: pw.Column(
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
                if (bill.business?.address != null)
                  pw.Text(
                    bill.business!.address!,
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                if (bill.business?.phone != null)
                  pw.Text(
                    'Phone: ${bill.business!.phone}',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                if (bill.business?.gstin != null)
                  pw.Text(
                    'GSTIN: ${bill.business!.gstin}',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'INVOICE',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 16,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Bill #',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 16,
                  color: PdfColors.grey700,
                ),
              ),
              pw.Text(
                billNumber,
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 16,
                  color: PdfColors.teal,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                DateFormat('MMM dd, yyyy').format(bill.createdAt),
                style: pw.TextStyle(
                  font: font,
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
              ),
              pw.Text(
                DateFormat('HH:mm').format(bill.createdAt),
                style: pw.TextStyle(
                  font: font,
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCustomerInfo(
      Customer customer, pw.Font font, pw.Font boldFont) {
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
            'Customer Information',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 14,
              color: PdfColors.teal,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            customer.name,
            style: pw.TextStyle(font: boldFont, fontSize: 12),
          ),
          pw.Text(
            customer.phone,
            style: pw.TextStyle(font: font, fontSize: 12),
          ),
          if (customer.gstin.isNotEmpty)
            pw.Text(
              'GSTIN: ${customer.gstin}',
              style: pw.TextStyle(font: font, fontSize: 12),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildBillInfo(Bill bill, pw.Font font, pw.Font boldFont) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
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
              _buildInfoRow('Bill Date:', dateFormat.format(bill.createdAt),
                  font, boldFont),
              _buildInfoRow(
                  'Status:', bill.status.toUpperCase(), font, boldFont),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInfoRow(
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

  pw.Widget _buildItemsTable(Bill bill, pw.Font font, pw.Font boldFont) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(4),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1.5),
        5: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableHeader('Sr.', boldFont),
            _buildTableHeader('Item', boldFont),
            _buildTableHeader('Quantity', boldFont),
            _buildTableHeader('Rate', boldFont),
            _buildTableHeader('GST', boldFont),
            _buildTableHeader('Amount', boldFont),
          ],
        ),
        ...bill.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          return pw.TableRow(
            children: [
              _buildTableCell('${index + 1}', font),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      item.item.name,
                      style: pw.TextStyle(font: font),
                    ),
                    if (item.notes?.isNotEmpty ?? false)
                      pw.Text(
                        item.notes!,
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 8,
                          color: PdfColors.grey700,
                        ),
                      ),
                  ],
                ),
              ),
              _buildTableCell('${item.quantity} ${item.item.unit}', font),
              _buildTableCell('₹${item.price.toStringAsFixed(2)}', font),
              _buildTableCell('${item.gstRate.toStringAsFixed(1)}%', font),
              _buildTableCell('₹${item.total.toStringAsFixed(2)}', font),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildTableHeader(String text, pw.Font boldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: boldFont),
      ),
    );
  }

  pw.Widget _buildTableCell(String text, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text, style: pw.TextStyle(font: font)),
    );
  }

  pw.Widget _buildNotes(String notes, pw.Font font, pw.Font boldFont) {
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

  pw.Widget _buildTotal(Bill bill, pw.Font font, pw.Font boldFont) {
    // Group items by GST rate
    final gstBreakdown = bill.items.where((item) => item.gstRate > 0).fold<Map<double, double>>(
      {},
      (map, item) {
        final rate = item.gstRate;
        map[rate] = (map[rate] ?? 0) + item.gstAmount;
        return map;
      },
    );

    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          _buildTotalRow('Sub Total:', '₹${bill.subTotal.toStringAsFixed(2)}',
              font, boldFont),
          if (gstBreakdown.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Container(
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                border: pw.Border.all(color: PdfColors.grey400),
              ),
              padding: const pw.EdgeInsets.all(5),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'GST Breakdown',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 10,
                      color: PdfColors.teal,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  ...gstBreakdown.entries.map(
                    (entry) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 2),
                      child: _buildTotalRow(
                        '${entry.key}% GST:',
                        '₹${entry.value.toStringAsFixed(2)}',
                        font,
                        font,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  _buildTotalRow(
                    'Total GST:',
                    '₹${bill.gstAmount.toStringAsFixed(2)}',
                    font,
                    boldFont,
                  ),
                ],
              ),
            ),
          ],
          if (bill.deliveryCharge > 0) ...[
            pw.SizedBox(height: 5),
            _buildTotalRow(
              'Delivery Charge:',
              '₹${bill.deliveryCharge.toStringAsFixed(2)}',
              font,
              boldFont,
            ),
          ],
          if (bill.discount > 0) ...[
            pw.SizedBox(height: 5),
            _buildTotalRow(
              'Discount:',
              '-₹${bill.discount.toStringAsFixed(2)}',
              font,
              boldFont,
              textColor: PdfColors.red,
            ),
          ],
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
              vertical: 5,
              horizontal: 10,
            ),
            decoration: pw.BoxDecoration(
              color: PdfColors.teal50,
              border: pw.Border.all(color: PdfColors.teal),
            ),
            child: _buildTotalRow(
              'Total Amount:',
              '₹${bill.total.toStringAsFixed(2)}',
              boldFont,
              boldFont,
              textColor: PdfColors.teal,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTotalRow(
    String label,
    String value,
    pw.Font font,
    pw.Font boldFont, {
    PdfColor textColor = PdfColors.black,
  }) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.SizedBox(
          width: 120,
          child: pw.Text(
            label,
            style: pw.TextStyle(font: font),
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: boldFont,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
