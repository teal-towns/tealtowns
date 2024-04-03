import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_scaffold.dart';
import '../../common/socket_service.dart';
import './user_class.dart';
import '../../common/form_input/input_fields.dart';
import './current_user_state.dart';
import '../../routes.dart';

class UserLoginComponent extends StatefulWidget {
  @override
  _UserLoginState createState() => _UserLoginState();
}

class _UserLoginState extends State<UserLoginComponent> {
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();
  InputFields _inputFields = InputFields();

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
        var user = UserClass.fromJson(data['user']);
        if (user.id.length > 0) {
          Provider.of<CurrentUserState>(context, listen: false).setCurrentUser(user);
          context.go(Routes.home);
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
                _socketService.emit('login', formVals);
              } else {
                setState(() { _loading = false; });
              }
            },
            child: Text('Log In'),
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
    return AppScaffoldComponent(
      body: ListView(
        children: [
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 600,
              padding: const EdgeInsets.only(top: 20, left: 10, right: 10),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _inputFields.inputEmail(formVals, 'email', fieldKey: _formFieldKeyEmail),
                    _inputFields.inputPassword(formVals, 'password', minLen: 6),
                    _buildSubmitButtons(context),
                    _buildMessage(context),
                    TextButton(
                      onPressed: () {
                        context.go(Routes.signup);
                      },
                      child: Text('No account? Sign up.'),
                    ),
                  ]
                ),
              ),
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