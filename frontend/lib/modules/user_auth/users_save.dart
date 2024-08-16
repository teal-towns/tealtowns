import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_scaffold.dart';
import '../../common/buttons.dart';
import '../../common/date_time_service.dart';
import '../../common/form_input/form_save.dart';
import '../../common/form_input/input_fields.dart';
import '../../common/layout_service.dart';
import '../../common/socket_service.dart';
import '../../common/style.dart';
import './user_class.dart';
import './current_user_state.dart';
import '../neighborhood/neighborhood_state.dart';
import '../neighborhood/user_neighborhood_class.dart';

class UsersSave extends StatefulWidget {
  @override
  _UsersSaveState createState() => _UsersSaveState();
}

class _UsersSaveState extends State<UsersSave> {
  Buttons _buttons = Buttons();
  DateTimeService _dateTime = DateTimeService();
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
    'sortKeys': '-createdAt',
  };
  List<Map<String, dynamic>> _sortOpts = [
    { 'value': '-createdAt', 'label': 'Created At (Desc)', },
    { 'value': 'firstName', 'label': 'First Name', },
    { 'value': 'lastName', 'label': 'Last Name', },
  ];

  List<UserClass> _users = [];
  UserClass _selectedUser = UserClass.fromJson({});

  @override
  void initState() {
    super.initState();

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

    _routeIds.add(_socketService.onRoute('HijackLogin', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1 && data.containsKey('user')) {
        Provider.of<CurrentUserState>(context, listen: false).clearUser();
        Provider.of<NeighborhoodState>(context, listen: false).ClearUserNeighborhoods();
        var user = UserClass.fromJson(data['user']);
        Provider.of<CurrentUserState>(context, listen: false).setCurrentUser(user);
        String route = '/user';
        if (data.containsKey('userNeighborhoods')) {
          List<UserNeighborhoodClass> userNeighborhoods = [];
          for (var i = 0; i < data['userNeighborhoods'].length; i++) {
            UserNeighborhoodClass userNeighborhood = UserNeighborhoodClass.fromJson(data['userNeighborhoods'][i]);
            userNeighborhoods.add(userNeighborhood);
            if (userNeighborhood.status == 'default') {
              route = '/n/${userNeighborhood.neighborhood.uName}';
            }
          }
          Provider.of<NeighborhoodState>(context, listen: false).SetUserNeighborhoods(userNeighborhoods);
        }
        context.go(route);
      }
    }));

    var currentUserState = Provider.of<CurrentUserState>(context, listen: false);
    if (!currentUserState.isLoggedIn) {
      Timer(Duration(milliseconds: 500), () {
        context.go('/home');
      });
    } else {
      SearchUsers();
    }
  }

  @override
  void dispose() {
    _socketService.offRouteIds(_routeIds);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var currentUserState = context.watch<CurrentUserState>();
    double fieldWidth = 300;
    List<Widget> colsUsers = [];
    List<Widget> colsForm = [];
    if (_selectedUser.id.length > 0) {
      colsForm = [
        SizedBox(height: 10),
        Text('${_selectedUser.firstName} ${_selectedUser.lastName} (${_selectedUser.username})'),
        SizedBox(height: 10),
        FormSave(formVals: _selectedUser.toJson(), dataName: 'user',
          routeSave: 'SaveUserRole', fieldWidth: fieldWidth,
          formFields: _formFields,
          parseData: (dynamic data) => UserClass.fromJson(data).toJson(),
          preSave: (dynamic data) {
            data['user'] = UserClass.fromJson(data['user']).toJson();
            return data;
          // }, onSave: (dynamic data) {
          },
        ),
        SizedBox(height: 10),
      ];
    } else {
      colsUsers = [
        _layoutService.WrapWidth(_users.map((user) => OneUser(user, context, currentUserState)).toList(),),
        SizedBox(height: 10),
      ];
    }

    return AppScaffoldComponent(
      listWrapper: true,
      // width: fieldWidth,
      body: Column(
        children: [
          _layoutService.WrapWidth([
            _inputFields.inputText(_filters, 'firstName', label: 'First Name', onChanged: (String newVal) {
              SearchUsers();
            }),
            _inputFields.inputText(_filters, 'lastName', label: 'Last Name', onChanged: (String newVal) {
              SearchUsers();
            }),
            _inputFields.inputText(_filters, 'email', label: 'Email', onChanged: (String newVal) {
              SearchUsers();
            }),
            _inputFields.inputSelect(_sortOpts, _filters, 'sortKeys', label: 'Sort By', onChanged: (String newVal) {
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

  Widget OneUser(UserClass user, BuildContext context, CurrentUserState currentUserState) {
    String createdAt = _dateTime.Format(user.createdAt, 'yyyy-MM-dd HH:mm');

    List<Widget> colsEdit = [];
    if (currentUserState.isLoggedIn && currentUserState.currentUser.roles.contains('editUser')) {
      colsEdit += [
        TextButton(child: Text('Edit'), onPressed: () {
          _selectedUser = user;
          setState(() { _selectedUser = _selectedUser; });
        }),
        _style.SpacingH('medium'),
      ];
    }

    if (currentUserState.isLoggedIn && currentUserState.currentUser.roles.contains('hijackUser')) {
      colsEdit += [
        TextButton(child: Text('Hijack'), onPressed: () {
          var data = { 'superUserId': currentUserState.currentUser.id, 'usernameToHijack': user.username };
          _socketService.emit('HijackLogin', data);
        }),
        _style.SpacingH('medium'),
      ];
    }

    Widget content = Column(
      children: [
        _buttons.Link(context, '${user.firstName} ${user.lastName} (${user.username})', '/u/${user.username}'),
        _style.SpacingH('medium'),
        _style.Text1('${user.email}'),
        _style.SpacingH('medium'),
        _style.Text1('${user.roles}'),
        _style.SpacingH('medium'),
        _style.Text1('${createdAt}'),
        _style.SpacingH('medium'),
        ...colsEdit,
      ]
    );
    return content;
  }

  void SearchUsers() {
    _socketService.emit('SearchUsers', _filters);
    setState(() { _selectedUser = UserClass.fromJson({}); });
  }
}
