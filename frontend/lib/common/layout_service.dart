import 'package:flutter/material.dart';

class LayoutService {
  LayoutService._privateConstructor();
  static final LayoutService _instance = LayoutService._privateConstructor();
  factory LayoutService() {
    return _instance;
  }

  double _headerHeight = 55;

  get headerHeight => _headerHeight;

  Widget WrapWidth(List<Widget> children, {double width = 250, double spacing = 10}) {
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      // alignment: WrapAlignment.center,
      children: <Widget> [
        ...children.map((child) {
          return SizedBox(
            width: width,
            child: child,
          );
        } ).toList(),
      ]
    );
  }
}
