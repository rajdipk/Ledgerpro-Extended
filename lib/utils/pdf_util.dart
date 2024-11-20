// ignore_for_file: avoid_print

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

import '../models/customer_model.dart';
import '../models/business_model.dart';
import '../models/transaction_model.dart';
import '../models/supplier_model.dart';

class PdfUtil {
  static Future<File> generatePdf(
    Customer customer,
    Business business,
    List<Transaction> transactions,
  ) async {
    final pdf = pw.Document();

    final font = await rootBundle.load("assets/fonts/NotoSans-Regular.ttf");
    final boldFont = await rootBundle.load("assets/fonts/NotoSans-Bold.ttf");

    final ttf = pw.Font.ttf(font);
    final boldTtf = pw.Font.ttf(boldFont);

    double totalCredits = 0;
    double totalDebits = 0;

    for (var transaction in transactions) {
      if (transaction.amount >= 0) {
        totalCredits += transaction.amount;
      } else {
        totalDebits += transaction.amount.abs();
      }
    }

    double finalBalance = totalCredits - totalDebits;
    double runningBalance = 0;

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Transaction Report for ${customer.name}',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  font: boldTtf,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                  'Phone: ${customer.phone.isNotEmpty ? customer.phone : 'Not available'}',
                  style: pw.TextStyle(fontSize: 12, font: ttf)),
              pw.SizedBox(height: 8),
              pw.Text(
                  'Address: ${customer.address.isNotEmpty ? customer.address : 'Not available'}',
                  style: pw.TextStyle(fontSize: 12, font: ttf)),
              pw.SizedBox(height: 8),
              pw.Text(
                  'PAN: ${customer.pan.isNotEmpty ? customer.pan : 'Not available'}',
                  style: pw.TextStyle(fontSize: 12, font: ttf)),
              pw.SizedBox(height: 8),
              pw.Text(
                  'GSTIN: ${customer.gstin.isNotEmpty ? customer.gstin : 'Not available'}',
                  style: pw.TextStyle(fontSize: 12, font: ttf)),
              pw.SizedBox(height: 16),
              pw.Divider(thickness: 2),
              pw.Container(
                color: PdfColors.grey200,
                padding: const pw.EdgeInsets.symmetric(
                    vertical: 8.0, horizontal: 16.0),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                        child: pw.Text('Date',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                font: boldTtf))),
                    pw.Expanded(
                        child: pw.Text('Received (₹)',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                font: boldTtf))),
                    pw.Expanded(
                        child: pw.Text('Given (₹)',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                font: boldTtf))),
                    pw.Expanded(
                        child: pw.Text('Balance (₹)',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, font: boldTtf),
                            textAlign: pw.TextAlign.right)),
                  ],
                ),
              ),
              pw.Divider(thickness: 2),
              ...transactions.map((transaction) {
                final isReceived = transaction.amount >= 0;
                final textColor = isReceived ? PdfColors.green : PdfColors.red;

                runningBalance += transaction.amount;

                return pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.grey300),
                    ),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          DateFormat("dd/MM/yyyy")
                              .format(DateTime.parse(transaction.date)),
                          style:
                              pw.TextStyle(color: PdfColors.black, font: ttf),
                          textAlign: pw.TextAlign.left,
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          isReceived
                              ? transaction.amount.toStringAsFixed(2)
                              : '',
                          style:
                              pw.TextStyle(color: PdfColors.black, font: ttf),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          isReceived
                              ? ''
                              : transaction.amount.abs().toStringAsFixed(2),
                          style:
                              pw.TextStyle(color: PdfColors.black, font: ttf),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          runningBalance.toStringAsFixed(2),
                          style: pw.TextStyle(
                              color: textColor,
                              fontWeight: pw.FontWeight.bold,
                              font: boldTtf),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              pw.Divider(thickness: 2),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    vertical: 8.0, horizontal: 16.0),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Total Given: ₹${totalDebits.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.red,
                          font: boldTtf),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Total Received: ₹${totalCredits.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green,
                          font: boldTtf),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Final Balance: ₹${finalBalance.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: finalBalance >= 0
                              ? PdfColors.green
                              : PdfColors.red,
                          font: boldTtf),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                        finalBalance >= 0
                            ? '${customer.name} will get ₹${finalBalance.abs().toStringAsFixed(2)} from ${business.name}.'
                            : '${business.name} will receive ₹${finalBalance.abs().toStringAsFixed(2)} from ${customer.name}.',
                        style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: finalBalance >= 0
                                ? PdfColors.green
                                : PdfColors.red,
                            font: boldTtf)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file =
        File("${output.path}/Transaction Report for ${customer.name}.pdf");
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static Future<void> sharePdf(
    Customer customer,
    Business business,
    List<Transaction> transactions,
  ) async {
    try {
      final file = await generatePdf(customer, business, transactions);
      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      print('Error sharing PDF: $e');
      throw Exception('Error sharing PDF: $e');
    }
  }

  static Future<String?> savePdf(
    Customer customer,
    Business business,
    List<Transaction> transactions,
  ) async {
    try {
      final file = await generatePdf(customer, business, transactions);
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Please select an output file:',
        fileName: 'Transaction Report for ${customer.name}.pdf',
      );

      if (result == null) {
        // The user canceled the file picker
        return null;
      }

      final output = File(result);
      final bytes = await file.readAsBytes();

      // Log the length of bytes array before writing
      print('Bytes length: ${bytes.length}');

      await output.writeAsBytes(bytes);
      return output.path;
    } catch (e) {
      print('Error saving PDF: $e');
      return null;
    }
  }

  static Future<File?> shareSupplierPdf(
    Supplier supplier,
    Business business,
    List<Transaction> transactions, {
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final pdf = await generateSupplierPdf(supplier, business, transactions,
        fromDate: fromDate, toDate: toDate);
    final String fileName =
        'supplier_report_${supplier.name}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)]);
    return file;
  }

  static Future<File?> saveSupplierPdf(
    Supplier supplier,
    Business business,
    List<Transaction> transactions, {
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final pdf = await generateSupplierPdf(supplier, business, transactions,
        fromDate: fromDate, toDate: toDate);
    final String fileName =
        'supplier_report_${supplier.name}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save PDF File',
      fileName: fileName,
    );

    if (outputFile == null) {
      return null;
    }

    final file = File(outputFile);
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static Future<pw.Document> generateSupplierPdf(
    Supplier supplier,
    Business business,
    List<Transaction> transactions, {
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final pdf = pw.Document();

    final font = await rootBundle.load("assets/fonts/NotoSans-Regular.ttf");
    final boldFont = await rootBundle.load("assets/fonts/NotoSans-Bold.ttf");

    final ttf = pw.Font.ttf(font);
    final boldTtf = pw.Font.ttf(boldFont);

    List<Transaction> filteredTransactions = transactions;
    if (fromDate != null && toDate != null) {
      filteredTransactions = transactions.where((transaction) {
        final transactionDate = DateTime.parse(transaction.date);
        return transactionDate.isAfter(fromDate) &&
            transactionDate.isBefore(toDate.add(const Duration(days: 1)));
      }).toList();
    }

    double totalReceived = 0;
    double totalGiven = 0;

    for (var transaction in filteredTransactions) {
      if (transaction.amount >= 0) {
        totalReceived += transaction.amount;
      } else {
        totalGiven += transaction.amount.abs();
      }
    }

    double finalBalance = totalReceived - totalGiven;

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Transaction Report for ${supplier.name}',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  font: boldTtf,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                  'Phone: ${supplier.phone.isNotEmpty ? supplier.phone : 'Not available'}',
                  style: pw.TextStyle(fontSize: 12, font: ttf)),
              pw.SizedBox(height: 8),
              pw.Text(
                  'Address: ${supplier.address.isNotEmpty ? supplier.address : 'Not available'}',
                  style: pw.TextStyle(fontSize: 12, font: ttf)),
              pw.SizedBox(height: 8),
              pw.Text(
                  'PAN: ${supplier.pan.isNotEmpty ? supplier.pan : 'Not available'}',
                  style: pw.TextStyle(fontSize: 12, font: ttf)),
              pw.SizedBox(height: 8),
              pw.Text(
                  'GSTIN: ${supplier.gstin.isNotEmpty ? supplier.gstin : 'Not available'}',
                  style: pw.TextStyle(fontSize: 12, font: ttf)),
              pw.SizedBox(height: 16),
              pw.Divider(thickness: 2),
              if (fromDate != null && toDate != null) ...[
                pw.Text(
                  'Period: ${DateFormat('MMM dd, yyyy').format(fromDate)} to ${DateFormat('MMM dd, yyyy').format(toDate)}',
                  style: pw.TextStyle(fontSize: 12, font: ttf),
                ),
                pw.SizedBox(height: 8),
              ],
              pw.Container(
                color: PdfColors.grey200,
                padding: const pw.EdgeInsets.symmetric(
                    vertical: 8.0, horizontal: 16.0),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                        child: pw.Text('Date',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                font: boldTtf))),
                    pw.Expanded(
                        child: pw.Text('Received (₹)',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                font: boldTtf))),
                    pw.Expanded(
                        child: pw.Text('Given (₹)',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                font: boldTtf))),
                    pw.Expanded(
                        child: pw.Text('Balance (₹)',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                font: boldTtf))),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),
              ...filteredTransactions.map((transaction) {
                return pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      vertical: 4.0, horizontal: 16.0),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                          child: pw.Text(
                              DateFormat('MMM dd, yyyy')
                                  .format(DateTime.parse(transaction.date)),
                              style: pw.TextStyle(font: ttf))),
                      pw.Expanded(
                          child: pw.Text(
                              transaction.amount >= 0
                                  ? transaction.amount.toStringAsFixed(2)
                                  : '',
                              style: pw.TextStyle(font: ttf))),
                      pw.Expanded(
                          child: pw.Text(
                              transaction.amount < 0
                                  ? transaction.amount.abs().toStringAsFixed(2)
                                  : '',
                              style: pw.TextStyle(font: ttf))),
                      pw.Expanded(
                          child: pw.Text(
                              transaction.balance.toStringAsFixed(2),
                              style: pw.TextStyle(font: ttf))),
                    ],
                  ),
                );
              }),
              pw.SizedBox(height: 16),
              pw.Divider(thickness: 2),
              pw.Container(
                padding: const pw.EdgeInsets.all(16.0),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total Received:',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                font: boldTtf)),
                        pw.Text('₹${totalReceived.toStringAsFixed(2)}',
                            style: pw.TextStyle(font: ttf)),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total Given:',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                font: boldTtf)),
                        pw.Text('₹${totalGiven.toStringAsFixed(2)}',
                            style: pw.TextStyle(font: ttf)),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Net Balance:',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                font: boldTtf)),
                        pw.Text('₹${finalBalance.toStringAsFixed(2)}',
                            style: pw.TextStyle(font: ttf)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }
}
