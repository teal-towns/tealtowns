import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import './current_user_state.dart';
import '../../app_scaffold.dart';
import '../../routes.dart';

class Auth extends StatefulWidget {
  Widget child = SizedBox.shrink();
  Auth({ @required this.child = const SizedBox.shrink(), Key? key, }) : super(key: key);

  @override
  _AuthState createState() => _AuthState();
}

String _status = '';

class _AuthState extends State<Auth> {

  @override
  void initState() {
    _status = '';
    super.initState();

    //String status = Provider.of<CurrentUserState>(context, listen: false).status;
    //if (authState.status == AuthStatus.idle) {
    //  WidgetsBinding.instance.addPostFrameCallback((_) async {
    //    await Future.delayed(const Duration(milliseconds: 500,));
    //    authState.authenticate();
    //  });
    //}
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    String status = Provider.of<CurrentUserState>(context, listen: false).status;
    if (status != _status) {
      _status = status;
      if (status == 'done' && !Provider.of<CurrentUserState>(context, listen: false).isLoggedIn) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go(Routes.login);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var currentUserState = context.watch<CurrentUserState?>();

    if (!currentUserState?.isLoggedIn) {
      return AppScaffoldComponent(
        body: ListView(
          children: [
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 600,
                padding: EdgeInsets.only(top: 20, left: 10, right: 10),
                child: Text('Loading..'),
              )
            )
          ]
        )
      );
    }

    return widget.child;
  }
}
