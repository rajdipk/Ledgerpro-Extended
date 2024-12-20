import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import '../models/bill_model.dart';

class PrintService {
  static Future<void> printBill(Bill bill) async {
    final pdf = pw.Document();

    // Get business logo if exists
    pw.MemoryImage? logoImage;
    if (bill.business?.logo != null) {
      try {
        final logoBytes = File(bill.business!.logo!).readAsBytesSync();
        logoImage = pw.MemoryImage(logoBytes);
      } catch (e) {
        print('Error loading logo: $e');
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with logo and business details
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (logoImage != null)
                    pw.Container(
                      width: 60,
                      height: 60,
                      child: pw.Image(logoImage),
                    ),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          bill.business?.name ?? 'Business Name',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        if (bill.business?.address != null)
                          pw.Text(bill.business!.address!),
                        if (bill.business?.phone != null)
                          pw.Text('Phone: ${bill.business!.phone}'),
                        if (bill.business?.gstin != null)
                          pw.Text('GSTIN: ${bill.business!.gstin}'),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Bill details
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Bill No: ${bill.id}'),
                        pw.Text(
                          'Date: ${bill.createdAt.toString().split(' ')[0]}',
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Customer Details:'),
                        pw.Text(bill.customer.name),
                        pw.Text('Phone: ${bill.customer.phone}'),
                        pw.Text('GSTIN: ${bill.customer.gstin}'),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Items table
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1),
                  1: const pw.FlexColumnWidth(4),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(2),
                  4: const pw.FlexColumnWidth(2),
                },
                children: [
                  // Table header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Sr.',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Item',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Qty',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Rate',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Amount',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  // Item rows
                  ...bill.items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('${index + 1}'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(item.item.name),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('${item.quantity}'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            item.item.sellingPrice.toStringAsFixed(2),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            (item.quantity * item.item.sellingPrice).toStringAsFixed(2),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
              pw.SizedBox(height: 20),

              // Bill summary
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text('Sub Total: '),
                        pw.SizedBox(width: 20),
                        pw.Text('₹${bill.subTotal.toStringAsFixed(2)}'),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text('GST (${(bill.gstAmount / bill.subTotal * 100).toStringAsFixed(0)}%): '),
                        pw.SizedBox(width: 20),
                        pw.Text('₹${bill.gstAmount.toStringAsFixed(2)}'),
                      ],
                    ),
                    if (bill.discount > 0) ...[
                      pw.SizedBox(height: 5),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text('Discount: '),
                          pw.SizedBox(width: 20),
                          pw.Text('₹${bill.discount.toStringAsFixed(2)}'),
                        ],
                      ),
                    ],
                    pw.SizedBox(height: 5),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        vertical: 5,
                        horizontal: 10,
                      ),
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey300,
                      ),
                      child: pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Text(
                            'Total: ',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(width: 20),
                          pw.Text(
                            '₹${bill.total.toStringAsFixed(2)}',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Notes
              if (bill.notes != null && bill.notes!.isNotEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Notes:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(bill.notes!),
                    ],
                  ),
                ),

              // Footer
              pw.Expanded(child: pw.SizedBox()),
              pw.Container(
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'Thank you for your business!',
                  style: pw.TextStyle(
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Get the temporary directory
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/bill_${bill.id}.pdf');
    
    // Save PDF
    await file.writeAsBytes(await pdf.save());

    // Print or share
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
