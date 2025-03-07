// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../provider/authentication_provider.dart';
// import '../screen/authentication_screen.dart';

// class AuthNavigator {
//   /// Navigate to a protected screen that requires authentication.
//   /// If the user is already authenticated, navigates directly to the destination.
//   /// Otherwise, shows the authentication screen first.
//   static Future<void> navigateToProtectedScreen({
//     required BuildContext context,
//     required Widget destination,
//     String authReason = 'Authentication Required',
//   }) async {
//     final authProvider =
//         Provider.of<AuthenticationProvider>(context, listen: false);

//     // If already authenticated, navigate directly
//     if (authProvider.status == AuthStatus.authenticated) {
//       Navigator.of(context).push(
//         MaterialPageRoute(builder: (context) => destination),
//       );
//       return;
//     }

//     // Show authentication screen
//     final authenticated = await Navigator.of(context).push<bool>(
//       MaterialPageRoute(
//         builder: (context) => AuthenticationScreen(
//           authReason: authReason,
//           isSessionAuth: true,
//         ),
//       ),
//     );

//     // If authentication successful, navigate to destination
//     if (authenticated == true) {
//       if (context.mounted) {
//         Navigator.of(context).push(
//           MaterialPageRoute(builder: (context) => destination),
//         );
//       }
//     }
//   }

//   /// Performs a protected action that requires authentication.
//   /// Returns true if the user successfully authenticates, false otherwise.
//   static Future<bool> performProtectedAction({
//     required BuildContext context,
//     String authReason = 'Authentication Required',
//   }) async {
//     final authProvider =
//         Provider.of<AuthenticationProvider>(context, listen: false);

//     // If already authenticated, allow action immediately
//     if (authProvider.status == AuthStatus.authenticated) {
//       return true;
//     }

//     // Show authentication screen
//     final authenticated = await Navigator.of(context).push<bool>(
//       MaterialPageRoute(
//         builder: (context) => AuthenticationScreen(
//           authReason: authReason,
//           isSessionAuth: true,
//         ),
//       ),
//     );

//     return authenticated ?? false;
//   }
// }
