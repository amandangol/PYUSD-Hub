# PYUSD Hub

![PYUSD Hub Logo](assets/images/pyusdlogo.png)

PYUSD Hub is a comprehensive mobile wallet application for managing PYUSD (PayPal USD) and ETH on the Ethereum network. It combines secure wallet functionality with advanced analytics and network monitoring tools.

Built with Flutter, PYUSD Hub offers a seamless experience for both casual users and crypto enthusiasts, providing intuitive access to the growing PYUSD ecosystem while enabling detailed blockchain insights. From simple token transfers to complex MEV analysis, the application serves as a complete solution for PYUSD token management on the go.

## 🔐 Authentication & Security

Our secure authentication process ensures your assets remain protected:

- **Secure Wallet Creation**: Create wallets with customizable PIN and biometric authentication
- **Mnemonic Backup**: Generate and securely store your 12-word recovery phrase
- **Import Functionality**: Easily import existing wallets using recovery phrases
- **Multi-factor Authentication**: Additional security layers for sensitive operations
- **Session Management**: Automatic session timeout and secure state persistence

```dart
// Authentication flow overview
class AuthProvider extends ChangeNotifier {
  // Secure wallet creation with encryption
  Future<bool> createWallet(String pin, bool enableBiometrics) async {...}
  
  // Recovery phrase management
  List<String> generateMnemonic() => {...}
  
  // Wallet import functionality
  Future<bool> importWalletFromMnemonic(String mnemonic, String pin) async {...}
}
```

## 💼 Wallet Management

Comprehensive wallet features for managing your digital assets:

- **Balance Tracking**: View ETH and PYUSD token balances with real-time updates
- **Network Switching**: Seamlessly toggle between Ethereum Mainnet and Sepolia Testnet
- **QR Generation**: Create QR codes for receiving funds
- **Transaction History**: Complete record of all wallet activities
- **Address Management**: Copy addresses and view QR codes for easy sharing

## 💸 Transaction Features

Powerful transaction capabilities:

- **Token Transfers**: Send ETH and PYUSD tokens with ease
- **Gas Optimization**: Dynamic fee estimation with multiple options (Eco, Standard, Fast)
- **QR Scanning**: Scan recipient addresses for error-free transactions
- **Status Monitoring**: Real-time transaction status updates and notifications
- **Confirmation Management**: Clear confirmation steps with security verification

## 🔍 Blockchain Tracing & MEV Analysis

Advanced blockchain analysis tools powered by GCP RPC methods:

### Transaction Tracing
- Detailed execution flow visualization for all transactions
- Internal calls and state changes tracking
- Contract interactions monitoring
- Error detection and resolution suggestions

### GCP RPC Integration
```dart
// Core GCP RPC implementation
class GcpRpcService {
  // Transaction tracing
  Future<Map<String, dynamic>> traceTransaction(String txHash) async {...}
  
  // Block-level analysis
  Future<List<Map<String, dynamic>>> traceBlock(String blockNumber) async {...}
  
  // State inspection capabilities
  Future<String> getStorageAt(String address, String position) async {...}
}
```

### MEV Protection & Analysis
- Sandwich attack detection and prevention
- Frontrunning analysis with risk assessment
- Transaction ordering optimization
- MEV activity monitoring with alerts

## 📊 Analytics & Insights

Comprehensive analytics tools for market and network intelligence:

- **Transaction Analysis**: Detailed breakdown of transaction patterns and trends
- **Gas Usage Statistics**: Track and optimize your gas consumption over time
- **Market Price Tracking**: Real-time PYUSD and ETH price monitoring
- **Network Monitoring**: Track congestion and optimize transaction timing
- **Visualization Tools**: Interactive charts and graphs for data analysis

## 📱 PYUSD City Visualization

Unique blockchain visualization experience:

- **Interactive City Layout**: Visualize blockchain as a living city with blocks as buildings
- **Transaction Vehicles**: Watch transactions move through the network in real-time
- **Network Weather Effects**: Visual indicators of network congestion and activity
- **Interactive Elements**: Click on buildings and vehicles to view detailed information

## ⚙️ Settings & Configuration

Extensive customization options:

- **Account Management**: View and manage wallet credentials
- **Appearance Settings**: Toggle between dark/light modes and customize themes
- **Security Preferences**: Configure PIN, biometric, and session settings
- **Notification Controls**: Customize transaction and price alerts
- **Network Configuration**: Advanced RPC endpoint management

### Configuration

1. Create a `.env` file in the project root by copying `.env.example`:
```bash
cp .env.example .env
```

2. Fill in your environment variables in the `.env` file with your actual values:
- GCP RPC endpoints for Mainnet and Sepolia
- PYUSD contract address
- API keys (Etherscan, Gemini)
- GCP configuration details
- Network chain ID

The `.env` file contains sensitive information and is git-ignored. Never commit your actual `.env` file to version control.

## 📰 News & Updates

Stay informed with integrated news features:

- **Crypto News Feed**: Latest updates on PYUSD and the crypto market
- **Category Filtering**: Focus on news that matters to you
- **Source Verification**: News from trusted and verified sources
- **Real-time Updates**: Constant flow of relevant information

## 🔔 Notification System

Comprehensive alert system:

- **Transaction Alerts**: Updates on pending and completed transactions
- **Gas Price Notifications**: Alerts when gas prices drop below threshold
- **Security Alerts**: Notifications about unusual account activity
- **Market Updates**: Price movement alerts for your tracked assets

## 🏗 Architecture

Our application uses modern Flutter architecture:

- **Provider Pattern**: Clean state management throughout the application
- **Repository Pattern**: Separation of data sources and business logic
- **Service Layer**: Dedicated services for network, authentication, and blockchain operations
- **Responsive UI**: Adaptive layouts that work across multiple device sizes

## 🚀 Getting Started

### Prerequisites
- Flutter SDK
- Ethereum node access (Infura, Alchemy, or custom GCP setup)
- Environment configuration

### Environment Setup
1. Create a `.env` file in the project root:
```env
MAINNET_HTTP_RPC_URL=your_mainnet_url
SEPOLIA_HTTP_RPC_URL=your_testnet_url
GCP_TRACE_API_URL=your_gcp_trace_endpoint
```

### Installation
1. Clone the repository
```bash
git clone https://github.com/yourusername/pyusd-wallet.git
```

2. Install dependencies
```bash
flutter pub get
```

3. Run the application
```bash
flutter run
```

## 🧪 Testing

Comprehensive test suite for reliability:
- Unit tests for core functionality
- Integration tests for wallet operations
- Widget tests for UI components
- Mock services for testing isolated components

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

Contributions are welcome! Please check out our contribution guidelines.

## 📞 Support

For support, please open an issue in the repository or contact the development team.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Ethereum community for blockchain infrastructure
- Web3Dart package contributors
- All contributors to this project