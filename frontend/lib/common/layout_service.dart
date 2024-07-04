import 'package:flutter/material.dart';

class LayoutService {
  LayoutService._privateConstructor();
  static final LayoutService _instance = LayoutService._privateConstructor();
  factory LayoutService() {
    return _instance;
  }

  double _headerHeight = 55;

  get headerHeight => _headerHeight;

  Widget WrapWidth(List<Widget> children, {double width = 250, double spacing = 20, String align = 'center'}) {
    WrapAlignment wrapAlignment = align == 'center' ? WrapAlignment.center : WrapAlignment.start;
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      alignment: wrapAlignment,
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
