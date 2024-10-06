import 'package:flutter/material.dart';

// Note: Must also update custom_theme.dart to match
Map<String, List<double>> _colorMap = {
  'primary': [44, 163, 134],
  'primaryLight': [44, 163, 134],
  'primaryDark': [16, 91, 87],
  'primaryTransparent': [44, 163, 134, 0.4],
  'accent': [143, 229, 142],
  'accentDark': [143, 229, 142],
  'accentTransparent': [143, 229, 142, 0.4],
  'secondary': [253, 224, 72],
  // 'secondary': [143, 229, 142],
  'text': [124, 124, 124],
  'success': [44, 163, 134],
  'error': [234, 84, 85],
  'warning': [220, 145, 110],
  'transparent': [0,0,0,0],

  // 'magentaTransparent': [200, 100, 240, 0.4],
  // 'magenta': [200, 100, 240],
  // 'red': [200, 100, 0],

  'greyLighter': [225, 225, 225],
  'greyLight': [200, 200, 200],
  'grey': [125, 125, 125],
  'greyTransparent': [125, 125, 125, 0.4],
  'greyDark': [50, 50, 50],
  'white': [255, 255, 255],
  'brown': [72, 43, 8],
  'black': [0, 0, 0],
};
// List<double> primary = [0, 167, 0];
// List<double> secondary = [15, 69, 194];
// List<double> primaryLight = [0, 167, 0, 0.5];
// List<double> text = [90, 90, 90];

// List<double> magentaTransparent = [200, 100, 240, 0.4];
// List<double> magenta = magentaTransparent.sublist(0, magentaTransparent.length - 1);
// List<double> red = [200, 100, 0];
// List<double> greyLighter = [225, 225, 225];
// List<double> greyLight = [200, 200, 200];
// List<double> grey = [125, 125, 125];
// List<double> greyTransparent = [125, 125, 125, 0.4];
// List<double> greyDark = [50, 50, 50];
// List<double> white = [255, 255, 255];

String valsToString(List<double> vals) {
  String str = 'rgba(';
  if (vals.length == 3) {
    vals.add(1);
  }
  
  for (int i=0; i<3; i++) {
    str = str + vals[i].toString() + ', ';
  }
  str = str + vals[3].toString() + ')';
  return str;
}

Color valsToColor(List<double> vals) {
  // Assume full opacity if none is provided
  if (vals.length == 3) {
    vals.add(1);
  }
  return Color.fromRGBO(vals[0].toInt(), vals[1].toInt(), vals[2].toInt(), vals[3]);
}
  
class ColorsService {
  ColorsService._privateConstructor();
  static final ColorsService _instance = ColorsService._privateConstructor();
  factory ColorsService() {
    return _instance;
  }

  Map<String, Color> _colors = {};
  Map<String, String> _colorsStr = {};

  bool _inited = false;

  void Init() {
    _inited = true;
    for (String key in _colorMap.keys) {
      _colors[key] = valsToColor(_colorMap[key]!);
      _colorsStr[key] = valsToString(_colorMap[key]!);
    }
  }

  List<double> GetRGB(String key) {
    if (!_inited) {
      Init();
    }
    if (!_colorMap.containsKey(key)) {
      return [0, 0, 0];
    }
    return _colorMap[key]!;
  }

  Map<String, Color> GetColors() {
    if (!_inited) {
      Init();
    }
    return _colors;
  }

  Map<String, String> GetColorsStr() {
    if (!_inited) {
      Init();
    }
    return _colorsStr;
  }

  // get colors => _colors;
  // get colorsStr => _colorsStr;
  get colors => GetColors();
  get colorsStr => GetColorsStr();
}
