import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    'xlarge': 30,
    'xxlarge': 42,
    'xxxlarge': 57,
  };
  Map<String, double> _spacingMap = {
    'none': 0,
    'small': 5,
    'medium': 10,
    'large': 20,
    'xlarge': 40,
    'xxlarge': 80,
  };

  Map<String, double> GetFontSizes() {
    return _fontSizeMap;
  }

  Map<String, double> GetSpacings() {
    return _spacingMap;
  }

  Widget Text1(String text, { String size = 'medium', Widget? left = null, Widget? right = null,
    String colorKey = 'text', FontWeight fontWeight = FontWeight.normal, double fontSize = -1,
    String align = 'left', String fontFamily = '', String googleFontFamily = '', }) {
    if (!_fontSizeMap.containsKey(size)) {
      size = 'medium';
    }
    if (fontSize < 0) {
      fontSize = _fontSizeMap[size]!;
    }
    TextAlign align1 = align == 'right' ? TextAlign.right : align == 'center' ? TextAlign.center : TextAlign.left;
    TextStyle textStyle = TextStyle(
      fontSize: fontSize,
      color: _colors.colors[colorKey],
      fontWeight: fontWeight,
    );
    if (fontFamily.length > 0) {
      textStyle = textStyle.copyWith(fontFamily: fontFamily);
    }
    if (googleFontFamily.length > 0) {
      textStyle = textStyle.copyWith(fontFamily: GoogleFonts.getFont(googleFontFamily).fontFamily);
    }
    Widget content = Text(text, style: textStyle, textAlign: align1,);
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
