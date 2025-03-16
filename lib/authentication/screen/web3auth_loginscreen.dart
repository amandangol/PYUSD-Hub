// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:web3auth_flutter/enums.dart' as web3auth;
// import '../../authentication/provider/auth_provider.dart';
// import '../../common/pyusd_appbar.dart';

// class Web3AuthLoginScreen extends StatefulWidget {
//   const Web3AuthLoginScreen({Key? key}) : super(key: key);

//   @override
//   State<Web3AuthLoginScreen> createState() => _Web3AuthLoginScreenState();
// }

// class _Web3AuthLoginScreenState extends State<Web3AuthLoginScreen> {
//   bool _isInitializing = true;
//   bool _isLoggingIn = false; // Added to track login process

//   @override
//   void initState() {
//     super.initState();
//     _initializeWeb3Auth();
//   }

//   Future<void> _initializeWeb3Auth() async {
//     final authProvider = Provider.of<AuthProvider>(context, listen: false);

//     setState(() {
//       _isInitializing = true;
//     });

//     try {
//       await authProvider.initWeb3Auth();

//       // If already logged in, navigate to home
//       if (authProvider.wallet != null) {
//         _navigateToMain();
//       }
//     } catch (e) {
//       debugPrint('Initialization error: $e'); // Add debug print
//       // Error will be shown in the UI
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isInitializing = false;
//         });
//       }
//     }
//   }

//   void _navigateToMain() {
//     Navigator.of(context).pushReplacementNamed('/main');
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final isDarkMode = theme.brightness == Brightness.dark;
//     final primaryColor =
//         isDarkMode ? theme.colorScheme.primary : const Color(0xFF3D56F0);
//     final backgroundColor = isDarkMode ? const Color(0xFF1A1A2E) : Colors.white;

//     return Scaffold(
//       backgroundColor: backgroundColor,
//       appBar: PyusdAppBar(
//         isDarkMode: isDarkMode,
//         hasWallet: false,
//         title: 'Login Screen',
//       ),
//       body: Consumer<AuthProvider>(
//         builder: (context, authProvider, _) {
//           // Show loading indicator for both initialization and login process
//           if (_isInitializing || authProvider.isLoading || _isLoggingIn) {
//             return const Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   CircularProgressIndicator(),
//                   SizedBox(height: 16),
//                   Text('Loading...'), // Added text for better UX
//                 ],
//               ),
//             );
//           }

//           if (authProvider.error != null) {
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.error_outline, color: Colors.red, size: 64),
//                   const SizedBox(height: 16),
//                   Text(
//                     'Error: ${authProvider.error}',
//                     style: const TextStyle(color: Colors.red),
//                     textAlign: TextAlign.center,
//                   ),
//                   const SizedBox(height: 24),
//                   ElevatedButton(
//                     onPressed: () {
//                       authProvider.clearError();
//                       _initializeWeb3Auth();
//                     },
//                     child: const Text('Retry'),
//                   ),
//                 ],
//               ),
//             );
//           }

//           return SingleChildScrollView(
//             padding: const EdgeInsets.all(24.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 // Logo or branding
//                 const SizedBox(height: 40),
//                 Icon(
//                   Icons.account_balance_wallet,
//                   size: 80,
//                   color: primaryColor,
//                 ),
//                 const SizedBox(height: 24),
//                 Text(
//                   'Welcome to PYUSD Wallet',
//                   style: TextStyle(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                     color: isDarkMode ? Colors.white : Colors.black87,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 12),
//                 Text(
//                   'Secure, simple, and efficient digital wallet for PayPal USD',
//                   style: TextStyle(
//                     fontSize: 16,
//                     color: isDarkMode ? Colors.white70 : Colors.black54,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 48),

//                 // Login buttons
//                 _buildLoginButton(
//                   context,
//                   authProvider,
//                   'Continue with Google',
//                   web3auth.Provider.google,
//                   Icons.g_mobiledata,
//                   Colors.red,
//                 ),
//                 const SizedBox(height: 16),
//                 _buildLoginButton(
//                   context,
//                   authProvider,
//                   'Continue with Facebook',
//                   web3auth.Provider.facebook,
//                   Icons.facebook,
//                   Colors.blue,
//                 ),
//                 const SizedBox(height: 16),
//                 _buildLoginButton(
//                   context,
//                   authProvider,
//                   'Continue with Twitter',
//                   web3auth.Provider.twitter,
//                   Icons.telegram,
//                   Colors.lightBlue,
//                 ),
//                 const SizedBox(height: 16),
//                 _buildLoginButton(
//                   context,
//                   authProvider,
//                   'Continue with Apple',
//                   web3auth.Provider.apple,
//                   Icons.apple,
//                   Colors.black,
//                 ),
//                 const SizedBox(height: 24),

//                 // Divider
//                 Row(
//                   children: [
//                     Expanded(
//                         child: Divider(
//                             color:
//                                 isDarkMode ? Colors.white30 : Colors.black26)),
//                     Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                       child: Text(
//                         'OR',
//                         style: TextStyle(
//                             color:
//                                 isDarkMode ? Colors.white54 : Colors.black45),
//                       ),
//                     ),
//                     Expanded(
//                         child: Divider(
//                             color:
//                                 isDarkMode ? Colors.white30 : Colors.black26)),
//                   ],
//                 ),
//                 const SizedBox(height: 24),

//                 // Legacy wallet options
//                 TextButton(
//                   onPressed: () {
//                     Navigator.pushNamed(context, '/legacy_import');
//                   },
//                   child: Text(
//                     'Import Existing Wallet',
//                     style: TextStyle(color: primaryColor),
//                   ),
//                 ),
//                 TextButton(
//                   onPressed: () async {
//                     try {
//                       setState(() {
//                         _isLoggingIn = true;
//                       });
//                       await authProvider.createWallet();
//                       _navigateToMain();
//                     } catch (e) {
//                       // Error will be shown in the UI
//                     } finally {
//                       if (mounted) {
//                         setState(() {
//                           _isLoggingIn = false;
//                         });
//                       }
//                     }
//                   },
//                   child: Text(
//                     'Create New Wallet',
//                     style: TextStyle(color: primaryColor),
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildLoginButton(
//     BuildContext context,
//     AuthProvider authProvider,
//     String label,
//     web3auth.Provider provider,
//     IconData icon,
//     Color iconColor,
//   ) {
//     return ElevatedButton.icon(
//       onPressed: () async {
//         try {
//           setState(() {
//             _isLoggingIn = true; // Show loading state during login
//           });

//           // Add debug print to track login process
//           debugPrint('Starting login with $provider');

//           await authProvider.loginWithWeb3Auth(provider);

//           debugPrint('Login completed, wallet: ${authProvider.wallet != null}');

//           if (authProvider.wallet != null) {
//             _navigateToMain();
//           } else {
//             // Handle the case where login completed but wallet is null
//             debugPrint('Login completed but wallet is null');
//             if (mounted) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(
//                   content: Text('Login failed. Please try again.'),
//                   duration: Duration(seconds: 3),
//                 ),
//               );
//             }
//           }
//         } catch (e) {
//           debugPrint('Login error: $e');
//           // Show error message
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text('Login error: $e'),
//                 duration: const Duration(seconds: 3),
//               ),
//             );
//           }
//         } finally {
//           if (mounted) {
//             setState(() {
//               _isLoggingIn = false;
//             });
//           }
//         }
//       },
//       icon: Icon(icon, color: iconColor),
//       label: Text(label),
//       style: ElevatedButton.styleFrom(
//         padding: const EdgeInsets.symmetric(vertical: 16),
//         textStyle: const TextStyle(fontSize: 16),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(8),
//         ),
//       ),
//     );
//   }
// }
