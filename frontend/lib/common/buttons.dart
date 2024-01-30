import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Buttons {
  Buttons._privateConstructor();
  static final Buttons _instance = Buttons._privateConstructor();
  factory Buttons() {
    return _instance;
  }

  Widget Link(BuildContext context, String text, String url) {
    return TextButton(
      onPressed: () {
        context.go(url);
      },
      child: Text(text),
    );
  }
}
