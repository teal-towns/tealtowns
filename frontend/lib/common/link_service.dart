import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../modules/user_auth/current_user_state.dart';
import './config_service.dart';

class LinkService {
  LinkService._privateConstructor();
  static final LinkService _instance = LinkService._privateConstructor();
  factory LinkService() {
    return _instance;
  }

  ConfigService _configService = ConfigService();

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
      Provider.of<CurrentUserState>(context, listen: false).AddRedirectUrl(url, remove: true);
      context.go('/login');
    } else {
      context.go(url);
    }
  }

  void LaunchURL(String url) async {
    // Check for local url and prepend domain if so.
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      Map<String, dynamic> config = _configService.GetConfig();
      url = '${config['SERVER_URL']}${url}';
    }
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
