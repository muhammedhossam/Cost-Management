import 'package:documentmanager/AddInvoiceScreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class PaymentLoggingScreen extends StatefulWidget {
  @override
  _PaymentLoggingScreenState createState() => _PaymentLoggingScreenState();
}

class _PaymentLoggingScreenState extends State<PaymentLoggingScreen> {
  String? selectedInvoiceId;
  final amountController = TextEditingController();
  String paymentMethod = 'Cash';
  final methods = ['Cash', 'Credit', 'Bank'];

  double totalAmount = 0.0;
  double paidAmount = 0.0;

  Future<void> logPayment() async {
    if (selectedInvoiceId == null || amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please select an invoice and enter amount"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final amount = double.tryParse(amountController.text);
    final remainingAmount = totalAmount - paidAmount;

    if (amount == null || amount <= 0 || amount > remainingAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Enter a valid amount up to ${remainingAmount.toStringAsFixed(2)}"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final paymentData = {
        'invoiceId': selectedInvoiceId,
        'amount': amount,
        'method': paymentMethod,
        'date': Timestamp.now(),
      };

      final invoiceRef = FirebaseFirestore.instance
          .collection('invoices')
          .doc(selectedInvoiceId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final invoiceSnapshot = await transaction.get(invoiceRef);

        if (!invoiceSnapshot.exists) throw Exception("Invoice not found");

        final currentPaid = (invoiceSnapshot.get('paidAmount') ?? 0).toDouble();

        transaction.set(
          FirebaseFirestore.instance.collection('payments').doc(),
          paymentData,
        );

        transaction.update(invoiceRef, {
          'paidAmount': currentPaid + amount,
        });
      });

      amountController.clear();
      setState(() {
        selectedInvoiceId = null;
        paymentMethod = 'Cash';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Payment logged successfully"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error logging payment: ${e.toString()}"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> fetchInvoiceDetails(String invoiceId) async {
    final invoiceRef =
        FirebaseFirestore.instance.collection('invoices').doc(invoiceId);
    final invoiceSnapshot = await invoiceRef.get();
    if (invoiceSnapshot.exists) {
      setState(() {
        totalAmount = (invoiceSnapshot.get('totalAmount') ?? 0).toDouble();
        paidAmount = (invoiceSnapshot.get('paidAmount') ?? 0).toDouble();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Log New Payment',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    SizedBox(height: 24),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('invoices')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData)
                          return Center(child: CircularProgressIndicator());

                        final invoices = snapshot.data!.docs;

                        return Column(
                          children: [
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Select Invoice',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.description),
                              ),
                              value: selectedInvoiceId,
                              items: invoices.map((doc) {
                                final clientname = doc.id;
                                return DropdownMenuItem(
                                  value: doc.id,
                                  child: Text('Invoice: $clientname'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  selectedInvoiceId = val;
                                  if (val != null) fetchInvoiceDetails(val);
                                });
                              },
                            ),
                            if (selectedInvoiceId != null) ...[
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Card(
                                      color: Colors.blue.shade50,
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          children: [
                                            Text(
                                              'Total Amount',
                                              style: TextStyle(
                                                color: Colors.blue.shade900,
                                              ),
                                            ),
                                            Text(
                                              '\$${totalAmount.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue.shade900,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Card(
                                      color: Colors.green.shade50,
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          children: [
                                            Text(
                                              'Paid Amount',
                                              style: TextStyle(
                                                color: Colors.green.shade900,
                                              ),
                                            ),
                                            Text(
                                              '\$${paidAmount.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green.shade900,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      decoration: InputDecoration(
                        labelText: 'Payment Amount',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Payment Method',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.payment),
                      ),
                      value: paymentMethod,
                      items: methods.map((method) {
                        return DropdownMenuItem(
                          value: method,
                          child: Text(method),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => paymentMethod = val!),
                    ),
                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.save),
                        label: Text("LOG PAYMENT"),
                        onPressed: logPayment,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
