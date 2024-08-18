import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import './colors_service.dart';
import './style.dart';

class CardPlaceholder extends StatefulWidget {
  String text;
  // Widget button;
  IconData icon;
  String onPressUrl;
  double height;
  String colorKey;
  CardPlaceholder({ this.text = '', this.icon = Icons.add, this.onPressUrl = '', this.colorKey = 'primary', this.height = 250, });

  @override
  _CardPlaceholderState createState() => _CardPlaceholderState();
}

class _CardPlaceholderState extends State<CardPlaceholder> {
  ColorsService _colors = ColorsService();
  Style _style = Style();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.go(widget.onPressUrl);
      },
      child: Container(padding: EdgeInsets.all(10), height: widget.height,
        decoration: BoxDecoration(
          border: Border.all(color: _colors.colors[widget.colorKey], width: 1),
        ),
        child: Column(
          // crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 1, child: Container()),
            _style.Text1(widget.text, colorKey: widget.colorKey, align: 'center'),
            _style.SpacingH('medium'),
            Icon(widget.icon, color: _colors.colors[widget.colorKey], size: 40),
            // widget.button,
            Expanded(flex: 1, child: Container()),
          ]
        ),
      ),
    );
  }
}
