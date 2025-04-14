# PYUSD Hub

<img src="assets/images/pyusdlogo.png" alt="PYUSD Hub Logo" width="200" height="200">

PYUSD Hub is a comprehensive mobile wallet application for managing PYUSD (PayPal USD) and ETH on the Ethereum network. It combines secure wallet functionality with advanced analytics and network monitoring tools.

Built with Flutter, PYUSD Hub offers a seamless experience for both casual users and crypto enthusiasts, providing intuitive access to the growing PYUSD ecosystem while enabling detailed blockchain insights.

## 📑 Table of Contents
- [Getting Started](#-getting-started)
- [Core Features](#-core-features)
- [Technical Architecture](#-technical-architecture)
- [Advanced Features](#-advanced-features)
- [User Interface](#-user-interface)
- [Testing & Development](#-testing--development)
- [Support & Legal](#-support--legal)

## 🚀 Getting Started

### Prerequisites
- Flutter SDK
- Ethereum node access (Infura, Alchemy, or custom GCP setup)
- Environment configuration

### Installation
1. Clone the repository
```bash
git clone https://github.com/yourusername/pyusd-wallet.git
```

2. Install dependencies
```bash
flutter pub get
```

3. Configure Environment
Create a `.env` file in the project root:
```env
# GCP RPC Endpoints
MAINNET_HTTP_RPC_URL=your_mainnet_http_rpc_url
MAINNET_WSS_RPC_URL=your_mainnet_wss_rpc_url
SEPOLIA_HTTP_RPC_URL=your_sepolia_http_rpc_url
SEPOLIA_WSS_RPC_URL=your_sepolia_wss_rpc_url
PYUSD_CONTRACT_ADDRESS=your_pyusd_contract_address
ETHERSCAN_API_KEY=your_etherscan_api_key
GEMINI_API_KEY=your_gemini_api_key
GCP_SERVICE_ACCOUNT_FILE=path/to/service-account.json
GCP_PROJECT_ID=your_gcp_project_id
NETWORK_CHAIN_ID=your_network_chain_id
```

4. Run the application
```bash
flutter run
```

## 🌟 Core Features

### 🔐 Authentication & Security
- **Secure Wallet Creation**: PIN and biometric authentication
- **Mnemonic Backup**: 12-word recovery phrase generation and storage
- **Import Functionality**: Recovery phrase wallet import
- **Multi-factor Authentication**: Additional security layers
- **Session Management**: Automatic timeout and secure persistence
  
<img src="https://github.com/user-attachments/assets/aca4bba5-59d4-44c9-9c9b-901e43d97005" alt="onboarding" height="400">
<img src="https://github.com/user-attachments/assets/14630495-b293-4d68-aeaa-3fd17e0a6dbd" alt="walletselection" height="400">
<img src="https://github.com/user-attachments/assets/0b6f7b06-dabe-4520-82ae-d868bb85544e" alt="login" height="400">
<img src="https://github.com/user-attachments/assets/0f28bde0-a42d-42c5-81b7-06a57587dabd" alt="mnemonic" height="400">
<img src="https://github.com/user-attachments/assets/f2ab9f82-5728-4dac-9315-aa9618d52b22" alt="importscreen" height="400">


### 💼 Wallet Management
- **Balance Tracking**: Real-time ETH and PYUSD balances
- **Network Switching**: Mainnet and Sepolia support
- **QR Generation**: Receive funds via QR codes
- **Transaction History**: Complete activity log
- **Address Management**: Easy address sharing

### 💸 Transaction Features
- **Token Transfers**: ETH and PYUSD transfers
- **Gas Optimization**: Dynamic fee estimation (Eco, Standard, Fast)
- **QR Scanning**: Scan recipient addresses
- **Status Monitoring**: Real-time updates
- **Confirmation Management**: Security verification steps

<img src="https://github.com/user-attachments/assets/5a63ea88-dd9b-43b2-8ec2-81d366a5bd0e" alt="walletscreen" height="400">
<img src="https://github.com/user-attachments/assets/4c2e462e-4942-4da1-a425-64f09479c5f2" alt="send_screen" height="400">
<img src="https://github.com/user-attachments/assets/76fc7525-53af-4bcc-a252-5b6897f8c8f3" alt="receive_screen" height="400">
<img src="https://github.com/user-attachments/assets/57e89d37-61e3-4671-9306-b84133b9554e" alt="transaction_details" height="400">
<img src="https://github.com/user-attachments/assets/86a9667d-3304-4426-9b6b-97a37546c681" alt="transaction_details2" height="400">
<img src="https://github.com/user-attachments/assets/5e4b8b28-6422-4f7c-b60b-73c955464385" alt="transaction_details3" height="400">

## 🏗 Technical Architecture

### GCP RPC Integration
Our application leverages Google Cloud Platform's RPC endpoints for:
- Transaction Management
- Network Analysis
- Transaction Tracing
- Wallet Management
- Market Insights
- Authentication & Security

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
Our application leverages Google's Gemini AI for advanced blockchain analysis:

1. **Real-time Analysis Pipeline**
   - Transaction trace interpretation
   - Smart contract interaction analysis
   - Risk assessment and security scanning
   - Natural language processing of blockchain data

2. **AI-Enhanced Features**
   - Intelligent pattern recognition
   - Predictive analytics
   - User behavior analysis
   - Security threat detection

3. **Integration Architecture**
   - Direct Gemini API integration
   - Optimized response caching
   - Parallel processing for multiple analyses
   - Efficient state management

## 🔍 Advanced Features

### Blockchain Tracing & MEV Protection
- Detailed transaction execution tracing
- Sandwich attack detection and prevention
- Frontrunning analysis and protection
- Transaction ordering optimization
- MEV activity monitoring
  
<img src="https://github.com/user-attachments/assets/3c8ef654-0754-4113-90c6-0b0530c42f66" alt="trace_homescreen" height="400">
<img src="https://github.com/user-attachments/assets/42aaacc6-b962-4879-aadd-8f0861c8b5ed" alt="mevanalysis_homescreen" height="400">
<img src="https://github.com/user-attachments/assets/1737c1f4-7560-4c1d-91a0-bcde5104387b" alt="transaction_trace" height="400">
<img src="https://github.com/user-attachments/assets/21480253-1c1f-47d4-af69-fb41d377ef12" alt="transaction_trace4" height="400">
<img src="https://github.com/user-attachments/assets/c20eff8c-ef73-47ab-9beb-21dd0ba3fabc" alt="advanced_trace1" height="400">

### Analytics & Insights
- Transaction pattern analysis
- Gas usage optimization
- Market price tracking
- Network congestion monitoring
- Interactive data visualization
  
<img src="https://github.com/user-attachments/assets/b47c4fab-cf71-4605-8e0f-311f6e30a7ba" alt="network_congestion" height="400">
<img src="https://github.com/user-attachments/assets/099ba23d-d0f3-48d1-bc83-942cd72097c5" alt="gas_tab" height="400">
<img src="https://github.com/user-attachments/assets/67acbbe8-61a5-4e15-abce-3be413eb1b83" alt="blocks_tab" height="400">
<img src="https://github.com/user-attachments/assets/4a2aa08e-42ab-4668-9203-9a6ee848fdf9" alt="transactions_tab" height="400">
<img src="https://github.com/user-attachments/assets/8baae0d0-d88a-4e67-ac34-8a038040e24c" alt="insightsscreen" height="400">
<img src="https://github.com/user-attachments/assets/4080629a-0203-4470-9f8e-ad53d18510b5" alt="insights_screen2" height="400">

### PYUSD City Visualization
- Interactive 3D blockchain city
- Real-time transaction vehicles
- Network weather effects
- Interactive building elements
- Congestion visualization
  
<img src="https://github.com/user-attachments/assets/41b2c8ad-44b9-49ca-9012-e1e2d588a671" alt="pyusd_city" height="400">
<img src="https://github.com/user-attachments/assets/aba6ea2e-0ec2-41e9-bd64-f692f9114041" alt="pyusd_city2" height="400">
<img src="https://github.com/user-attachments/assets/cb6d8218-87f2-43e0-8749-3f6b3282af51" alt="pyusd_city3" height="400">
<img src="https://github.com/user-attachments/assets/c35f5bd6-8c10-441f-a299-aefc4b981618" alt="pyusd_city4" height="400">

### 🤖 AI-Powered Analysis with Google Gemini
- **Smart Transaction Analysis**: Real-time transaction pattern recognition and risk assessment using Google's Gemini AI
- **Intelligent Trace Interpretation**: 
  - Natural language explanations of complex transaction traces
  - Smart contract interaction analysis
  - Gas usage optimization recommendations
  - Risk level assessment and security insights
- **MEV Protection Insights**:
  - AI-driven frontrunning detection
  - Sandwich attack pattern recognition
  - Predictive MEV exposure analysis
- **Market Intelligence**:
  - Smart market trend analysis
  - Price impact predictions
  - Trading pattern recognition
- **User-Friendly Explanations**:
  - Technical details translated into plain English
  - Visual representation of complex blockchain operations
  - Actionable recommendations for users

<img src="https://github.com/user-attachments/assets/072c3175-689f-4309-8c39-e0fa61b655b8" alt="ai_analysis" height="400">
<img src="https://github.com/user-attachments/assets/f5a30b9a-7384-4dda-b1e6-adb36c33703f" alt="transaction_trace3" height="400">

## 📱 User Interface

### Dashboard & Navigation
- Intuitive mobile interface
- Dark/light mode support
- Quick action shortcuts
- Responsive layouts

### Settings & Configuration
- Account management
- Security preferences
- Notification controls
- Network configuration
- Appearance customization
  
<img src="https://github.com/user-attachments/assets/d7a6611b-e6a7-4fe0-bd17-9f840058774e" alt="walletscreen" height="400">

### Notification System
- Transaction alerts
- Gas price notifications
- Security alerts
- Market updates
- Custom alert thresholds

## 🧪 Testing & Development

### Testing Suite
- Unit tests
- Integration tests
- Widget tests
- Mock services

### Developer Integration
- Clean API access
- Documentation
- Example implementations
- Integration guides

## 📞 Support & Legal

### License
This project is licensed under the MIT License - see the LICENSE file for details.

### Contributing
Contributions are welcome! Please check out our contribution guidelines.

### Support
For support, please open an issue in the repository or contact the development team.

### Acknowledgments
- Flutter team
- Ethereum community
- Web3Dart package contributors
- Project contributors
