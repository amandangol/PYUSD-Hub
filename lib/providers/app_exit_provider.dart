import 'package:flutter/material.dart';

class AppExitProvider extends ChangeNotifier {
  bool _isExiting = false;
  bool get isExiting => _isExiting;

  void setExiting(bool value) {
    _isExiting = value;
    notifyListeners();
  }
}
