import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReceiptScreen extends StatefulWidget {
  @override
  _ReceiptScreenState createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  String? selectedPaymentId;
  Map<String, dynamic>? selectedPayment;
  Map<String, String> invoiceClientMap = {}; // invoiceId -> clientId

  Future<List<QueryDocumentSnapshot>> fetchPayments() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('payments')
        .orderBy('date', descending: true)
        .get();

    final payments = snapshot.docs;

    // Fetch clientId for each invoice
    for (var payment in payments) {
      final invoiceId = payment['invoiceId'];
      final invoiceSnapshot = await FirebaseFirestore.instance
          .collection('invoices')
          .doc(invoiceId)
          .get();

      if (invoiceSnapshot.exists) {
        final clientId = invoiceSnapshot['clientId'];
        invoiceClientMap[invoiceId] = clientId;
      }
    }

    return payments;
  }

  Future<pw.Document> generateReceiptPdf(
      Map<String, dynamic> payment, String paymentId) async {
    final date = (payment['date'] as Timestamp).toDate();
    final formattedDate = DateFormat.yMMMd().add_jm().format(date);
    final invoiceId = payment['invoiceId'];
    final clientId = invoiceClientMap[invoiceId] ?? "Unknown";

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Padding(
          padding: const pw.EdgeInsets.all(24),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("🧾 Payment Receipt",
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 16),
              pw.Text("Client ID: $clientId"),
              pw.Text("Invoice ID: $invoiceId"),
              pw.Text("Payment ID: $paymentId"),
              pw.Text("Amount Paid: \$${payment['amount']}"),
              pw.Text("Payment Method: ${payment['method']}"),
              pw.Text("Date: $formattedDate"),
              pw.SizedBox(height: 20),
              pw.Text("Thank you for your payment!",
                  style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
            ],
          ),
        ),
      ),
    );

    return pdf;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Receipts'),
        elevation: 0,
      ),
      body: FutureBuilder<List<QueryDocumentSnapshot>>(
        future: fetchPayments(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());

          final payments = snapshot.data!;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Payment',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              hintText: 'Choose a payment to view receipt',
                            ),
                            value: selectedPaymentId,
                            items: payments.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final invoiceId = data['invoiceId'];
                              final clientId = invoiceClientMap[invoiceId] ?? "Unknown";
                              final date = (data['date'] as Timestamp).toDate();
                              final formatted = DateFormat.yMd().add_jm().format(date);

                              return DropdownMenuItem(
                                value: doc.id,
                                child: Text(
                                  '$clientId - \$${data['amount']} on $formatted',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                selectedPaymentId = val;
                                selectedPayment = payments
                                    .firstWhere((doc) => doc.id == val!)
                                    .data() as Map<String, dynamic>;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (selectedPayment != null) buildReceipt(selectedPayment!),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildReceipt(Map<String, dynamic> payment) {
    final date = (payment['date'] as Timestamp).toDate();
    final formattedDate = DateFormat.yMMMd().add_jm().format(date);
    final invoiceId = payment['invoiceId'];
    final clientId = invoiceClientMap[invoiceId] ?? "Unknown";

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Text(
              "Payment Receipt",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReceiptRow("Client ID", clientId),
                _buildReceiptRow("Invoice ID", invoiceId),
                _buildReceiptRow("Payment ID", selectedPaymentId ?? ""),
                _buildReceiptRow("Amount Paid", "\$${payment['amount']}"),
                _buildReceiptRow("Payment Method", payment['method']),
                _buildReceiptRow("Date", formattedDate),
                Divider(height: 32),
                Text(
                  "Thank you for your payment!",
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                    ),
                    icon: Icon(Icons.picture_as_pdf),
                    label: Text(
                      "Export as PDF",
                      style: TextStyle(fontSize: 16),
                    ),
                    onPressed: () async {
                      final pdf = await generateReceiptPdf(payment, selectedPaymentId!);
                      await Printing.layoutPdf(onLayout: (format) => pdf.save());
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label + ":",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
