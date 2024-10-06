import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_scaffold.dart';
import '../../common/socket_service.dart';
import './user_class.dart';
import '../../common/form_input/input_fields.dart';
import '../../common/style.dart';
import './current_user_state.dart';
import '../../routes.dart';

import '../neighborhood/neighborhood_state.dart';
import '../neighborhood/user_neighborhood_class.dart';

class UserLogin extends StatefulWidget {
  bool withScaffold;
  bool redirectOnDone;
  bool withHeaderImage;
  bool withHeader;
  String logInText;
  Function(dynamic)? onSave;
  Function(dynamic)? onShowSignup;
  UserLogin({this.withScaffold = true, this.redirectOnDone = true, this.withHeaderImage = true,
    this.withHeader = true,this.onSave = null, this.onShowSignup = null, this.logInText = 'Log In',});

  @override
  _UserLoginState createState() => _UserLoginState();
}

class _UserLoginState extends State<UserLogin> {
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();
  InputFields _inputFields = InputFields();
  Style _style = Style();

  final _formKey = GlobalKey<FormState>();
  final _formFieldKeyEmail = GlobalKey<FormFieldState>();
  var formVals = {};
  bool _loading = false;
  String _message = '';

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('login', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1 && data.containsKey('user')) {
        UserClass user = UserClass.fromJson(data['user']);
        if (user.id.length > 0) {
          String route = '/home';
          CurrentUserState currentUserState = Provider.of<CurrentUserState>(context, listen: false);
          currentUserState.setCurrentUser(user);
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
          if (widget.onSave != null) {
            widget.onSave!(user.toJson());
          }
          if (widget.redirectOnDone) {
            String redirectUrl = currentUserState.GetRedirectUrl();
            if (redirectUrl.length > 0) {
              route = redirectUrl;
            }
            context.go(route);
          }
        } else {
          setState(() { _message = data['message'].length > 0 ? data['message'] : 'Invalid login, please try again'; });
        }
      } else {
        setState(() { _message = data['message'].length > 0 ? data['message'] : 'Invalid login, please try again'; });
      }
      setState(() { _loading = false; });
    }));

    _routeIds.add(_socketService.onRoute('forgotPassword', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      String message = 'No matching email found.';
      if (data['valid'] == 1) {
        message = 'Check your email to reset your password.';
      }
      setState(() { _message = message; });
      setState(() { _loading = false; });
    }));
  }

  Widget _buildSubmitButtons(BuildContext context) {
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: LinearProgressIndicator(
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: <Widget> [
          ElevatedButton(
            onPressed: () {
              setState(() { _message = ''; });
              if (_formKey.currentState?.validate() == true) {
                setState(() { _loading = true; });
                _formKey.currentState?.save();
                formVals['withUserNeighborhoods'] = 1;
                _socketService.emit('login', formVals);
              } else {
                setState(() { _loading = false; });
              }
            },
            child: Text(widget.logInText),
          ),
          SizedBox(width: 15),
          ElevatedButton(
            onPressed: () {
              setState(() { _message = ''; });
              if (_formFieldKeyEmail.currentState?.validate() == true) {
                setState(() { _loading = true; });
                _formKey.currentState?.save();
                _socketService.emit('forgotPassword', { 'email': formVals['email'] });
              } else {
                setState(() { _loading = false; });
              }
            },
            child: Text('Forgot Password'),
          ),
        ]
      ),
    );
  }

  Widget _buildMessage(BuildContext context) {
    if (_message.length > 0) {
      return Text(_message);
    }
    return SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> colsHeader = [];
    if (widget.withHeaderImage) {
      colsHeader = [
        Image.asset('assets/images/logo.png', width: 30, height: 30),
        SizedBox(width: 10),
      ];
    }
    if (widget.withHeader) {
      colsHeader += [
        _style.Text1('Log In', size: 'large', colorKey: 'primary'),
      ];
    }
    Widget content = Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: [
              ...colsHeader,
            ]
          ),
          _inputFields.inputEmail(formVals, 'email', fieldKey: _formFieldKeyEmail),
          _inputFields.inputPassword(formVals, 'password', minLen: 6),
          _buildSubmitButtons(context),
          _buildMessage(context),
          TextButton(
            onPressed: () {
              if (widget.onShowSignup != null) {
                widget.onShowSignup!({});
              } else {
                context.go(Routes.signup);
              }
            },
            child: Text('No account? Sign up.'),
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