import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_scaffold.dart';
import '../../common/socket_service.dart';
import '../../common/style.dart';
import './user_class.dart';
import './user_phone.dart';
import './current_user_state.dart';

class User extends StatefulWidget {
  String username;

  User({this.username = ''});

  @override
  _UserState createState() => _UserState();
}

class _UserState extends State<User> {
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();
  Style _style = Style();

  bool _loading = false;
  String _message = '';
  UserClass _user = UserClass.fromJson({});
  bool _userIsSelf = false;

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('getUserByUsername', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (int.tryParse(data['valid']) == 1 && data['user'] != null && data['user'].runtimeType != String) {
        _user = UserClass.fromJson(data['user']);
        setState(() { _user = _user; });
      } else {
        _message = 'No user found for username ${widget.username}';
        setState(() { _message = _message; });
      }
    }));

    if (widget.username.length > 0) {
      _socketService.emit('getUserByUsername', {'username': widget.username});
      if (Provider.of<CurrentUserState>(context, listen: false).isLoggedIn && widget.username == Provider.of<CurrentUserState>(context, listen: false).currentUser.username) {
        _userIsSelf = true;
      }
    } else {
      if (!Provider.of<CurrentUserState>(context, listen: false).isLoggedIn) {
        Timer(Duration(milliseconds: 500), () {
          context.go('/login');
        });
      } else {
        _user = Provider.of<CurrentUserState>(context, listen: false).currentUser;
        _userIsSelf = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> cols = [];
    if (_message.length > 0) {
      cols.add(Text('${_message}'));
    } else {
      Widget phone = _userIsSelf ? UserPhone() : SizedBox.shrink();
      cols += [
        _style.Text1('${_user.firstName} ${_user.lastName} (${_user.username})', size: 'large'),
        _style.SpacingH('medium'),
        phone,
      ];
    }
    return AppScaffoldComponent(
      listWrapper: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...cols,
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
