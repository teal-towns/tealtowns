import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter/gestures.dart';

import '../../common/buttons.dart';
import '../../common/socket_service.dart';
import './user_class.dart';
import '../../common/form_input/input_fields.dart';
import './current_user_state.dart';

class UserPhone extends StatefulWidget {
  @override
  _UserPhoneState createState() => _UserPhoneState();
}

class _UserPhoneState extends State<UserPhone> {
  List<String> _routeIds = [];
  Buttons _buttons = Buttons();
  SocketService _socketService = SocketService();
  InputFields _inputFields = InputFields();

  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> _formVals = {
    'phoneNumber': '',
    'phoneNumberVerificationKey': '',
    'terms': false,
  };
  bool _loading = false;
  String _message = '';
  bool _verificationSent = false;

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('SendPhoneVerificationCode', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        _message = data['message'];
        _formVals['phoneNumberVerificationKey'] = '';
        _formVals['phoneNumber'] = data['phoneNumber'];
        _formVals['terms'] = true;
        if (_formVals['phoneNumber']!.length > 0) {
          _verificationSent = true;
        } else {
          _verificationSent = false;
        }
        setState(() { _verificationSent = _verificationSent; _formVals = _formVals; _message = _message; });
      } else {
        setState(() { _message = data['message'].length > 0 ? data['message'] : 'Invalid number, please try again.'; });
      }
      setState(() { _loading = false; });
    }));

    _routeIds.add(_socketService.onRoute('VerifyPhone', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        var user = UserClass.fromJson(data['user']);
        Provider.of<CurrentUserState>(context, listen: false).setCurrentUser(user, skipSession: true);
        _formVals['phoneNumberVerificationKey'] = '';
        setState(() { _message = 'Phone successfully verified'; });
      } else {
        setState(() { _message = data['message'].length > 0 ? data['message'] : 'Invalid verification key, please try again.'; });
      }
      setState(() { _loading = false; });
    }));

    UserClass user = Provider.of<CurrentUserState>(context, listen: false).currentUser;
    _formVals['phoneNumber'] = user.phoneNumber;
    setState(() { _formVals = _formVals; });
  }

  Widget _buildSubmit(BuildContext context) {
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: LinearProgressIndicator(
        ),
      );
    }

    String buttonText = (_formVals['phoneNumberVerificationKey']!.length > 0 || _verificationSent) ? 'Verify Phone' : 'Send Verification Code';
    List<Widget> buttons = [
      ElevatedButton(
        onPressed: () {
          setState(() { _message = ''; });
          if (_formKey.currentState?.validate() == true && _formVals['terms'] == true) {
            setState(() { _loading = true; });
            _formKey.currentState?.save();
            if (_formVals['phoneNumberVerificationKey']!.length > 0) {
              var data = {
                'userId': Provider.of<CurrentUserState>(context, listen: false).currentUser.id,
                'phoneNumberVerificationKey': _formVals['phoneNumberVerificationKey'],
              };
              _socketService.emit('VerifyPhone', data);
            } else if (_formVals['phoneNumber']!.length >= 8) {
              var data = {
                'userId': Provider.of<CurrentUserState>(context, listen: false).currentUser.id,
                'phoneNumber': _formVals['phoneNumber'],
              };
              _socketService.emit('SendPhoneVerificationCode', data);
            }
          } else {
            setState(() { _loading = false; _message = "Please fill out all fields."; });
          }
        },
        child: Text(buttonText),
      )
    ];
    if (Provider.of<CurrentUserState>(context, listen: false).currentUser.phoneNumberVerified > 0) {
      buttons.add(SizedBox(width: 10));
      buttons.add(TextButton(
        onPressed: () {
          setState(() { _message = ''; _loading = true; });
          var data = {
            'userId': Provider.of<CurrentUserState>(context, listen: false).currentUser.id,
            'phoneNumber': '',
          };
          _socketService.emit('SendPhoneVerificationCode', data);
        },
        child: Text('Remove Phone'),
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: buttons
      ),
    );
  }

  Widget _buildMessage(BuildContext context) {
    if (_message.length > 0) {
      return Text(_message);
    }
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    double width = 500;
    Widget widgetVerificationKey = SizedBox.shrink();
    if (_formVals['phoneNumber']!.length > 8 && _verificationSent) {
      widgetVerificationKey = Container(width: width, child: _inputFields.inputText(_formVals, 'phoneNumberVerificationKey', minLen: 2, label: 'Verification Key'));
    }
    RegExp pattern = new RegExp(r'^[0-9]*$');
    return Container(
      width: 750,
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(width: width, child: _inputFields.inputText(_formVals, 'phoneNumber',
              label: 'Phone Number, with country code', hint: '15551234567',
              pattern: pattern, minLen: 8, maxLen: 15,)),
            Container(width: width, child: _inputFields.inputCheckbox(_formVals, 'terms',
              label: 'I agree to receive text messages from TealTowns. Consent is not a condition of purchase. Message and data rates may apply. Message frequency varies. Unsubscribe at any time by clicking the unsubscribe link (where available).',
              onChange: (bool val) {
                _formVals['terms'] = val;
                setState(() { _formVals = _formVals; });
              },
            )),
            widgetVerificationKey,
            _buildSubmit(context),
            _buildMessage(context),
            SizedBox(height: 10),
            RichText( text: TextSpan(
              children: [
                // TextSpan(
                //   text: 'I agree to receive text messages from TealTowns. Consent is not a condition of purchase. Message and data rates may apply. Message frequency varies. Unsubscribe at any time by clicking the unsubscribe link (where available). ',
                // ),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(color: Colors.blue),
                  recognizer: TapGestureRecognizer()..onTap = () {
                    context.go('/privacy-policy');
                  },
                ),
                TextSpan(
                  text: ' | ',
                ),
                TextSpan(
                  text: 'Terms of Service',
                  style: TextStyle(color: Colors.blue),
                  recognizer: TapGestureRecognizer()..onTap = () {
                    context.go('/terms-of-service');
                  },
                ),
              ]
            )),
          ]
        ),
      )
    );
  }

  @override
  void dispose() {
    _socketService.offRouteIds(_routeIds);
    super.dispose();
  }
}