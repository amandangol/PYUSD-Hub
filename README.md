# PYUSD Hub - Non-Custodial Mobile Wallet & Analytics Platform

<div align="center">
  <img src="assets/images/pyusdlogo.png" alt="PYUSD Hub Logo" width="200" height="200">
  
  <h3>Non-Custodial PYUSD & ETH Wallet with Advanced Blockchain Analytics</h3>

  [![Flutter](https://img.shields.io/badge/Flutter-3.4.0+-02569B?logo=flutter)](https://flutter.dev/)
  [![Ethereum](https://img.shields.io/badge/Ethereum-Powered-3C3C3D?logo=ethereum)](https://ethereum.org/)
  [![GCP](https://img.shields.io/badge/GCP-Blockchain-4285F4?logo=google-cloud)](https://cloud.google.com/)
  [![Gemini](https://img.shields.io/badge/AI-Gemini-8E75B2?logo=google)](https://cloud.google.com/vertex-ai)
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


## 🚀 Getting Started

### Prerequisites
```bash
Flutter SDK ≥3.4.0
Dart ≥3.0.0
Android Studio / VS Code
Git
```

### Installation Steps

1. **Clone Repository**
```bash
git clone https://github.com/yourusername/PYUSD-Hub.git
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

### 1. 📊 Analytics & Insights

<div style="display: flex; justify-content: space-around; margin: 20px 0;">
  <img src="https://github.com/user-attachments/assets/8baae0d0-d88a-4e67-ac34-8a038040e24c" alt="insightsscreen" height="400"/>
  <img src="https://github.com/user-attachments/assets/4080629a-0203-4470-9f8e-ad53d18510b5" alt="insights screen2" height="400"/>
</div>

- Market trend analysis
- Historical data visualization
- Price impact predictions
- Network health monitoring

### 2. 🔔 Notification System
- Gas price alerts
- Transaction confirmations
- Network congestion warnings
- Custom alert thresholds

### 3. 📰 News & Information Center
- PYUSD ecosystem updates
- Market news integration
- Protocol announcements
- Educational content

## 🏗 Technical Architecture

### GCP RPC Integration
Our application leverages these key RPC methods:

1. **Core Methods**
   - `eth_getBalance`
   - `eth_getTransactionCount`
   - `eth_call`
   - `eth_sendRawTransaction`

2. **Advanced Methods**
   - `debug_traceTransaction`
   - `debug_traceBlockByNumber`
   - `trace_block`
   - `eth_subscribe`

and many more!!!

### High-Performance Components

1. **Trace Processing Engine**
   - Parallel transaction trace processing
   - Real-time block analysis
   - MEV pattern detection
   - State reconstruction

2. **Analytics Pipeline**
   - Blockchain data stream processing
   - Real-time market analysis
   - Pattern recognition
   - Predictive modeling

3. **Visualization Engine**
   - 3D blockchain state rendering
   - Real-time transaction flows
   - Interactive exploration
   - Optimized performance

### Google Gemini AI Integration
- Transaction pattern recognition
- Risk assessment
- Gas optimization recommendations
- Smart contract interaction analysis

## 🌆 PYUSD City Visualization

### Interactive 3D Visualization
- Real-time block visualization
- Transaction flow animation
- Network congestion effects
- Interactive building exploration

### Weather Effects System
- Clear Sky: Low congestion (<30%)
- Cloudy: Moderate congestion (30-60%)
- Foggy: High congestion (60-80%)
- Rain: Severe congestion (>80%)

## 📚 Documentation

### API Reference
- [Wallet API Documentation](docs/api/wallet.md)
- [Analytics API Documentation](docs/api/analytics.md)
- [RPC Integration Guide](docs/api/rpc.md)

### Architecture Guides
- [System Architecture](docs/architecture/system.md)
- [Security Model](docs/architecture/security.md)
- [Data Flow](docs/architecture/data-flow.md)

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
