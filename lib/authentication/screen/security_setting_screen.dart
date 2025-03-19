// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../provider/auth_provider.dart';
// import '../provider/session_provider.dart';
// import '../widgets/pin_input_widget.dart';
// import 'pinsetup_screen.dart';

// class SecuritySettingsScreen extends StatefulWidget {
//   const SecuritySettingsScreen({Key? key}) : super(key: key);

//   @override
//   State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
// }

// class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
//   bool _isBiometricsAvailable = false;
//   bool _isBiometricsEnabled = false;
//   bool _isCheckingBiometrics = true;
//   bool _isChangingPIN = false;
//   String? _currentPin;

//   @override
//   void initState() {
//     super.initState();
//     _checkBiometrics();
//   }

//   Future<void> _checkBiometrics() async {
//     final authProvider = Provider.of<AuthProvider>(context, listen: false);

//     _isBiometricsAvailable = await authProvider.checkBiometrics();
//     if (_isBiometricsAvailable) {
//       _isBiometricsEnabled = await authProvider.isBiometricsEnabled();
//     }

//     if (mounted) {
//       setState(() {
//         _isCheckingBiometrics = false;
//       });
//     }
//   }

//   void _showEnableBiometricsDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Enable Biometrics'),
//         content: PinInput(
//           onPinEntered: (pin) async {
//             Navigator.of(context).pop();
//             final authProvider =
//                 Provider.of<AuthProvider>(context, listen: false);

//             final success = await authProvider.enableBiometrics(pin);
//             if (success) {
//               setState(() {
//                 _isBiometricsEnabled = true;
//               });

//               if (mounted) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(
//                     content: Text('Biometric authentication enabled'),
//                     backgroundColor: Colors.green,
//                   ),
//                 );
//               }
//             } else {
//               if (mounted) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                     content: Text(
//                         authProvider.error ?? 'Failed to enable biometrics'),
//                     backgroundColor: Colors.red,
//                   ),
//                 );
//               }
//             }
//           },
//           title: 'Enter your PIN',
//         ),
//       ),
//     );
//   }

//   Widget _buildChangePINSection() {
//     if (!_isChangingPIN) {
//       return ElevatedButton.icon(
//         onPressed: () {
//           setState(() {
//             _isChangingPIN = true;
//             _currentPin = null;
//           });
//         },
//         icon: const Icon(Icons.lock_outline),
//         label: const Text('Change PIN'),
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Theme.of(context).colorScheme.primary,
//           foregroundColor: Theme.of(context).colorScheme.onPrimary,
//           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//         ),
//       );
//     } else {
//       if (_currentPin == null) {
//         // Step 1: Enter current PIN
//         return Column(
//           children: [
//             const Text(
//               'Enter your current PIN',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 16),
//             PinInput(
//               onCompleted: (pin) {
//                 setState(() {
//                   _currentPin = pin;
//                 });
//               },
//             ),
//             const SizedBox(height: 16),
//             TextButton(
//               onPressed: () {
//                 setState(() {
//                   _isChangingPIN = false;
//                 });
//               },
//               child: const Text('Cancel'),
//             ),
//           ],
//         );
//       } else {
//         // Step 2: Enter new PIN
//         return Column(
//           children: [
//             const Text(
//               'Enter your new PIN',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 16),
//             PinInputWidget(
//               onPinEntered: (newPin) async {
//                 final authProvider =
//                     Provider.of<AuthProvider>(context, listen: false);
//                 final success =
//                     await authProvider.changePIN(_currentPin!, newPin);

//                 if (mounted) {
//                   setState(() {
//                     _isChangingPIN = false;
//                   });

//                   if (success) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(
//                         content: Text('PIN changed successfully'),
//                         backgroundColor: Colors.green,
//                       ),
//                     );
//                   } else {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(
//                         content:
//                             Text(authProvider.error ?? 'Failed to change PIN'),
//                         backgroundColor: Colors.red,
//                       ),
//                     );
//                   }
//                 }
//               },
//               title: '',
//             ),
//             const SizedBox(height: 16),
//             TextButton(
//               onPressed: () {
//                 setState(() {
//                   _isChangingPIN = false;
//                 });
//               },
//               child: const Text('Cancel'),
//             ),
//           ],
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final primaryColor = Theme.of(context).colorScheme.primary;
//     final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
//     final onBackground = Theme.of(context).colorScheme.onBackground;

//     return Scaffold(
//       backgroundColor: backgroundColor,
//       appBar: AppBar(
//         title: const Text('Security Settings'),
//         centerTitle: true,
//         elevation: 0,
//         backgroundColor: Colors.transparent,
//         foregroundColor: onBackground,
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: _isCheckingBiometrics
//               ? Center(child: CircularProgressIndicator(color: primaryColor))
//               : Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Security Info Section
//                     Container(
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: Theme.of(context)
//                             .colorScheme
//                             .primary
//                             .withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             children: [
//                               Icon(Icons.security, color: primaryColor),
//                               const SizedBox(width: 8),
//                               Text(
//                                 'Security Options',
//                                 style: TextStyle(
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.bold,
//                                   color: onBackground,
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 16),
//                           Text(
//                             'Secure your wallet with multiple authentication methods',
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: onBackground.withOpacity(0.7),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),

//                     const SizedBox(height: 32),

//                     // PIN Section
//                     Text(
//                       'PIN Protection',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                         color: onBackground,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Your PIN is required to access your wallet and confirm transactions',
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: onBackground.withOpacity(0.7),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     _buildChangePINSection(),

//                     const SizedBox(height: 32),

//                     // Biometrics Section
//                     if (_isBiometricsAvailable)
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Biometric Authentication',
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                               color: onBackground,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             'Use fingerprint or face recognition to quickly access your wallet',
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: onBackground.withOpacity(0.7),
//                             ),
//                           ),
//                           const SizedBox(height: 16),
//                           SwitchListTile(
//                             title: const Text('Enable Biometrics'),
//                             value: _isBiometricsEnabled,
//                             onChanged: (value) {
//                               if (value) {
//                                 _showEnableBiometricsDialog();
//                               } else {
//                                 // TODO: Implement disable biometrics
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   const SnackBar(
//                                     content: Text(
//                                         'To disable biometrics, please change your PIN'),
//                                     backgroundColor: Colors.orange,
//                                   ),
//                                 );
//                               }
//                             },
//                             secondary: Icon(
//                               Icons.fingerprint,
//                               color: _isBiometricsEnabled
//                                   ? primaryColor
//                                   : onBackground.withOpacity(0.5),
//                             ),
//                           ),
//                         ],
//                       ),

//                     const SizedBox(height: 32),

//                     // Auto-Lock Section
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Auto-Lock',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                             color: onBackground,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           'Automatically lock your wallet after a period of inactivity',
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: onBackground.withOpacity(0.7),
//                           ),
//                         ),
//                         const SizedBox(height: 16),
//                         Consumer<SessionProvider>(
//                           builder: (context, sessionProvider, _) {
//                             return DropdownButtonFormField<int>(
//                               value: sessionProvider.autoLockDuration,
//                               decoration: InputDecoration(
//                                 labelText: 'Auto-Lock Timer',
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(8.0),
//                                 ),
//                                 prefixIcon:
//                                     Icon(Icons.timer, color: primaryColor),
//                               ),
//                               items: const [
//                                 DropdownMenuItem(
//                                     value: 1, child: Text('1 minute')),
//                                 DropdownMenuItem(
//                                     value: 5, child: Text('5 minutes')),
//                                 DropdownMenuItem(
//                                     value: 15, child: Text('15 minutes')),
//                                 DropdownMenuItem(
//                                     value: 30, child: Text('30 minutes')),
//                                 DropdownMenuItem(
//                                     value: 60, child: Text('1 hour')),
//                                 DropdownMenuItem(
//                                     value: 0, child: Text('Never')),
//                               ],
//                               onChanged: (value) {
//                                 if (value != null) {
//                                   sessionProvider.setAutoLockDuration(value);
//                                 }
//                               },
//                             );
//                           },
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//         ),
//       ),
//     );
//   }
// }
