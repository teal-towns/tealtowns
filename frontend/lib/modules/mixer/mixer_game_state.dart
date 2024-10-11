import 'dart:convert';
import 'package:flutter/material.dart';

class MixerGameState extends ChangeNotifier {
  Map<String, dynamic> _keyVals = {};

  get keyVals => _keyVals;

  void Save(Map<String, dynamic> keyVals) {
    _keyVals = keyVals;
  }
}
