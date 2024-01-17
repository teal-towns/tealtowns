import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../modules/user_auth/current_user_state.dart';

class LinkService {
  LinkService._privateConstructor();
  static final LinkService _instance = LinkService._privateConstructor();
  factory LinkService() {
    return _instance;
  }

  void Go(String url, BuildContext context, CurrentUserState currentUserState) {
    if (!currentUserState.isLoggedIn) {
      context.go('/login');
    } else {
      context.go(url);
    }
  }

  void LaunchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
