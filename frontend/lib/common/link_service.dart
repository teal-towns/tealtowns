import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../modules/user_auth/current_user_state.dart';

class LinkService {
  LinkService._privateConstructor();
  static final LinkService _instance = LinkService._privateConstructor();
  factory LinkService() {
    return _instance;
  }

  void Go(String url, BuildContext context, {CurrentUserState? currentUserState = null}) {
    if (url.length < 1) {
      url = Uri.base.path;
      if (Uri.base.query.length > 0) {
        url = url + '?' + Uri.base.query;
      }
    }
    if (currentUserState == null) {
      currentUserState = Provider.of<CurrentUserState>(context, listen: false);
    }
    if (!currentUserState.isLoggedIn) {
      Provider.of<CurrentUserState>(context, listen: false).SetRedirectUrl(url);
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
