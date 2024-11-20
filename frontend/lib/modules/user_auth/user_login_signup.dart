import 'package:flutter/material.dart';

import './user_class.dart';
import './user_login.dart';
import './user_signup.dart';

class UserLoginSignup extends StatefulWidget {
  Function(Map<String, dynamic>) onSave;
  bool withHeader;
  String mode;
  String logInText;
  String signUpText;
  String firstName;
  String lastName;
  UserLoginSignup({required this.onSave, this.withHeader = true, this.mode = 'login',
  this.logInText = 'Log In', this.signUpText = 'Sign Up', this.firstName = '', this.lastName = ''});

  @override
  _UserLoginSignupState createState() => _UserLoginSignupState();
}

class _UserLoginSignupState extends State<UserLoginSignup> {
  String _mode = 'login';

  @override
  void initState() {
    super.initState();

    _mode = widget.mode;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> cols = [];
    if (_mode == 'login') {
      cols += [
        UserLogin(withScaffold: false, redirectOnDone: false, withHeaderImage: false,
          withHeader: widget.withHeader, logInText: widget.logInText, onSave: (dynamic user) {
          widget.onSave({ 'user': user, 'mode': 'login' });
        }, onShowSignup: (dynamic data) {
          setState(() {
            _mode = 'signup';
          });
        }),
      ];
    } else if (_mode == 'signup') {
      cols += [
        UserSignup(withScaffold: false, redirectOnDone: false, withHeaderImage: false,
          withHeader: widget.withHeader, signUpText: widget.signUpText, firstName: widget.firstName,
          lastName: widget.lastName, onSave: (dynamic user) {
          widget.onSave({ 'user': user, 'mode': 'signup' });
        }, onShowLogin: (dynamic data) {
          setState(() {
            _mode = 'login';
          });
        }),
      ];
    }
    return Container(width: 450,
      child: Column(
        children: [
          ...cols,
        ]
      ),
    );
  }
}