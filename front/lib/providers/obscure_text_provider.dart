import 'package:flutter/material.dart';

class ObscureTextProvider extends ChangeNotifier {
  bool _obscureText;
  ObscureTextProvider([this._obscureText = true]);
  bool get obscureText => _obscureText;
  void toggle() {
    _obscureText = !_obscureText;
    notifyListeners();
  }
}