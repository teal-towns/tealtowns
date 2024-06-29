import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import './colors_service.dart';
import './link_service.dart';

class Buttons {
  Buttons._privateConstructor();
  static final Buttons _instance = Buttons._privateConstructor();
  factory Buttons() {
    return _instance;
  }

  ColorsService _colors = ColorsService();
  LinkService _linkService = LinkService();

  Widget Link(BuildContext context, String text, String url, {bool checkLoggedIn = false, bool launchUrl = false,
    String colorBackground = 'transparent', String colorText = 'primary'}) {
    return TextButton(
      onPressed: () {
        OnPress(context, url, checkLoggedIn: checkLoggedIn, launchUrl: launchUrl);
      },
      style: TextButton.styleFrom(
        backgroundColor: _colors.colors[colorBackground],
        foregroundColor: _colors.colors[colorText],
      ),
      child: Text(text),
    );
  }

  Widget LinkElevated(BuildContext context, String text, String url, {bool checkLoggedIn = false, bool launchUrl = false}) {
    return ElevatedButton(
      onPressed: () {
        OnPress(context, url, checkLoggedIn: checkLoggedIn, launchUrl: launchUrl);
      },
      child: Text(text),
    );
  }

  Widget LinkInline(BuildContext context, String text, String url, {bool checkLoggedIn = false, bool launchUrl = false}) {
    return InkWell(
      onTap: () {
        OnPress(context, url, checkLoggedIn: checkLoggedIn, launchUrl: launchUrl);
      },
      child: Text(text, style: TextStyle( color: Theme.of(context).primaryColor )),
    );
  }

  void OnPress(BuildContext context, String url, {bool checkLoggedIn = false, bool launchUrl = false}) {
    if (launchUrl) {
      _linkService.LaunchURL(url);
    } else {
      if (checkLoggedIn) {
        _linkService.Go(url, context);
      } else {
        context.go(url);
      }
    }
  }
}
