# Document Manager

A comprehensive Flutter application for managing invoices and documents with Firebase integration.

## 🚀 Features

- **Invoice Management**
  - Create and manage invoices
  - Track invoice status
  - Generate invoice summaries
  - View payment history

- **Payment Processing**
  - Log payments
  - Track payment history
  - Generate receipts

- **Firebase Integration**
  - Cloud storage for documents
  - Real-time data synchronization
  - Secure authentication
  - Firestore database

## 🛠️ Technologies Used

- Flutter SDK ^3.6.1
- Firebase Core ^3.13.0
- Firebase Auth ^5.5.3
- Cloud Firestore ^5.6.7
- Firebase Storage ^12.4.5
- PDF Generation (pdf: ^3.11.3)
- Printing Support (printing: ^5.14.2)

## 📋 Prerequisites

- Flutter SDK (^3.6.1)
- Dart SDK
- Firebase project setup
- Android Studio / VS Code
- Git

## 🔧 Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/documentmanager.git
   ```

2. Navigate to project directory:
   ```bash
   cd documentmanager
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Configure Firebase:
   - Create a new Firebase project
   - Add your Firebase configuration files
   - Enable Authentication, Firestore, and Storage services

5. Run the application:
   ```bash
   flutter run
   ```

## 📱 Application Structure

- `main.dart` - Application entry point and main configuration
- `AddInvoiceScreen.dart` - Invoice creation interface
- `invoice_status.dart` - Invoice status tracking
- `invoice_summary.dart` - Invoice summary generation
- `payment_history.dart` - Payment history tracking
- `receipt_generation.dart` - Receipt generation functionality
- `payment_logging.dart` - Payment logging interface
- `models.dart` - Data models
- `firebase_options.dart` - Firebase configuration

## 🔐 Environment Setup

Ensure you have the following environment variables set up in your Firebase configuration:

- Firebase API Key
- Project ID
- Storage Bucket
- Messaging Sender ID
- App ID

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👥 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📞 Support

For support, please open an issue in the GitHub repository or contact the development team.

---

Made with ❤️ using Flutter and Firebase
