import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

import '../screens/transactions/model/transaction_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  bool _isInitialized = false;
  double? _lastNotifiedGasPrice;
  DateTime? _lastGasPriceNotificationTime;
  static const _gasPriceNotificationCooldown = Duration(minutes: 15);

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

    if (!_isInitialized) {
      await _initializeNotifications();
    }

    try {
      String title;
      String body;
      String formattedAmount = amount.toStringAsFixed(
          tokenSymbol == 'PYUSD' ? 2 : 6); // Format based on token type

      switch (status) {
        case TransactionStatus.confirmed:
          title = '✅ Transaction Confirmed';
          body =
              'Your transaction of $formattedAmount $tokenSymbol has been confirmed. Please refresh the page to see the latest status.';
          break;
        case TransactionStatus.failed:
          title = '❌ Transaction Failed';
          body =
              'Transaction of $formattedAmount $tokenSymbol has failed. Please refresh the page to see the latest status.';
          break;
        case TransactionStatus.pending:
          title = '⏳ Transaction Pending';
          body =
              'Your transaction of $formattedAmount $tokenSymbol is being processed';
          break;
      }

      const androidDetails = AndroidNotificationDetails(
        'transaction_channel',
        'Transaction Notifications',
        channelDescription: 'Notifications for transaction updates',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'Transaction Update',
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

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
  }

  // Notify about low gas price
  Future<void> showGasPriceNotification({
    required double currentGasPrice,
    required double thresholdGasPrice,
    required double averageGasPrice,
  }) async {
    // Check if we should show notification (cooldown period)
    if (_lastGasPriceNotificationTime != null &&
        DateTime.now().difference(_lastGasPriceNotificationTime!) <
            _gasPriceNotificationCooldown) {
      return;
    }

    // Check if gas price is significantly lower than threshold
    if (currentGasPrice >= thresholdGasPrice) {
      return;
    }

    // Check if we've already notified for this price
    if (_lastNotifiedGasPrice == currentGasPrice) {
      return;
    }

    // Ensure initialization is complete
    if (!_isInitialized) {
      await _initializeNotifications();
    }

    try {
      final savings =
          ((thresholdGasPrice - currentGasPrice) / thresholdGasPrice * 100)
              .toStringAsFixed(1);

      const androidDetails = AndroidNotificationDetails(
        'gas_price_channel',
        'Gas Price Alerts',
        channelDescription: 'Notifications for low gas prices',
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'Gas Price Alert',
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
        color: Colors.green,
        enableLights: true,
        ledColor: Colors.green,
        ledOnMs: 1000,
        ledOffMs: 500,
      );

      const iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      // Show the notification
      await _flutterLocalNotificationsPlugin.show(
        'gas_price_alert'.hashCode,
        '🎉 Low Gas Price Alert!',
        'Gas price is $savings% lower than your threshold!\nCurrent: ${currentGasPrice.toStringAsFixed(3)} Gwei',
        details,
        payload: 'gas_price_alert',
      );

      // Update last notification time and price
      _lastGasPriceNotificationTime = DateTime.now();
      _lastNotifiedGasPrice = currentGasPrice;

      print('Gas price notification sent successfully');
    } catch (e) {
      print('Error showing gas price notification: $e');
    }
  }

  // // Add a test method
  // Future<void> testNotification() async {
  //   await showTransactionNotification(
  //     txHash: 'test_hash',
  //     tokenSymbol: 'ETH',
  //     amount: 1.0,
  //     status: TransactionStatus.confirmed,
  //   );
  // }
}
