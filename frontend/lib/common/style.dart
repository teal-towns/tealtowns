import 'package:flutter/material.dart';

import './colors_service.dart';

class Style {
  Style._privateConstructor();
  static final Style _instance = Style._privateConstructor();
  factory Style() {
    return _instance;
  }

  ColorsService _colors = ColorsService();

  Map<String, double> _fontSizeMap = {
    'small': 12,
    'medium': 15,
    'large': 21,
    'xlarge': 26,
    'xxlarge': 32,
  };
  Map<String, double> _spacingMap = {
    'none': 0,
    'small': 5,
    'medium': 10,
    'large': 20,
    'xlarge': 30,
  };

  Map<String, double> GetFontSizes() {
    return _fontSizeMap;
  }

  Map<String, double> GetSpacings() {
    return _spacingMap;
  }

  Widget Text1(String text, { String size = 'medium', Widget? left = null, Widget? right = null,
    String colorKey = 'text', FontWeight fontWeight = FontWeight.normal }) {
    if (!_fontSizeMap.containsKey(size)) {
      size = 'medium';
    }
    Widget content = Text(text, style: TextStyle(
      fontSize: _fontSizeMap[size],
      color: _colors.colors[colorKey],
      fontWeight: fontWeight,
    ));
    if (left != null || right != null) {
      List<Widget> rows = [];
      if (left != null) {
        rows += [
          left!,
          SizedBox(width: 10),
        ];
      }
      rows.add(Expanded(flex: 1, child: content));
      if (right != null) {
        rows += [
          SizedBox(width: 10),
          right!,
        ];
      }
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
    }
    return content;
  }

  Widget Spacing({ String height = 'none', String width = 'none' }) {
    if (!_spacingMap.containsKey(height)) {
      height = 'none';
    }
    if (!_spacingMap.containsKey(width)) {
      width = 'none';
    }
    return SizedBox(height: _spacingMap[height], width: _spacingMap[width]);
  }

  Widget SpacingH(String height) {
    return Spacing(height: height);
  }

  Widget SpacingV(String width) {
    return Spacing(width: width);
  }
}
