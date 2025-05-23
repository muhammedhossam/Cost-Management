import 'package:documentmanager/AddInvoiceScreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class InvoiceSummaryReportScreen extends StatefulWidget {
  @override
  _InvoiceSummaryReportScreenState createState() => _InvoiceSummaryReportScreenState();
}

class _InvoiceSummaryReportScreenState extends State<InvoiceSummaryReportScreen> {
  DateTimeRange? selectedDateRange;
  String selectedStatus = 'All';
  String selectedClient = 'All';
  List<String> statusOptions = ['All', 'Paid', 'Unpaid', 'Overdue'];
  List<String> clientOptions = ['All'];
  bool isLoadingClients = true;
  bool isLoadingData = false;
  List<Map<String, dynamic>> invoices = [];

  // Summary metrics
  double totalAmount = 0;
  double paidAmount = 0;
  double unpaidAmount = 0;
  int totalInvoices = 0;

  @override
  void initState() {
    super.initState();
    _fetchClientIds();
    _fetchInvoices();
  }

  Future<void> _fetchClientIds() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('invoices').get();
      final clients = <String>{};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final clientId = data['clientId'] ?? '';
        if (clientId.isNotEmpty) {
          clients.add(clientId);
        }
      }

      setState(() {
        clientOptions = ['All', ...clients];
        isLoadingClients = false;
      });
    } catch (e) {
      print("Error fetching client IDs: $e");
      setState(() => isLoadingClients = false);
    }
  }

  Future<void> _fetchInvoices() async {
    setState(() => isLoadingData = true);

    try {
      Query query = FirebaseFirestore.instance.collection('invoices');

      if (selectedClient != 'All') {
        query = query.where('clientId', isEqualTo: selectedClient);
      }

      if (selectedStatus != 'All') {
        query = query.where('status', isEqualTo: selectedStatus);
      }

      if (selectedDateRange != null) {
        query = query
            .where('dueDate',
                isGreaterThanOrEqualTo:
                    Timestamp.fromDate(selectedDateRange!.start))
            .where('dueDate',
                isLessThanOrEqualTo: Timestamp.fromDate(selectedDateRange!.end));
      }

      final snapshot = await query.get();
      final fetchedInvoices = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {...data, 'id': doc.id};
      }).toList();

      // Calculate summary metrics
      double total = 0;
      double paid = 0;
      double unpaid = 0;

      for (var invoice in fetchedInvoices) {
        total += (invoice['totalAmount'] ?? 0).toDouble();
        paid += (invoice['paidAmount'] ?? 0).toDouble();
      }
      unpaid = total - paid;

      setState(() {
        invoices = fetchedInvoices;
        totalAmount = total;
        paidAmount = paid;
        unpaidAmount = unpaid;
        totalInvoices = fetchedInvoices.length;
        isLoadingData = false;
      });
    } catch (e) {
      print("Error fetching invoices: $e");
      setState(() => isLoadingData = false);
    }
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice Summary'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddInvoiceScreen()),
              ).then((_) => _fetchInvoices());
            },
            tooltip: 'Add New Invoice',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters Section
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
                      // Status Dropdown
                      DropdownButtonFormField<String>(
                        value: selectedStatus,
                        decoration: InputDecoration(
                          labelText: 'Invoice Status',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.assignment_turned_in),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: statusOptions.map((status) {
                          return DropdownMenuItem(value: status, child: Text(status));
                        }).toList(),
                        onChanged: (val) {
                          setState(() => selectedStatus = val!);
                          _fetchInvoices();
                        },
                      ),
                      SizedBox(height: 16),

                      // Client Dropdown
                      if (isLoadingClients)
                        Center(child: CircularProgressIndicator())
                      else
                        DropdownButtonFormField<String>(
                          value: selectedClient,
                          decoration: InputDecoration(
                            labelText: 'Select Client',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_outline),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: clientOptions.map((client) {
                            return DropdownMenuItem(value: client, child: Text(client));
                          }).toList(),
                          onChanged: (val) {
                            setState(() => selectedClient = val!);
                            _fetchInvoices();
                          },
                        ),
                      SizedBox(height: 16),

                      // Date Range Picker
                      OutlinedButton.icon(
                        icon: Icon(Icons.date_range),
                        label: Text(
                          selectedDateRange == null
                              ? 'Select Date Range'
                              : '${DateFormat.yMd().format(selectedDateRange!.start)} - ${DateFormat.yMd().format(selectedDateRange!.end)}',
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                            initialDateRange: selectedDateRange,
                          );
                          if (picked != null) {
                            setState(() => selectedDateRange = picked);
                            _fetchInvoices();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Summary Cards
          if (!isLoadingData) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Total Invoices',
                          totalInvoices.toString(),
                          Colors.blue,
                          Icons.description,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _buildSummaryCard(
                          'Total Amount',
                          '\$${totalAmount.toStringAsFixed(2)}',
                          Colors.green,
                          Icons.account_balance,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Paid Amount',
                          '\$${paidAmount.toStringAsFixed(2)}',
                          Colors.green.shade700,
                          Icons.check_circle,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _buildSummaryCard(
                          'Unpaid Amount',
                          '\$${unpaidAmount.toStringAsFixed(2)}',
                          Colors.orange,
                          Icons.warning,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Invoice List
          Expanded(
            child: isLoadingData
                ? Center(child: CircularProgressIndicator())
                : invoices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No invoices found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: invoices.length,
                        itemBuilder: (context, index) {
                          final invoice = invoices[index];
                          final totalAmount = (invoice['totalAmount'] ?? 0).toDouble();
                          final paidAmount = (invoice['paidAmount'] ?? 0).toDouble();
                          final progress = totalAmount > 0 ? (paidAmount / totalAmount) : 0.0;

                          return Card(
                            elevation: 2,
                            margin: EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Invoice #${invoice['id']}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Client: ${invoice['clientId']}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: invoice['status'] == 'Paid'
                                              ? Colors.green.withOpacity(0.1)
                                              : invoice['status'] == 'Overdue'
                                                  ? Colors.red.withOpacity(0.1)
                                                  : Colors.orange.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          invoice['status'] ?? 'Unknown',
                                          style: TextStyle(
                                            color: invoice['status'] == 'Paid'
                                                ? Colors.green
                                                : invoice['status'] == 'Overdue'
                                                    ? Colors.red
                                                    : Colors.orange,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total: \$${totalAmount.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Paid: \$${paidAmount.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      backgroundColor: Colors.grey[200],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        progress >= 1 ? Colors.green : Colors.orange,
                                      ),
                                      minHeight: 8,
                                    ),
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
    );
  }
}
