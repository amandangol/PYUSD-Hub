// import 'package:flutter/material.dart';
// import 'package:web3auth_flutter/input.dart';
// import 'package:web3auth_flutter/output.dart';
// import 'package:web3auth_flutter/web3auth_flutter.dart';
// import 'package:web3auth_flutter/enums.dart';
// import 'package:web3dart/web3dart.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';

// import '../model/wallet.dart';

// class Web3AuthService {
//   bool _initialized = false;

//   // Initialize Web3Auth
//   Future<void> init() async {
//     if (_initialized) return;

//     try {
//       // Get keys from environment variables
//       final clientId = dotenv.env['WEB3AUTH_CLIENT_ID'];
//       final redirectUrl = dotenv.env['WEB3AUTH_REDIRECT_URL'];

//       debugPrint('Loaded redirect URL: $redirectUrl');
//       debugPrint('Loaded client ID: $clientId');

//       if (clientId == null || clientId.isEmpty) {
//         throw Exception(
//             'WEB3AUTH_CLIENT_ID not found in environment variables');
//       }
//       if (redirectUrl == null || redirectUrl.isEmpty) {
//         throw Exception(
//             'WEB3AUTH_REDIRECT_URL not found in environment variables');
//       }

//       // Initialize Web3Auth with proper parameters
//       await Web3AuthFlutter.init(
//         Web3AuthOptions(
//           clientId: clientId,
//           network: Network.sapphire_devnet,
//           redirectUrl: Uri.parse(redirectUrl),
//           whiteLabel: WhiteLabelData(
//             appName: "PYUSD Wallet",
//           ),
//         ),
//       );

//       debugPrint('Web3Auth initialized successfully');
//       _initialized = true;
//     } catch (e) {
//       debugPrint('Web3Auth init error: $e');
//       rethrow;
//     }
//   }

//   // Login with Web3Auth using specified provider
//   Future<WalletModel?> login(Provider provider) async {
//     if (!_initialized) {
//       debugPrint('Calling init() before login attempt');
//       await init();
//     }

//     try {
//       debugPrint('Starting Web3Auth login with provider: $provider');
//       final Web3AuthResponse response = await Web3AuthFlutter.login(
//         LoginParams(
//           mfaLevel: MFALevel.NONE,
//           // curve: Curve.SECP256K1,
//           loginProvider: provider,
//         ),
//       );

//       debugPrint('Web3Auth login response received');

//       if (response.privKey == null || response.privKey!.isEmpty) {
//         debugPrint('Web3Auth login failed: No private key received');
//         return null;
//       }

//       debugPrint('Private key received, creating credentials');

//       // Create credentials
//       final credentials = EthPrivateKey.fromHex(response.privKey!);
//       final address = await credentials.extractAddress();

//       debugPrint('Wallet address: ${address.hex}');

//       return WalletModel(
//         address: address.hex,
//         privateKey: response.privKey!,
//         mnemonic: '', // Web3Auth doesn't provide mnemonics
//         credentials: credentials,
//         userInfo: response.userInfo != null
//             ? {
//                 'email': response.userInfo?.email,
//                 'name': response.userInfo?.name,
//                 'profileImage': response.userInfo?.profileImage,
//                 'verifier': response.userInfo?.verifier,
//                 'verifierId': response.userInfo?.verifierId,
//                 'typeOfLogin': response.userInfo?.typeOfLogin,
//               }
//             : {},
//       );
//     } catch (e) {
//       debugPrint('Web3Auth login error: $e');
//       rethrow;
//     }
//   }

//   // Get the current wallet if logged in via Web3Auth
//   Future<WalletModel?> getWallet() async {
//     if (!_initialized) {
//       debugPrint('Initializing Web3Auth before getting wallet');
//       await init();
//     }

//     try {
//       debugPrint('Getting private key from Web3Auth');
//       final privKey = await Web3AuthFlutter.getPrivKey();

//       if (privKey == null || privKey.isEmpty) {
//         debugPrint('No private key found, user not logged in');
//         return null;
//       }

//       debugPrint('Private key obtained, creating wallet');

//       // Create wallet from private key
//       final credentials = EthPrivateKey.fromHex(privKey);
//       final address = await credentials.extractAddress();

//       // Get user info
//       final userInfo = await Web3AuthFlutter.getUserInfo();
//       debugPrint('User info obtained: ${userInfo?.email != null}');

//       return WalletModel(
//         address: address.hex,
//         privateKey: privKey,
//         mnemonic: '', // Web3Auth doesn't provide mnemonics
//         credentials: credentials,
//         userInfo: userInfo != null
//             ? {
//                 'email': userInfo.email,
//                 'name': userInfo.name,
//                 'profileImage': userInfo.profileImage,
//                 'verifier': userInfo.verifier,
//                 'verifierId': userInfo.verifierId,
//                 'typeOfLogin': userInfo.typeOfLogin,
//               }
//             : {},
//       );
//     } catch (e) {
//       debugPrint('Web3Auth getWallet error: $e');
//       return null;
//     }
//   }

//   // Logout from Web3Auth
//   Future<void> logout() async {
//     if (!_initialized) {
//       debugPrint('Not initialized, nothing to logout from');
//       return;
//     }

//     try {
//       debugPrint('Logging out from Web3Auth');
//       await Web3AuthFlutter.logout();
//       debugPrint('Logout successful');
//     } catch (e) {
//       debugPrint('Web3Auth logout error: $e');
//       rethrow;
//     }
//   }
// }
