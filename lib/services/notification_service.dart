import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../screens/transactions/model/transaction_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  bool _isInitialized = false;

  NotificationService._internal() {
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Initialize settings for Android
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Initialize settings for iOS
    const iOSSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Combined initialization settings
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );

    // Initialize plugin
    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        print('Notification clicked: ${details.payload}');
      },
    );

    // Request permissions
    await _requestPermissions();

    _isInitialized = true;
    print('NotificationService initialized successfully');
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.requestNotificationsPermission();
      print('Android notification permissions requested');
    }

    if (Platform.isIOS) {
      final IOSFlutterLocalNotificationsPlugin? iOSPlugin =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin>();

      await iOSPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  // Notify about transaction status
  Future<void> showTransactionNotification({
    required String txHash,
    required String tokenSymbol,
    required double amount,
    required TransactionStatus status,
  }) async {
    print('\n=== Showing Transaction Notification ===');
    print('Hash: $txHash');
    print('Status: $status');
    print('Amount: $amount $tokenSymbol');

    // Ensure initialization is complete
    if (!_isInitialized) {
      await _initializeNotifications();
    }

    try {
      String title;
      String body;

      switch (status) {
        case TransactionStatus.confirmed:
          title = '✅ Transaction Confirmed';
          body = 'Your transaction of $amount $tokenSymbol has been confirmed';
          break;
        case TransactionStatus.failed:
          title = '❌ Transaction Failed';
          body = 'Transaction of $amount $tokenSymbol has failed';
          break;
        case TransactionStatus.pending:
          title = '⏳ Transaction Pending';
          body = 'Your transaction of $amount $tokenSymbol is being processed';
          break;
        default:
          return;
      }

      // Create the notification details
      final androidDetails = AndroidNotificationDetails(
        'transaction_channel',
        'Transaction Notifications',
        channelDescription: 'Notifications for transaction updates',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'Transaction Update',
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      );

      final iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      // Show the notification
      await _flutterLocalNotificationsPlugin.show(
        txHash.hashCode,
        title,
        body,
        details,
        payload: txHash,
      );

      print('Notification sent successfully');
    } catch (e) {
      print('Error showing notification: $e');
      print(e.toString());
    }
    print('=== End Notification ===\n');
  }

  // Add a test method
  Future<void> testNotification() async {
    await showTransactionNotification(
      txHash: 'test_hash',
      tokenSymbol: 'ETH',
      amount: 1.0,
      status: TransactionStatus.confirmed,
    );
  }
}
