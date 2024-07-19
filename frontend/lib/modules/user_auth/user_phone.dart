import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter/gestures.dart';

import '../../common/buttons.dart';
import '../../common/link_service.dart';
import '../../common/socket_service.dart';
import './user_class.dart';
import '../../common/form_input/input_fields.dart';
import './current_user_state.dart';

class UserPhone extends StatefulWidget {
  @override
  _UserPhoneState createState() => _UserPhoneState();
}

class _UserPhoneState extends State<UserPhone> {
  Buttons _buttons = Buttons();
  InputFields _inputFields = InputFields();
  LinkService _linkService = LinkService();
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();

  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> _formVals = {
    'phoneNumber': '',
    'phoneNumberVerificationKey': '',
    'whatsappNumber': '',
    'whatsappNumberVerificationKey': '',
    'terms': false,
    'mode': 'whatsapp',
  };
  bool _loading = false;
  String _message = '';
  bool _verificationSent = false;
  Map<String, Map<String, String>> _fieldsByMode = {
    'sms': {
      'number': 'phoneNumber',
      'verificationKey': 'phoneNumberVerificationKey',
    },
    'whatsapp': {
      'number': 'whatsappNumber',
      'verificationKey': 'whatsappNumberVerificationKey',
    },
  };

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('SendPhoneVerificationCode', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        _message = data['message'];
        var user = UserClass.fromJson(data['user']);
        Provider.of<CurrentUserState>(context, listen: false).setCurrentUser(user, skipSession: true);
        if (_formVals['mode'] == 'sms') {
          _formVals['phoneNumberVerificationKey'] = '';
          _formVals['phoneNumber'] = data['phoneNumber'];
        } else if (_formVals['mode'] == 'whatsapp') {
          _formVals['whatsappNumberVerificationKey'] = '';
          _formVals['whatsappNumber'] = data['whatsappNumber'];
        }
        _formVals['terms'] = true;
        String phoneField = _formVals['mode'] == 'sms' ? 'phoneNumber' : 'whatsappNumber';
        if (_formVals[phoneField]!.length > 0) {
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
        String field = _formVals['mode'] == 'sms' ? 'phoneNumberVerificationKey' : 'whatsappNumberVerificationKey';
        _formVals[field] = '';
        setState(() { _message = 'Phone successfully verified'; });
      } else {
        setState(() { _message = data['message'].length > 0 ? data['message'] : 'Invalid verification key, please try again.'; });
      }
      setState(() { _loading = false; });
    }));

    UserClass user = Provider.of<CurrentUserState>(context, listen: false).currentUser;
    _formVals['phoneNumber'] = user.phoneNumber;
    _formVals['whatsappNumber'] = user.whatsappNumber;
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

    String fieldNumber = _fieldsByMode[_formVals['mode']]!['number']!;
    String fieldVerificationKey = _fieldsByMode[_formVals['mode']]!['verificationKey']!;
    String buttonText = (_formVals[fieldVerificationKey]!.length > 0 || _verificationSent) ? 'Verify Phone' : 'Send Verification Code';
    List<Widget> buttons = [
      ElevatedButton(
        onPressed: () {
          setState(() { _message = ''; });
          if (_formKey.currentState?.validate() == true && _formVals['terms'] == true) {
            setState(() { _loading = true; });
            _formKey.currentState?.save();
            if (_formVals[fieldVerificationKey]!.length > 0) {
              var data = {
                'userId': Provider.of<CurrentUserState>(context, listen: false).currentUser.id,
                'mode': _formVals['mode'],
              };
              data[fieldVerificationKey] = _formVals[fieldVerificationKey];
              _socketService.emit('VerifyPhone', data);
            } else if (_formVals['phoneNumber']!.length >= 8) {
              var data = {
                'userId': Provider.of<CurrentUserState>(context, listen: false).currentUser.id,
                'mode': _formVals['mode'],
              };
              data[fieldNumber] = _formVals[fieldNumber];
              _socketService.emit('SendPhoneVerificationCode', data);
            }
          } else {
            setState(() { _loading = false; _message = "Please fill out all fields."; });
          }
        },
        child: Text(buttonText),
      )
    ];

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
    String fieldNumber = _fieldsByMode[_formVals['mode']]!['number']!;
    String fieldVerificationKey = _fieldsByMode[_formVals['mode']]!['verificationKey']!;
    if (_formVals[fieldNumber]!.length > 8 && _verificationSent) {
      widgetVerificationKey = Container(width: width, child: _inputFields.inputText(_formVals, fieldVerificationKey, minLen: 2, label: 'Verification Key'));
    }
    RegExp pattern = new RegExp(r'^[0-9]*$');
    List<Map<String, dynamic>> optsMode = [
      {'value': 'sms', 'label': 'SMS'},
      {'value': 'whatsapp', 'label': 'WhatsApp'},
    ];

    var currentUserState = context.watch<CurrentUserState>();
    bool verified = false;
    if ((_formVals['mode'] == 'sms' && currentUserState.currentUser.phoneNumberVerified > 0) ||
      (_formVals['mode'] == 'whatsapp' && currentUserState.currentUser.whatsappNumberVerified > 0)) {
      verified = true;
    }
    List<Widget> cols = [];
    if (!verified) {
      cols += [
        Container(width: width, child: _inputFields.inputText(_formVals, fieldNumber,
          label: 'Phone Number, with country code', hint: '15551234567',
          pattern: pattern, minLen: 8, maxLen: 15,)),
        Container(width: width, child: _inputFields.inputCheckbox(_formVals, 'terms',
          label: 'I agree to receive text messages from TealTowns. Consent is not a condition of purchase. Message and data rates may apply. Message frequency varies. Unsubscribe at any time by clicking the unsubscribe link (where available).',
          onChanged: (bool val) {
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
                _linkService.LaunchURL('/privacy-policy');
              },
            ),
            TextSpan(
              text: ' | ',
            ),
            TextSpan(
              text: 'Terms of Service',
              style: TextStyle(color: Colors.blue),
              recognizer: TapGestureRecognizer()..onTap = () {
                _linkService.LaunchURL('/terms-of-service');
              },
            ),
          ]
        )),
      ];
    } else {
      cols += [
        SizedBox(height: 10),
        Text("${_formVals[fieldNumber]}"),
        SizedBox(height: 10),
        TextButton(
          onPressed: () {
            setState(() { _message = ''; _loading = true; });
            var data = {
              'userId': Provider.of<CurrentUserState>(context, listen: false).currentUser.id,
              'mode': _formVals['mode'],
            };
            data[fieldNumber] = '';
            _socketService.emit('SendPhoneVerificationCode', data);
          },
          child: Text('Remove Phone'),
        ),
      ];
    }

    return Container(
      width: 750,
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(width: width, child: _inputFields.inputSelectButtons(optsMode, _formVals, 'mode', onChanged: (val) {
              _formVals['mode'] = val;
              setState(() { _formVals = _formVals; });
            })),
            ...cols,
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