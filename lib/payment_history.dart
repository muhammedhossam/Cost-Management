import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PaymentHistoryLogScreen extends StatefulWidget {
  @override
  _PaymentFilterScreenState createState() => _PaymentFilterScreenState();
}

class _PaymentFilterScreenState extends State<PaymentHistoryLogScreen> {
  final _invoiceIdController = TextEditingController();
  final _amountController = TextEditingController();

  String? _selectedMethod;
  DateTime? _startDate;
  DateTime? _endDate;

  List<Map<String, dynamic>> _filteredPayments = [];
  bool _loading = false;
  String? _error;

  final List<String> _paymentMethods = ['Cash', 'Credit', 'Bank'];

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  void _resetFilters() {
    setState(() {
      _invoiceIdController.clear();
      _amountController.clear();
      _selectedMethod = null;
      _startDate = null;
      _endDate = null;
      _filteredPayments = [];
      _error = null;
    });
  }

  Future<void> _searchPayments() async {
    final invoiceId = _invoiceIdController.text.trim();
    if (invoiceId.isEmpty) {
      setState(() => _error = "Please enter an invoice ID");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _filteredPayments = [];
    });

    try {
      Query query = FirebaseFirestore.instance
          .collection('payments')
          .where('invoiceId', isEqualTo: invoiceId);

      // Filtering by method
      if (_selectedMethod != null && _selectedMethod!.isNotEmpty) {
        query = query.where('method', isEqualTo: _selectedMethod);
      }

      // For amount, Firestore requires exact match or range
      if (_amountController.text.isNotEmpty) {
        final amount = double.tryParse(_amountController.text);
        if (amount != null) {
          query = query.where('amount', isEqualTo: amount);
        }
      }

      // Date filtering (range)
      if (_startDate != null) {
        query = query.where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate!));
      }
      if (_endDate != null) {
        query = query.where('date',
            isLessThanOrEqualTo: Timestamp.fromDate(_endDate!));
      }

      // // Order by date descending
      // query = query.orderBy('date', descending: true);

      final snapshot = await query.get();

      final payments = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      setState(() {
        _filteredPayments = payments;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Error fetching payments: $e";
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _invoiceIdController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment History'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _resetFilters,
            tooltip: 'Reset Filters',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: ExpansionTile(
              title: Text(
                'Filter Options',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              leading: Icon(Icons.filter_list),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Invoice ID Field
                      TextField(
                        controller: _invoiceIdController,
                        decoration: InputDecoration(
                          labelText: 'Invoice ID',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.receipt),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      // Amount Field
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      // Payment Method Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedMethod,
                        decoration: InputDecoration(
                          labelText: 'Payment Method',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.payment),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: [
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text('Any Method'),
                          ),
                          ..._paymentMethods.map((method) {
                            return DropdownMenuItem<String>(
                              value: method,
                              child: Text(method),
                            );
                          }).toList(),
                        ],
                        onChanged: (val) => setState(() => _selectedMethod = val),
                      ),
                      SizedBox(height: 16),
                      
                      // Date Range Selectors
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: Icon(Icons.calendar_today),
                              label: Text(_startDate == null
                                  ? 'Start Date'
                                  : DateFormat.yMd().format(_startDate!)),
                              onPressed: _pickStartDate,
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: Icon(Icons.calendar_today),
                              label: Text(_endDate == null
                                  ? 'End Date'
                                  : DateFormat.yMd().format(_endDate!)),
                              onPressed: _pickEndDate,
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                      
                      // Search Button
                      ElevatedButton.icon(
                        icon: Icon(Icons.search),
                        label: Text('SEARCH PAYMENTS'),
                        onPressed: _searchPayments,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Error Message
          if (_error != null)
            Container(
              padding: EdgeInsets.all(8),
              margin: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade900),
                    ),
                  ),
                ],
              ),
            ),
          
          // Loading Indicator or Results
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator())
                : _filteredPayments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No payments found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(8),
                        itemCount: _filteredPayments.length,
                        itemBuilder: (context, index) {
                          final payment = _filteredPayments[index];
                          final date = (payment['date'] as Timestamp).toDate();
                          final formattedDate = DateFormat.yMMMd().add_jm().format(date);
                          
                          return Card(
                            elevation: 2,
                            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                child: Icon(
                                  payment['method'] == 'Cash'
                                      ? Icons.money
                                      : payment['method'] == 'Credit'
                                          ? Icons.credit_card
                                          : Icons.account_balance,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    '\$${payment['amount']}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      payment['method'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 8),
                                  Text('Invoice ID: ${payment['invoiceId']}'),
                                  Text('Date: $formattedDate'),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
