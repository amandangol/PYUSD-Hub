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


### GCP RPC Integration

Our application leverages Google Cloud Platform's RPC endpoints for enhanced blockchain interaction and analysis. Here's how different features utilize these RPC methods:

#### Transaction Management
```dart
// TransactionProvider utilizes GCP RPC for:
- Transaction sending and monitoring
- Gas price estimation and optimization
- Transaction receipt verification
- Token transfers and balance checks

Example:
await _rpcService.sendEthTransaction(
  rpcEndpoint,
  credentials,
  toAddress,
  amount,
  gasPrice: gasPrice,
  gasLimit: gasLimit
);
```

#### Network Analysis
```dart
// NetworkCongestionProvider uses RPC for:
- Real-time gas price tracking
- Network congestion monitoring
- Block time analysis
- Pending transaction pool monitoring

Example:
final gasPrice = await _rpcService.getDetailedGasPrices(rpcEndpoint);
```

#### Transaction Tracing
```dart
// TraceProvider implements:
- Detailed transaction execution tracing
- Internal calls visualization
- State changes tracking
- MEV detection and analysis

Example:
final trace = await _rpcService.traceTransaction(txHash);
```

#### Wallet Management
```dart
// WalletScreenProvider uses RPC for:
- Real-time balance updates
- Token allowance checks
- Transaction history fetching
- Contract interaction state reads

Example:
final balance = await _rpcService.getBalance(address);
```

#### Market Insights
```dart
// InsightsProvider leverages RPC for:
- Block data analysis
- Network statistics
- Token transfer events
- Contract state monitoring

Example:
final blockData = await _rpcService.getBlockWithTransactions(blockNumber);
```

#### Authentication & Security
```dart
// AuthProvider utilizes RPC for:
- Transaction signing verification
- Nonce management
- Chain ID verification
- Network state validation

Example:
final nonce = await _rpcService.getTransactionCount(address);
```

#### Send Transaction Flow
```dart
// SendScreen implements:
- Gas estimation
- Balance verification
- Transaction broadcasting
- Receipt monitoring

Example:
final gasEstimate = await _rpcService.estimateGas({
  'from': sender,
  'to': recipient,
  'value': amount
});
```

Our GCP RPC integration provides:
- High availability and reliability
- Enhanced transaction tracing capabilities
- MEV protection features
- Real-time network monitoring
- Optimized gas fee estimation
- Secure transaction broadcasting

The service is configured through environment variables:
```env
MAINNET_HTTP_RPC_URL=your_mainnet_http_rpc_url
MAINNET_WSS_RPC_URL=your_mainnet_wss_rpc_url
SEPOLIA_HTTP_RPC_URL=your_sepolia_http_rpc_url
SEPOLIA_WSS_RPC_URL=your_sepolia_wss_rpc_url
```

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
# GCP RPC Endpoints
MAINNET_HTTP_RPC_URL=your_mainnet_http_rpc_url
MAINNET_WSS_RPC_URL=your_mainnet_wss_rpc_url
SEPOLIA_HTTP_RPC_URL=your_sepolia_http_rpc_url
SEPOLIA_WSS_RPC_URL=your_sepolia_wss_rpc_url

# Contract Addresses
PYUSD_CONTRACT_ADDRESS=your_pyusd_contract_address

# API Keys
ETHERSCAN_API_KEY=your_etherscan_api_key
GEMINI_API_KEY=your_gemini_api_key

# GCP Configuration
GCP_SERVICE_ACCOUNT_FILE=path/to/service-account.json
GCP_PROJECT_ID=your_gcp_project_id

# Network Configuration
NETWORK_CHAIN_ID=your_network_chain_id

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

## 🚀 Innovation & Technical Excellence

### Advanced Transaction Analysis Engine
Our application leverages GCP's Blockchain RPC service to perform computationally intensive operations that would be cost-prohibitive with traditional providers:

```dart
// Example of deep transaction tracing
class TransactionAnalytics {
  Future<Map<String, dynamic>> analyzeTransaction(String txHash) async {
    // Utilize GCP's debug_traceTransaction for detailed analysis
    final trace = await rpcService.debugTraceTransaction(txHash);
    // Process complex MEV patterns
    final mevAnalysis = await analyzeMEVPatterns(trace);
    return {
      'trace': trace,
      'mev': mevAnalysis,
      'gas_optimization': calculateOptimalGas(trace)
    };
  }
}
```

### Innovative Features

#### 1. Real-time MEV Protection
- **Sandwich Attack Detection**: Utilizes `trace_block` to analyze pending transactions
- **Frontrunning Prevention**: Real-time monitoring of mempool activities
- **Transaction Optimization**: Intelligent gas pricing based on MEV analysis
- **Cost Advantage**: Free access to computationally expensive trace methods through GCP

#### 2. PYUSD City Visualization
Unique 3D visualization of blockchain activity:
- Real-time block processing using `debug_traceBlock`
- Visual representation of token flows and smart contract interactions
- Interactive exploration of transaction traces
- Network congestion visualization through weather effects

#### 3. Advanced Analytics Suite
Leveraging GCP's computational power for:
- **Deep Transaction Analysis**: Full execution traces of PYUSD transactions
- **Pattern Recognition**: ML-powered analysis of trading patterns
- **Gas Optimization**: Historical analysis of gas usage patterns
- **Network Intelligence**: Real-time network state analysis

## 💪 Pushing Technical Boundaries

### Computationally Intensive Features

#### 1. Block Analysis Engine
```dart
// Utilizing GCP's trace_block for comprehensive analysis
class BlockAnalytics {
  Future<BlockInsights> analyzeBlock(String blockNumber) async {
    final blockTrace = await rpcService.traceBlock(blockNumber);
    return processTraceData(blockTrace);
  }
}
```

#### 2. State Reconstruction
- Historical state analysis using `debug_traceCall`
- Smart contract interaction simulation
- Transaction impact prediction
- Gas usage optimization recommendations

#### 3. MEV Protection System
```dart
// Real-time MEV detection and prevention
class MEVProtection {
  Future<bool> detectSandwichAttack(Transaction tx) async {
    final pendingBlock = await rpcService.traceBlock('pending');
    return analyzeMEVPatterns(pendingBlock, tx);
  }
}
```

### GCP Advantages
- **Cost Efficiency**: Free access to expensive trace methods
- **High Performance**: Parallel processing of block traces
- **Reliability**: Enterprise-grade infrastructure
- **Scalability**: Handling multiple concurrent trace requests

## 🎯 Functionality & Real-world Impact

### PYUSD Integration
- Seamless token transfers with MEV protection
- Real-time transaction monitoring
- Advanced gas fee optimization
- Cross-chain bridge monitoring

### Problem Solutions
1. **MEV Protection**: Protecting users from value extraction
2. **Gas Optimization**: Reducing transaction costs
3. **Transaction Transparency**: Clear visualization of token flows
4. **Market Intelligence**: Real-time network insights

## 🤝 Accessibility & Adoption

### User Experience
- Intuitive mobile interface
- Clear transaction visualization
- Simplified complex blockchain concepts
- Beginner-friendly features with advanced options

### Developer Integration
```dart
// Easy integration example
class PyusdHub {
  // Simple API for complex features
  Future<TransactionSafety> checkTransactionSafety(
    String to,
    double amount
  ) async {
    return await mevProtection.analyzeSafety(to, amount);
  }
}
```

### Enterprise Features
- API access for business integration
- Customizable analytics dashboard
- Batch transaction processing
- Advanced reporting capabilities

## 🔧 Technical Architecture

### High-Performance Components
1. **Trace Processing Engine**
   - Parallel processing of transaction traces
   - Real-time block analysis
   - MEV pattern detection
   - State reconstruction

2. **Analytics Pipeline**
   - Stream processing of blockchain data
   - Real-time market analysis
   - Pattern recognition
   - Predictive modeling

3. **Visualization Engine**
   - 3D rendering of blockchain state
   - Real-time transaction flows
   - Interactive exploration
   - Performance-optimized rendering

## 🌐 Real-time Network Monitoring & PYUSD City

### Network Congestion Monitoring
Our application provides comprehensive real-time monitoring of Ethereum network metrics through GCP's advanced RPC methods:

#### 1. Real-time Network Stats
```dart
class NetworkCongestionProvider {
  // Real-time websocket connection for network updates
  Future<void> initializeWebSocket() async {
    final subscription = await _rpcService.subscribeToNewBlocks();
    subscription.listen((block) {
      updateNetworkMetrics(block);
      analyzeBlockData(block);
    });
  }
}
```

#### 2. Multi-Layer Monitoring
- **Block Monitoring**: Real-time tracking of new blocks and their metrics
- **Gas Price Updates**: Live gas price tracking with predictive modeling
- **Transaction Pool**: Monitoring pending and confirmed transactions
- **Network Health**: Real-time congestion and performance metrics

### PYUSD City Visualization
Innovative 3D visualization of network activity with real-time updates:

#### 1. Dynamic City Layout
```dart
class PyusdCityScreen {
  // Real-time block visualization
  Widget _buildCityBlocks() {
    return StreamBuilder(
      stream: blockStream,
      builder: (context, block) {
        return CityBuilding(
          height: calculateBuildingHeight(block.gasUsed),
          transactions: block.transactions,
          pyusdTransactions: filterPyusdTransactions(block)
        );
      }
    );
  }
}
```

#### 2. Live Transaction Visualization
- **Transaction Vehicles**: Moving vehicles represent live transactions
- **Speed Indicators**: Vehicle speed based on gas price
- **Status Updates**: Real-time transaction confirmation status
- **Interactive Elements**: Tap for detailed transaction information

### Network Metrics Dashboard

#### 1. Overview Tab
- Network Status Overview
  - Congestion Level
  - Peer Count
  - Network Version
  - Block Time
- Queue Status
  - Pending Transactions
  - Transaction Pool Size
- Performance Metrics
  - Network Latency
  - Block Utilization

#### 2. Gas Analysis Tab
```dart
class GasTab {
  // Real-time gas price monitoring
  Widget buildGasPriceChart() {
    return StreamBuilder(
      stream: gasPriceStream,
      builder: (context, prices) {
        return GasPriceChart(
          currentPrice: prices.current,
          historicalPrices: prices.history,
          predictions: calculatePricePredictions(prices)
        );
      }
    );
  }
}
```

#### 3. Block Analysis
- Real-time block monitoring
- Gas usage patterns
- Transaction density
- PYUSD transaction concentration

#### 4. Transaction Monitoring
```dart
class TransactionsTab {
  // PYUSD transaction filtering and monitoring
  Stream<List<Transaction>> getPyusdTransactions() {
    return transactionStream.where((tx) => 
      tx.to == PYUSD_CONTRACT_ADDRESS
    ).map((tx) => enrichTransactionData(tx));
  }
}
```

### Weather Effects System
Network conditions are represented through dynamic weather effects:

- **Clear Sky**: Low network congestion (<30%)
- **Cloudy**: Moderate congestion (30-60%)
- **Foggy**: High congestion (60-80%)
- **Rain**: Severe congestion (>80%)

### Technical Implementation

#### 1. Data Collection
```dart
class NetworkCongestionProvider {
  final Map<String, Stream> _dataStreams = {
    'blocks': _subscribeToBlocks(),
    'transactions': _subscribeToTransactions(),
    'gasPrices': _subscribeToGasPrices(),
  };

  Future<void> initialize() async {
    await _initializeWebSocket();
    await _setupDataStreams();
    _startMetricsCollection();
  }
}
```

#### 2. Real-time Updates
- WebSocket connections for instant updates
- Efficient data processing pipeline
- Optimized rendering system
- Smart caching mechanism

#### 3. Performance Optimization
```dart
class NetworkMetrics {
  // Efficient metrics calculation
  void updateMetrics(Block block) {
    _calculateNetworkLoad(block);
    _updateGasMetrics(block);
    _processTransactions(block);
    _updateCongestionLevel();
  }
}
```

### Key Features
1. **Real-time Monitoring**
   - Block-by-block updates
   - Gas price fluctuations
   - Transaction pool status
   - Network congestion levels

2. **Interactive Visualization**
   - Dynamic city layout
   - Real-time transaction flow
   - Weather effects system
   - Interactive buildings and vehicles

3. **Performance Metrics**
   - Network health indicators
   - Gas price trends
   - Transaction throughput
   - Block utilization rates

4. **PYUSD-Specific Analysis**
   - PYUSD transaction tracking
   - Token transfer monitoring
   - Contract interaction analysis
   - Volume visualization

This comprehensive monitoring system provides users with an intuitive and engaging way to track network activity, particularly focusing on PYUSD transactions and overall network health.