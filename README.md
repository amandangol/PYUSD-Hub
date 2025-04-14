# PYUSD Hub 

<div align="center">
  <img src="assets/images/pyusdlogo.png" alt="PYUSD Hub Logo" width="200" height="200">
  
  <h3>Non-Custodial PYUSD & ETH Wallet with Advanced Blockchain Analytics</h3>

  [![Flutter](https://img.shields.io/badge/Flutter-3.4.0+-02569B?logo=flutter)](https://flutter.dev/)
  [![Ethereum](https://img.shields.io/badge/Ethereum-Powered-3C3C3D?logo=ethereum)](https://ethereum.org/)
  [![GCP](https://img.shields.io/badge/GCP-Blockchain-4285F4?logo=google-cloud)](https://cloud.google.com/)
  [![Gemini](https://img.shields.io/badge/AI-Gemini-8E75B2?logo=google)](https://cloud.google.com/vertex-ai)
</div>

## 📲 Try It Now!

<div align="center">
  <h3>Download PYUSD Hub</h3>
  
  [![Download APK](https://img.shields.io/badge/Download-APK-green?style=for-the-badge&logo=android)](https://drive.google.com/drive/u/1/folders/1BG7YnRTCbg41MjIbq4gOsnfVAuP1WTyn)
  [![GitHub Release](https://img.shields.io/badge/GitHub-Release-blue?style=for-the-badge&logo=github)](https://github.com/amandangol/PYUSD-Hub/releases/latest)

  For the best experience, install the APK on your Android device and explore all features in real-time!
  
  > 🌟 Experience real-time blockchain analytics, secure wallet, and AI-powered insights on your mobile device.
</div>

## 📑 Table of Contents
- [Overview](#-overview)
- [Getting Started](#-getting-started)
- [Core Features & GCP Integration](#-core-features--gcp-integration)
- [Technical Architecture](#-technical-architecture)
- [Advanced Features](#-advanced-features)
- [User Interface](#-user-interface)
- [Testing & Development](#-testing--development)
- [Support & Legal](#-support--legal)

## 🎯 Overview

PYUSD Hub revolutionizes PYUSD token management by combining enterprise-grade security with advanced blockchain analytics powered by Google Cloud Platform's RPC services. Our application stands out through:

### Key Innovations
- 💼 Secure multi-factor authenticated wallet management
- 📊 Real-time network analytics and gas optimization
- 🌆 Interactive 3D blockchain visualization ("PYUSD City")
- 🔒 Advanced MEV protection using GCP's `debug_traceTransaction`
- 🤖 AI-powered transaction analysis with Google Gemini


### Quick Start
Want to try PYUSD Hub right away? Download the APK and start exploring:
1. Download from [Google Drive](https://drive.google.com/drive/u/1/folders/1BG7YnRTCbg41MjIbq4gOsnfVAuP1WTyn) or [GitHub Releases](https://github.com/amandangol/PYUSD-Hub/releases/latest)
2. Install on your Android device
3. Choose Demo Mode to explore without a wallet, or create a new wallet for the full experience
4. Experience real-time blockchain analytics and AI-powered insights

> Note: For security reasons, always download from our official links above.

## 🚀 Getting Started

### Prerequisites
```bash
Flutter SDK ≥3.4.0
Dart ≥3.0.0
Android Studio / VS Code
Git
```

### Obtaining API Keys & RPC URLs

1. **GCP Blockchain RPC Setup**
   - Visit [Google Cloud Blockchain RPC Console](https://console.cloud.google.com/blockchain/rpc)
   - Follow the [Quickstart Guide](https://cloud.google.com/blockchain-rpc/docs/quickstart)
   - Copy both HTTP and WebSocket endpoints for Mainnet and Sepolia

2. **Gemini API Key**
   - Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
   - Create a new API key
   - Copy the key for Gemini AI integration

3. **Etherscan API Key**
   - Go to [Etherscan](https://etherscan.io/apis)
   - Create an account and generate an API key
   - Copy the key for transaction verification

### Environment Configuration

1. **Get Environment Template**
```bash
# Copy the example environment file
cp .env.example .env
```

2. **Configure Environment Variables**
```env
# GCP RPC Endpoints (from Google Cloud Console)
MAINNET_HTTP_RPC_URL=https://your-mainnet-http-endpoint
MAINNET_WSS_RPC_URL=wss://your-mainnet-websocket-endpoint
SEPOLIA_HTTP_RPC_URL=https://your-sepolia-http-endpoint
SEPOLIA_WSS_RPC_URL=wss://your-sepolia-websocket-endpoint

# Contract Configuration
PYUSD_CONTRACT_ADDRESS=0x6c3ea9036406c555b959dc03447c4f087d6d91fa

# API Keys
GEMINI_API_KEY=your_gemini_key_from_ai_studio
ETHERSCAN_API_KEY=your_etherscan_api_key
```

> Note: Never commit your `.env` file to version control. The `.env.example` file is provided as a template.

### Installation Steps

1. **Clone Repository**
```bash
git clone https://github.com/amandangol/PYUSD-Hub.git
cd PYUSD-Hub
```

2. **Install Dependencies**
```bash
flutter pub get
```

3. **Configure Environment**
Create a `.env` file:
```env
# GCP RPC Endpoints
MAINNET_HTTP_RPC_URL=your_mainnet_http_rpc_url
MAINNET_WSS_RPC_URL=your_mainnet_wss_rpc_url
SEPOLIA_HTTP_RPC_URL=your_sepolia_http_rpc_url
SEPOLIA_WSS_RPC_URL=your_sepolia_wss_rpc_url

# Contract Configuration
PYUSD_CONTRACT_ADDRESS=your_pyusd_contract_address

# API Keys
GEMINI_API_KEY=your_gemini_key
ETHERSCAN_API_KEY=your_etherscan_key
```

4. **Run Application**
```bash
flutter run
```

## 🌟 Core Features & GCP Integration

### Complete List of GCP RPC Methods Used

1. **Account & Balance Methods**
   - `eth_getBalance` - Get ETH balance
   - `eth_getTransactionCount` - Get account nonce
   - `eth_call` - Call smart contracts (PYUSD balance)
   - `eth_estimateGas` - Estimate transaction gas
   - `eth_gasPrice` - Get current gas price
   - `eth_maxPriorityFeePerGas` - Get max priority fee
   - `eth_feeHistory` - Get historical fee data

2. **Transaction Management**
   - `eth_sendRawTransaction` - Send transactions
   - `eth_getTransactionByHash` - Get transaction details
   - `eth_getTransactionReceipt` - Get transaction receipts
   - `eth_getBlockByHash` - Get block details by hash
   - `eth_getBlockByNumber` - Get block details by number

3. **Network State**
   - `eth_blockNumber` - Get latest block number
   - `eth_syncing` - Check sync status
   - `eth_chainId` - Get network chain ID
   - `net_version` - Get network version
   - `net_peerCount` - Get connected peers

4. **Tracing & Debug**
   - `debug_traceTransaction` - Detailed transaction trace
   - `debug_traceBlockByNumber` - Trace entire block
   - `debug_traceBlockByHash` - Trace block by hash
   - `debug_traceCall` - Simulate transaction trace
   - `trace_block` - Get block traces
   - `trace_transaction` - Get transaction traces
   - `trace_call` - Trace contract calls
   - `trace_rawTransaction` - Trace raw transactions

5. **WebSocket Subscriptions**
   - `eth_subscribe` - Subscribe to events
     - `newHeads` - New block headers
     - `newPendingTransactions` - Pending transactions
     - `logs` - Contract event logs
   - `eth_unsubscribe` - Unsubscribe from events

6. **State & Storage**
   - `eth_getCode` - Get contract code
   - `eth_getStorageAt` - Get contract storage
   - `eth_getLogs` - Get contract event logs

### 1. 💼 Secure Wallet Management
Our non-custodial wallet leverages GCP RPC methods for secure asset management:

<div style="display: flex; justify-content: space-around; margin: 20px 0;">
<img src="https://github.com/user-attachments/assets/5a63ea88-dd9b-43b2-8ec2-81d366a5bd0e" alt="wallet screen" height="400"/>
<img src="https://github.com/user-attachments/assets/d7a6611b-e6a7-4fe0-bd17-9f840058774e" alt="wallet screen" height="400"/>
</div>

#### Key Features:
- Real-time ETH & PYUSD balance tracking
- QR code generation for receiving funds
- Comprehensive transaction history
- Network switching (Mainnet/Sepolia)
- Gas optimization using GCP data

#### Transaction Management:
<div style="display: flex; justify-content: space-around; margin: 20px 0;">
  <img src="https://github.com/user-attachments/assets/4c2e462e-4942-4da1-a425-64f09479c5f2" alt="send screen" height="400"/>
  <img src="https://github.com/user-attachments/assets/76fc7525-53af-4bcc-a252-5b6897f8c8f3" alt="receive screen" height="400"/>
  <img src="https://github.com/user-attachments/assets/57e89d37-61e3-4671-9306-b84133b9554e" alt="transaction details" height="400"/>
  <img src="https://github.com/user-attachments/assets/86a9667d-3304-4426-9b6b-97a37546c681" alt="transaction_details2" height="400">
  <img src="https://github.com/user-attachments/assets/5e4b8b28-6422-4f7c-b60b-73c955464385" alt="transaction_details3" height="400">
</div>

### 2. 🔐 Authentication & Security
Multi-layer security implementation with:

<div style="display: flex; justify-content: space-around; margin: 20px 0;">
  <img src="https://github.com/user-attachments/assets/aca4bba5-59d4-44c9-9c9b-901e43d97005" alt="onboarding" height="400"/>
  <img src="https://github.com/user-attachments/assets/0b6f7b06-dabe-4520-82ae-d868bb85544e" alt="login" height="400"/>
  <img src="https://github.com/user-attachments/assets/0f28bde0-a42d-42c5-81b7-06a57587dabd" alt="mnemonic" height="400"/>
  <img src="https://github.com/user-attachments/assets/f2ab9f82-5728-4dac-9315-aa9618d52b22" alt="importscreen" height="400">
</div>

- Biometric authentication
- Custom PIN encryption
- 12-word recovery phrase
- Secure key storage  
- Session management
- Import/Export functionality

### 3. 🔍 Network Analysis & Monitoring

<div style="display: flex; justify-content: space-around; margin: 20px 0;">
  <img src="https://github.com/user-attachments/assets/b47c4fab-cf71-4605-8e0f-311f6e30a7ba" alt="network congestion" height="400"/>
  <img src="https://github.com/user-attachments/assets/099ba23d-d0f3-48d1-bc83-942cd72097c5" alt="gas tab" height="400"/>
  <img src="https://github.com/user-attachments/assets/67acbbe8-61a5-4e15-abce-3be413eb1b83" alt="blocks tab" height="400"/>
  <img src="https://github.com/user-attachments/assets/4a2aa08e-42ab-4668-9203-9a6ee848fdf9" alt="transactions_tab" height="400">
</div>

#### Real-time Monitoring:
- Gas price tracking
- Block production analysis
- Network congestion metrics
- Transaction pool insights
- MEV activity detection

### 4. 🔬 Transaction Tracing & MEV Protection

<div style="display: flex; justify-content: space-around; margin: 20px 0;">
  <img src="https://github.com/user-attachments/assets/3c8ef654-0754-4113-90c6-0b0530c42f66" alt="trace homescreen" height="400"/>
  <img src="https://github.com/user-attachments/assets/42aaacc6-b962-4879-aadd-8f0861c8b5ed" alt="mevanalysis homescreen" height="400"/>
  <img src="https://github.com/user-attachments/assets/1737c1f4-7560-4c1d-91a0-bcde5104387b" alt="transaction trace" height="400"/>
  <img src="https://github.com/user-attachments/assets/c20eff8c-ef73-47ab-9beb-21dd0ba3fabc" alt="advanced_trace1" height="400">
</div>

#### Advanced Analysis Features:
- Detailed transaction tracing
- Sandwich attack detection
- Frontrunning prevention
- Block replay analysis
- Smart contract interaction tracking

### 5. 🌆 PYUSD City Visualization

<div style="display: flex; justify-content: space-around; margin: 20px 0;">
  <img src="https://github.com/user-attachments/assets/41b2c8ad-44b9-49ca-9012-e1e2d588a671" alt="pyusd city" height="400"/>
  <img src="https://github.com/user-attachments/assets/aba6ea2e-0ec2-41e9-bd64-f692f9114041" alt="pyusd city2" height="400"/>
  <img src="https://github.com/user-attachments/assets/cb6d8218-87f2-43e0-8749-3f6b3282af51" alt="pyusd city3" height="400"/>
</div>

- Interactive 3D blockchain visualization
- Real-time transaction flows
- Network congestion weather effects
- Block building visualization
- Transaction vehicle animations

### 6. 🤖 AI-Powered Analysis

<div style="display: flex; justify-content: space-around; margin: 20px 0;">
  <img src="https://github.com/user-attachments/assets/072c3175-689f-4309-8c39-e0fa61b655b8" alt="ai analysis" height="400"/>
  <img src="https://github.com/user-attachments/assets/f5a30b9a-7384-4dda-b1e6-adb36c33703f" alt="transaction trace3" height="400"/>
</div>

- Transaction pattern recognition
- Risk assessment
- Gas optimization recommendations
- Smart contract interaction analysis
- Natural language explanations

## 📱 Additional Features

### 1. 🎮 Demo Mode
- Simulated wallet with test transactions
- Pre-populated transaction history
- Real-time network data access
- Full MEV protection testing
- AI analysis demonstration
- PYUSD City exploration
- Network switching capability
- All features accessible without real funds

### 2. ⚙️ Advanced Settings & Management
- Custom RPC endpoint configuration
- Network management (Mainnet/Testnet)
- Security settings (Biometric, PIN, Session)
- Notification preferences
- UI customization (Dark/Light theme)
- Connection quality monitoring
- Fallback providers configuration

### 3. 📊 Analytics & Insights

<div style="display: flex; justify-content: space-around; margin: 20px 0;">
  <img src="https://github.com/user-attachments/assets/8baae0d0-d88a-4e67-ac34-8a038040e24c" alt="insightsscreen" height="400"/>
  <img src="https://github.com/user-attachments/assets/4080629a-0203-4470-9f8e-ad53d18510b5" alt="insights screen2" height="400"/>
</div>

- Market trend analysis
- Historical data visualization
- Price impact predictions
- Network health monitoring

### 4. 🔔 Notification System
- Gas price alerts
- Transaction confirmations
- Network congestion warnings
- Custom alert thresholds

### 5. 📰 News & Information
- PYUSD ecosystem updates
- Market news integration
- Protocol announcements
- Educational content

### High-Performance Components

1. **Processing Engine**
   - Parallel transaction trace processing
   - Real-time block analysis
   - MEV pattern detection
   - State reconstruction
   - Blockchain data stream processing
   - Pattern recognition
   - Predictive modeling
   > Note: Some advanced analytics features requiring BigQuery are not implemented due to billing constraints. The application focuses on real-time data analysis using GCP's Blockchain RPC services.

2. **Visualization Engine**
   - 3D blockchain state rendering
   - Real-time transaction flows
   - Interactive exploration
   - Weather effects system
     - Clear Sky: Low congestion (<30%)
     - Cloudy: Moderate congestion (30-60%)
     - Foggy: High congestion (60-80%)
     - Rain: Severe congestion (>80%)

3. **System Optimizations**
   - Caching System
     - Transaction and balance caching
     - Network data and RPC response caching
     - Image caching
   - Background Processing
     - Parallel RPC requests
     - Transaction queue management
     - WebSocket connection handling
   - Resource Management
     - Memory and battery optimization
     - Network bandwidth management
     - Storage optimization

### Google Gemini AI Integration
- Transaction pattern recognition
- Risk assessment
- Gas optimization recommendations
- Smart contract interaction analysis


### Note on BigQuery Features
> 🔔 Due to billing constraints, BigQuery integration features are currently not implemented. These features would have included:
> - Historical transaction analysis
> - Advanced MEV pattern detection
> - Cross-chain analytics
> - Custom SQL queries for blockchain data
> 
> The application currently uses GCP's Blockchain RPC services for real-time data analysis.

## 🔧 Troubleshooting

### Common Issues
1. **WebSocket Connection Failed**
   - Check GCP credentials
   - Verify network connectivity
   - Ensure correct WSS endpoint

2. **RPC Errors**
   - Verify API keys
   - Check rate limits
   - Confirm endpoint availability

## 📄 License
MIT License - see [LICENSE](LICENSE) for details

## 📚 Learn More

### Google Cloud Web3 Resources
- [GCP Blockchain RPC Overview](https://cloud.google.com/blockchain-rpc/docs)
- [Quickstart Guide](https://cloud.google.com/blockchain-rpc/docs/quickstart)
- [Ethereum API Methods](https://cloud.google.com/blockchain-rpc/docs/rpc-api)
- [Crypto Public Datasets on BigQuery](https://cloud.google.com/application/web3/discover) *(Note: BigQuery features not implemented due to billing constraints)*
  - [BigQuery Crypto Public Datasets HOWTO](https://cloud.google.com/application/web3/discover/products/public-blockchain-datasets-available-in-bigquery)
  - [BigQuery Ethereum Dataset](https://console.cloud.google.com/marketplace/product/bigquery-public-data/blockchain-analytics-ethereum-mainnet-us)
  - [Ethereum Real-time Events (Experimental)](https://cloud.google.com/application/web3/discover/products/realtime-evm-blockchain-events-with-pubsub?e=48754805)
- [Google Faucet (Sepolia & Holesky)](https://cloud.google.com/application/web3/faucet)
- [Google AI Studio](https://aistudio.google.com/prompts/new_chat)

### PYUSD Documentation
- [About PYUSD](https://developer.paypal.com/community/blog/pyusd-stablecoin/)
- [PYUSD Contract on Paxos](https://github.com/paxosglobal/pyusd-contract)
- [PYUSD Contract ABI on Ethereum](https://etherscan.io/token/0x6c3ea9036406852006290770bedfcaba0e23a0e8)
- [PYUSD Contract ABI on Sourcify](https://sourcify.dev/#/lookup/0x6c3ea9036406852006290770BEdFcAbA0e23A0e8)
- [PYUSD Faucet on Paxos](https://faucet.paxos.com/)

### Ethereum Development
- [JSON-RPC API Documentation](https://ethereum.org/en/developers/docs/apis/json-rpc/)
- [Reading Blockchain Data](https://docs.alchemy.com/docs/how-to-read-data-with-json-rpc)

## 🙏 Credits & Acknowledgments

This project is built upon the incredible work of several organizations and their technologies:

### PayPal USD (PYUSD)
PYUSD is a trademark of PayPal, Inc. This project utilizes the PYUSD smart contract and infrastructure provided by PayPal and Paxos. For more information about PYUSD, visit [pyusd.com](https://developer.paypal.com/community/blog/pyusd-stablecoin/).

### Google Cloud Platform
This project leverages Google Cloud's Blockchain Node Engine and various Web3 services. Special thanks to the GCP team for providing robust blockchain infrastructure and documentation.

### Ethereum Foundation
Built on Ethereum's technology and standards. Thanks to the Ethereum Foundation and community for maintaining the backbone of decentralized finance.

### Open Source Community
This project uses various open-source libraries and tools. We're grateful to all the developers who maintain these resources.

## 📝 Legal Notice

- PYUSD™ is a trademark of PayPal, Inc.
- Google Cloud™ and related marks are trademarks of Google LLC
- Ethereum™ is a trademark of Ethereum Foundation

This project is not officially associated with PayPal, Google, or the Ethereum Foundation. It is an independent implementation utilizing their public APIs and services.
