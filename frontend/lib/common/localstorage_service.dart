import 'dart:convert';
import 'package:localstorage/localstorage.dart';

import './parse_service.dart';

class LocalstorageService {
  LocalstorageService._privateConstructor();
  static final LocalstorageService _instance = LocalstorageService._privateConstructor();
  factory LocalstorageService() {
    return _instance;
  }

  final _jsonEncoder = JsonEncoder();

  ParseService _parseService = ParseService();

  dynamic GetItem(String key, { String parseType = 'listDynamic' }) {
    String? value = localStorage.getItem(key);
    if (value == null) {
      return null;
    }
    Map<String, dynamic> json = jsonDecode(value);
    if (parseType == 'listDynamic') {
      return value;
      // return json.decode(value!) as List<dynamic>?;
    } else if (parseType == 'mapStringDynamic') {
      return _parseService.parseMapStringDynamic(json);
    }
    return json;
  }

  void SetItem(String key, dynamic value) {
    localStorage.setItem(key, _jsonEncoder.convert(value));
  }

  void RemoveItem(String key) {
    localStorage.removeItem(key);
  }
}