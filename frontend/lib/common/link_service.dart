import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
}
