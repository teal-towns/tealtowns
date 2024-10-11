import 'dart:convert';
import 'package:flutter/material.dart';
// import 'package:localstorage/localstorage.dart';

// import '../../common/localstorage_service.dart';

class MixerGameState extends ChangeNotifier {
//   LocalstorageService _localstorageService = LocalstorageService();

//   LocalStorage? _localstorage = null;
  Map<String, dynamic> _keyVals = {};

  get keyVals => _keyVals;

//   void GetLocalstorage() {
//     if (_localstorage == null) {
//       _localstorage = _localstorageService.localstorage;
//     }
//   }

  void Save(Map<String, dynamic> keyVals) {
    _keyVals = keyVals;
    print ('save keyVals ${keyVals}');
  }
}
