# PYUSD Hub - Ethereum Wallet & Analytics Platform

PYUSD Hub is a comprehensive mobile wallet application for managing PYUSD (PayPal USD) and ETH on the Ethereum network. It combines secure wallet functionality with advanced analytics and network monitoring tools.

![PYUSD Hub Logo](assets/images/pyusdlogo.png)

## Features

### 🔐 Secure Wallet Management
- **Non-custodial Wallet**: Full control over your private keys
- **Biometric Security**: Fingerprint/Face ID authentication
- **PIN Protection**: Additional security layer for transactions
- **Recovery Phrase Backup**: Standard 12/24-word seed phrase support
- **Multiple Authentication Methods**: PIN, biometrics, and password options

### 💱 Transaction Features
- **Send & Receive**: Easy PYUSD and ETH transfers
- **Transaction History**: Detailed record of all transactions
- **Gas Fee Optimization**: Smart gas price suggestions
- **QR Code Support**: Quick address sharing and scanning
- **Address Book**: Save and manage frequent contacts

### 📊 Market Insights & Analytics
- **Price Tracking**: Real-time PYUSD and ETH price data
- **Exchange Analytics**: Track PYUSD trading across exchanges
- **Market News**: Latest updates from the crypto space
- **Portfolio Analysis**: Track your holdings and performance
- **Price Alerts**: Customizable price notification system

### 🌐 Network Tools
- **Network Congestion Monitor**: Real-time gas prices and network status
- **Transaction Tracing**: Detailed analysis of transaction execution
- **PYUSD City View**: 3D visualization of network activity
- **Block Explorer**: Browse and analyze blockchain data
- **Gas Price Predictions**: Optimize transaction timing

### 🔍 Advanced Features
- **Demo Mode**: Explore features without creating a wallet
- **Dark/Light Theme**: Customizable UI appearance
- **Multi-language Support**: International accessibility
- **Offline Support**: Basic functionality without internet
- **Transaction Notifications**: Real-time updates

## Getting Started

### Prerequisites
- Flutter SDK (2.5.0 or higher)
- Dart (2.14.0 or higher)
- Android Studio / Xcode
- Git

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/pyusd-hub.git
cd pyusd-hub
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

### Configuration

1. Create a `.env` file in the project root:
```env
ETHERSCAN_API_KEY=your_api_key
INFURA_PROJECT_ID=your_project_id
```

2. Update the configuration in `lib/config/app_config.dart`:
```dart
class AppConfig {
  static const String apiUrl = 'your_api_url';
  // ... other configurations
}
```

## Architecture

PYUSD Hub follows a clean architecture pattern with Provider state management:

```

### Key Components
- **Authentication**: Secure wallet creation and import
- **Transaction Management**: Handle crypto transfers
- **Network Monitoring**: Track blockchain status
- **Market Data**: Real-time price and exchange info
- **Analytics**: Transaction and portfolio analysis

## Security Features

- **Secure Storage**: Encrypted storage for sensitive data
- **Biometric Authentication**: Native device security
- **PIN Protection**: Custom PIN implementation
- **Session Management**: Automatic logout
- **Secure Communication**: SSL/TLS encryption

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## Testing

Run the test suite:
```bash
flutter test
```

### Test Coverage
- Unit Tests: Core functionality
- Widget Tests: UI components
- Integration Tests: End-to-end flows

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Flutter Team
- Ethereum Community
- PayPal/PYUSD Team
- Open-source contributors

## Support

For support, please:
- Open an issue
- Join our Discord community
- Email: support@pyusdhub.com

## Roadmap

- [ ] Multi-wallet support
- [ ] DeFi integration
- [ ] Cross-chain compatibility
- [ ] Advanced analytics features
- [ ] Social features

## Screenshots

[Include screenshots of key features here]

## Performance

- Launch time: < 2 seconds
- Transaction processing: < 5 seconds
- Memory usage: < 100MB
- Battery impact: Minimal

## Requirements

- iOS 13.0 or later
- Android 6.0 or later
- Internet connection
- Camera (optional, for QR scanning)