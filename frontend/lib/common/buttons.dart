import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import './link_service.dart';

class Buttons {
  Buttons._privateConstructor();
  static final Buttons _instance = Buttons._privateConstructor();
  factory Buttons() {
    return _instance;
  }

  LinkService _linkService = LinkService();

  Widget Link(BuildContext context, String text, String url, {bool checkLoggedIn = false}) {
    return TextButton(
      onPressed: () {
        if (checkLoggedIn) {
          _linkService.Go(url, context);
        } else {
          context.go(url);
        }
      },
      child: Text(text),
    );
  }

  Widget LinkElevated(BuildContext context, String text, String url, {bool checkLoggedIn = false}) {
    return ElevatedButton(
      onPressed: () {
        if (checkLoggedIn) {
          _linkService.Go(url, context);
        } else {
          context.go(url);
        }
      },
      child: Text(text),
    );
  }

  Widget LinkInline(BuildContext context, String text, String url, {bool checkLoggedIn = false}) {
    return InkWell(
      onTap: () {
        if (checkLoggedIn) {
          _linkService.Go(url, context);
        } else {
          context.go(url);
        }
      },
      child: Text(text, style: TextStyle( color: Theme.of(context).primaryColor )),
    );
  }
}
