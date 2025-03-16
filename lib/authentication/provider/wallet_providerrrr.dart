// import 'package:flutter/foundation.dart';
// import 'package:web3auth_flutter/web3auth_flutter.dart';

// class WalletProvider with ChangeNotifier {
//   Web3AuthFlutter? _web3Auth;
//   String? _userAddress;
//   String? get userAddress => _userAddress;

//   // Initialize Web3Auth
//   Future<void> initializeWeb3Auth(String clientId, String redirectUrl) async {
//     try {
//       _web3Auth = await Web3AuthFlutter.init(
//         Web3AuthOptions(
//           clientId: clientId, // Replace with your Web3Auth Client ID
//           network: Network.sapphire_devnet, // or any other supported network
//           redirectUrl: redirectUrl, // Set the redirect URL
//         ),
//       );
//       notifyListeners();
//     } catch (e) {
//       print("Error initializing Web3Auth: $e");
//     }
//   }

//   // Login using Web3Auth
//   Future<void> login() async {
//     if (_web3Auth == null) return;

//     try {
//       final loginParams = LoginParams(
//           loginProvider: Provider
//               .google); // You can use other providers like Facebook, Twitter, etc.
//       await _web3Auth!.login(loginParams);
//       final userInfo = await _web3Auth!.getUserInfo();
//       _userAddress = userInfo?.userAddress;
//       notifyListeners();
//     } catch (e) {
//       print("Login failed: $e");
//     }
//   }

//   // Logout using Web3Auth
//   Future<void> logout() async {
//     if (_web3Auth == null) return;

//     try {
//       await _web3Auth!.logout();
//       _userAddress = null;
//       notifyListeners();
//     } catch (e) {
//       print("Logout failed: $e");
//     }
//   }
// }
