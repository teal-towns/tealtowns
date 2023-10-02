import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_scaffold.dart';
import '../../common/socket_service.dart';
import './current_user_state.dart';
import '../../routes.dart';

class UserLogoutComponent extends StatefulWidget {
  @override
  _UserLogoutState createState() => _UserLogoutState();
}

class _UserLogoutState extends State<UserLogoutComponent> {
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();

  bool _loading = false;
  String _message = '';

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('logout', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        Provider.of<CurrentUserState>(context, listen: false).clearUser();
        context.go(Routes.home);
      } else {
        setState(() { _message = data['msg'].length > 0 ? data['msg'] : 'Logout error'; });
      }
      //setState(() { _loading = false; });
    }));

    if (Provider.of<CurrentUserState>(context, listen: false).isLoggedIn) {
      Provider.of<CurrentUserState>(context, listen: false).logout();
    } else {
      Timer(Duration(milliseconds: 500), () {
        context.go(Routes.home);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffoldComponent(
      body: ListView(
        children: [
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 600,
              padding: EdgeInsets.only(top: 20, left: 10, right: 10),
              child: Column(
                children: <Widget> [
                  Text('Logging out'),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: LinearProgressIndicator(
                    ),
                  ),
                ]
              )
            ),
          )
        ]
      )
    );
  }

  @override
  void dispose() {
    _socketService.offRouteIds(_routeIds);
    super.dispose();
  }
}