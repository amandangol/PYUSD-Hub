// import 'dart:async';
// import 'package:connectivity_plus/connectivity_plus.dart';

// class NetworkService {
//   final _connectivity = Connectivity();
//   final _controller = StreamController<ConnectivityResult>.broadcast();

//   Stream<ConnectivityResult> get connectivityStream => _controller.stream;

//   NetworkService() {
//     _connectivity.onConnectivityChanged.listen((event) {
//       if (event.isNotEmpty) {
//         _controller.add(event.first);
//       }
//     });
//   }

//   Future<bool> isConnected() async {
//     final result = await _connectivity.checkConnectivity();
//     return result != ConnectivityResult.none;
//   }

//   void dispose() {
//     _controller.close();
//   }
// }
