import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_scaffold.dart';
// import '../../common/socket_service.dart';
import './user_class.dart';
import './user_phone.dart';
// import '../../common/form_input/input_fields.dart';
import './current_user_state.dart';

class User extends StatefulWidget {
  @override
  _UserState createState() => _UserState();
}

class _UserState extends State<User> {
  // List<String> _routeIds = [];
  // SocketService _socketService = SocketService();
  // InputFields _inputFields = InputFields();

  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffoldComponent(
      listWrapper: true,
      body: Column(
        children: [
          UserPhone(),
        ]
      )
    );
  }

  @override
  void dispose() {
    // _socketService.offRouteIds(_routeIds);
    super.dispose();
  }
}
