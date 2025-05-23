import 'package:documentmanager/invoice_status.dart';
import 'package:documentmanager/invoice_summary.dart';
import 'package:documentmanager/payment_history.dart';
import 'package:documentmanager/payment_logging.dart';
import 'package:documentmanager/reciept_generation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Prevent duplicate initialization
  try {
    // Try to initialize only if not already done
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyD0MWojZWiN6GE_BkAjz1hSgANSRkTw3W4",
          authDomain: "documentmanager-8bc79.firebaseapp.com",
          projectId: "documentmanager-8bc79",
          storageBucket: "documentmanager-8bc79.firebasestorage.app",
          messagingSenderId: "75816416281",
          appId: "1:75816416281:web:a3d3b39ebdfcf29964a688",
          measurementId: "G-SZ3KBY265V",
        ),
      );
    }
  } catch (e) {
    print('Firebase initialization skipped: $e');
  }

  runApp(CostManagementApp());
}

class CostManagementApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cost Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
        primaryColor: Color(0xFF2196F3),
        secondaryHeaderColor: Color(0xFF1976D2),
        scaffoldBackgroundColor: Color(0xFFF8F9FA),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
        ),
        cardTheme: CardTheme(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
      ),
      home: MainHome(),
    );
  }
}

class MainHome extends StatefulWidget {
  @override
  _MainHomeState createState() => _MainHomeState();
}

class _MainHomeState extends State<MainHome> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    PaymentLoggingScreen(),
    ReceiptScreen(),
    InvoiceStatusTrackingScreen(),
    PaymentHistoryLogScreen(),
    InvoiceSummaryReportScreen(),
  ];

  final List<String> _titles = [
    'Log Payment',
    'Generate Receipt',
    'Invoice Status',
    'Payment History',
    'Invoice Summary',
  ];

  final List<IconData> _icons = [
    Icons.payment_rounded,
    Icons.receipt_rounded,
    Icons.description_rounded,
    Icons.history_rounded,
    Icons.analytics_rounded,
  ];

  Widget _buildDrawerHeader() {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        image: DecorationImage(
          image: AssetImage('assets/images/drawer_bg.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Theme.of(context).primaryColor.withOpacity(0.9),
            BlendMode.srcOver,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              color: Theme.of(context).primaryColor,
              size: 32,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Cost Management',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Document Manager',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(int index) {
    final isSelected = _currentIndex == index;
    return ListTile(
      leading: Icon(
        _icons[index],
        color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
      ),
      title: Text(
        _titles[index],
        style: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[800],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onTap: () {
        setState(() => _currentIndex = index);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(_icons[_currentIndex], size: 24),
            SizedBox(width: 12),
            Text(_titles[_currentIndex]),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                Icon(Icons.notifications_outlined),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      '3',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {
              // TODO: Implement notifications
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Icon(
                Icons.person_outline,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            _buildDrawerHeader(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  for (int i = 0; i < _titles.length; i++)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: _buildDrawerItem(i),
                    ),
                  Divider(height: 32),
                  ListTile(
                    leading:
                        Icon(Icons.settings_outlined, color: Colors.grey[600]),
                    title: Text('Settings'),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onTap: () {
                      // TODO: Implement settings
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.help_outline, color: Colors.grey[600]),
                    title: Text('Help & Support'),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onTap: () {
                      // TODO: Implement help & support
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: _screens[_currentIndex],
      ),
    );
  }
}
