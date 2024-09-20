import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_scaffold.dart';
import '../../common/ip_service.dart';
import '../../common/socket_service.dart';
import './user_class.dart';
import '../../common/form_input/input_fields.dart';
import '../../common/style.dart';
import './current_user_state.dart';
import '../../routes.dart';

class UserSignup extends StatefulWidget {
  bool withScaffold;
  bool redirectOnDone;
  Function(dynamic)? onSave;
  UserSignup({this.withScaffold = true, this.redirectOnDone = true, this.onSave = null});

  @override
  _UserSignupState createState() => _UserSignupState();
}

class _UserSignupState extends State<UserSignup> {
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();
  InputFields _inputFields = InputFields();
  IPService _ipService = IPService();
  Style _style = Style();

  final _formKey = GlobalKey<FormState>();
  var formVals = {};
  bool _loading = false;
  String _message = '';
  bool _loadingIP = true;
  bool _initedIP = false;

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('signup', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        // Email verification skipped, so already are auto logged in.
        if (data.containsKey('user')) {
          var user = UserClass.fromJson(data['user']);
          CurrentUserState currentUserState = Provider.of<CurrentUserState>(context, listen: false);
          if (user.id.length > 0) {
            currentUserState.setCurrentUser(user);
            if (widget.onSave != null) {
              widget.onSave!(user);
            }
            if (widget.redirectOnDone) {
              // String route = '/home';
              String route = '/interests';
              String redirectUrl = currentUserState.GetRedirectUrl();
              if (redirectUrl.length > 0) {
                // currentUserState.AddRouterRedirectUrl(route);
                route = redirectUrl;
              }
              context.go(route);
            }
          } else {
            setState(() { _message = 'Error, please try again.'; });
          }
        } else {
          setState(() { _message = 'Check your email to verify and get started! Check your SPAM folder if you do not see the email within a few minutes.'; });
        }
      } else {
        setState(() { _message = data['message'].length > 0 ? data['message'] : 'Invalid fields, please try again'; });
      }
      setState(() { _loading = false; });
    }));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init();
    });
  }

  Widget _buildSubmit(BuildContext context) {
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        //child: Text('Loading'),
        child: LinearProgressIndicator(
          //backgroundColor: Colors.grey,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: ElevatedButton(
        onPressed: () {
          setState(() { _message = ''; });
          if (_formKey.currentState?.validate() == true) {
            setState(() { _loading = true; });
            _formKey.currentState?.save();
            formVals['roles'] = [''];
            _socketService.emit('signup', formVals);
          } else {
            setState(() { _loading = false; });
          }
        },
        child: Text('Start my TealTown!'),
      ),
    );
  }

  Widget _buildMessage(BuildContext context) {
    if (_message.length > 0) {
      return Text(_message);
    }
    return Container();
  }

  void _init() async {
    await _ipService.GetIPAddress();
    setState(() { _loadingIP = false; });
  }

  @override
  Widget build(BuildContext context) {
    var currentUserState = Provider.of<CurrentUserState>(context, listen: false);
    if (!_initedIP && (_ipService.IsLoaded() || currentUserState.isLoggedIn)) {
      _initedIP = true;
      _loadingIP = false;
      var data = {
        'fieldKey': 'signUpUniqueViewsAt',
        'userOrIP': currentUserState.isLoggedIn ? 'user_' + currentUserState.currentUser.id : _ipService.IP(),
      };
      _socketService.emit('AddAppInsightView', data);
    }

    Widget content = Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: [
              Image.asset('assets/images/logo.png', width: 30, height: 30),
              SizedBox(width: 10),
              _style.Text1('Registration', size: 'large', colorKey: 'primary'),
            ]
          ),
          _inputFields.inputEmail(formVals, 'email'),
          _inputFields.inputPassword(formVals, 'password', minLen: 6),
          _inputFields.inputText(formVals, 'firstName', minLen: 2, label: 'First Name'),
          _inputFields.inputText(formVals, 'lastName', minLen: 2, label: 'Last Name'),
          _buildSubmit(context),
          _buildMessage(context),
          TextButton(
            onPressed: () {
              context.go(Routes.login);
            },
            child: Text('Already have an account? Log in.'),
          ),
        ]
      ),
    );
    if (!widget.withScaffold) {
      return content;
    }
    return AppScaffoldComponent(
      listWrapper: true,
      width: 600,
      body: content,
    );
  }

  @override
  void dispose() {
    _socketService.offRouteIds(_routeIds);
    super.dispose();
  }
}