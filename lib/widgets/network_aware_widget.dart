// import 'package:flutter/material.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import '../services/network_service.dart';

// class NetworkAwareWidget extends StatelessWidget {
//   final Widget child;
//   final Widget? offlineWidget;
//   final NetworkService networkService;

//   const NetworkAwareWidget({
//     Key? key,
//     required this.child,
//     this.offlineWidget,
//     required this.networkService,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<ConnectivityResult>(
//       stream: networkService.connectivityStream,
//       builder: (context, snapshot) {
//         if (snapshot.hasData && snapshot.data == ConnectivityResult.none) {
//           return Stack(
//             children: [
//               child, // Keep the main app visible
//               Container(
//                 color: Colors.black54, // Semi-transparent overlay
//                 child: offlineWidget ?? _defaultOfflineWidget(context),
//               ),
//             ],
//           );
//         }
//         return child;
//       },
//     );
//   }

//   Widget _defaultOfflineWidget(BuildContext context) {
//     return Center(
//       child: Container(
//         margin: const EdgeInsets.all(16),
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Icon(Icons.wifi_off, size: 48),
//             const SizedBox(height: 16),
//             const Text(
//               'No Internet Connection',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//             const Text(
//               'Please check your connection and try again',
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: () async {
//                 // Check connectivity again
//                 final isConnected = await networkService.isConnected();
//                 if (context.mounted && isConnected) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(
//                       content: Text('Connected to network'),
//                       backgroundColor: Colors.green,
//                     ),
//                   );
//                 }
//               },
//               child: const Text('Retry Connection'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
