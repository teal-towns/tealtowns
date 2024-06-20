import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_scaffold.dart';
import '../../common/form_input/form_save.dart';
import '../../common/form_input/input_fields.dart';
import '../../common/layout_service.dart';
import '../../common/socket_service.dart';
import '../../common/style.dart';
import './user_class.dart';
import './current_user_state.dart';

class UsersSave extends StatefulWidget {
  @override
  _UsersSaveState createState() => _UsersSaveState();
}

class _UsersSaveState extends State<UsersSave> {
  InputFields _inputFields = InputFields();
  LayoutService _layoutService = LayoutService();
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();
  Style _style = Style();

  Map<String, Map<String, dynamic>> _formFields = {
    'roles': {},
  };

  Map<String, dynamic> _filters = {
    'firstName': '',
    'lastName': '',
    'email': '',
  };

  List<UserClass> _users = [];
  UserClass _selectedUser = UserClass.fromJson({});

  @override
  void initState() {
    super.initState();

    var currentUserState = Provider.of<CurrentUserState>(context, listen: false);
    if (!currentUserState.isLoggedIn || !currentUserState.currentUser.roles.contains('editUser')) {
      Timer(Duration(milliseconds: 500), () {
        context.go('/home');
      });
    }

    _routeIds.add(_socketService.onRoute('SearchUsers', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1 && data.containsKey('users')) {
        _users = [];
        for (var user in data['users']) {
          _users.add(UserClass.fromJson(user));
        }
        setState(() { _users = _users; });
      }
    }));
  }

  @override
  void dispose() {
    _socketService.offRouteIds(_routeIds);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double fieldWidth = 300;
    List<Widget> colsUsers = [];
    List<Widget> colsForm = [];
    if (_selectedUser.id.length > 0) {
      colsForm = [
        FormSave(formVals: _selectedUser.toJson(), dataName: 'user',
          routeSave: 'SaveUserRole', fieldWidth: fieldWidth,
          formFields: _formFields,
          parseData: (dynamic data) => UserClass.fromJson(data).toJson(),
          preSave: (dynamic data) {
            data = UserClass.fromJson(data).toJson();
            return data;
          // }, onSave: (dynamic data) {
          },
        ),
        SizedBox(height: 10),
      ];
    } else {
      colsUsers = [
        _layoutService.WrapWidth(_users.map((user) => OneUser(user)).toList(),),
        SizedBox(height: 10),
      ];
    }

    return AppScaffoldComponent(
      listWrapper: true,
      // width: fieldWidth,
      body: Column(
        children: [
          _layoutService.WrapWidth([
            _inputFields.inputText(_filters, 'firstName', label: 'First Name', onChange: (String newVal) {
              SearchUsers();
            }),
            _inputFields.inputText(_filters, 'lastName', label: 'Last Name', onChange: (String newVal) {
              SearchUsers();
            }),
            _inputFields.inputText(_filters, 'email', label: 'Email', onChange: (String newVal) {
              SearchUsers();
            }),
          ]),
          SizedBox(height: 10),
          ...colsUsers,
          ...colsForm,
        ]
      )
    );
  }

  Widget OneUser(UserClass user) {
    return InkWell(
      child: Column(
        children: [
          _style.Text1('${user.firstName} ${user.lastName} (${user.username})'),
          _style.SpacingH('medium'),
          _style.Text1('${user.email}'),
          _style.SpacingH('medium'),
          _style.Text1('${user.roles}'),
        ]
      ),
      onTap: () {
        _selectedUser = user;
        setState(() { _selectedUser = _selectedUser; });
      },
    );
  }

  void SearchUsers() {
    _socketService.emit('SearchUsers', _filters);
    setState(() { _selectedUser = UserClass.fromJson({}); });
  }
}
