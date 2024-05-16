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

class UserEmailVerifyComponent extends StatefulWidget {
  @override
  _UserEmailVerifyState createState() => _UserEmailVerifyState();
}

class _UserEmailVerifyState extends State<UserEmailVerifyComponent> {
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();
  InputFields _inputFields = InputFields();

  final _formKey = GlobalKey<FormState>();
  var formVals = {};
  bool _loading = false;
  String _message = '';

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('emailVerify', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        if (data.containsKey('user')) {
          var user = UserClass.fromJson(data['user']);
          if (user.id.length > 0) {
            Provider.of<CurrentUserState>(context, listen: false).setCurrentUser(user);
            String route = '/home';
            String redirectUrl = Provider.of<CurrentUserState>(context, listen: false).redirectUrl;
            if (redirectUrl.length > 0) {
              route = redirectUrl;
              Provider.of<CurrentUserState>(context, listen: false).SetRedirectUrl('');
            }
            context.go(route);
          } else {
            setState(() { _message = 'Error, please try again.'; });
          }
        } else {
          setState(() { _message = 'Error, please try again.'; });
        }
      } else {
        setState(() { _message = data['message'].length > 0 ? data['message'] : 'Invalid key, please check your email and try again.'; });
      }
      setState(() { _loading = false; });
    }));
  }

  Widget _buildSubmit(BuildContext context) {
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: LinearProgressIndicator(
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: ElevatedButton(
        onPressed: () {
          setState(() { _message = ''; });
          //bool valid = (_formKey.currentState?.validate() != null) ? _formKey.currentState?.validate() : false;
          if (_formKey.currentState?.validate() == true) {
            setState(() { _loading = true; });
            _formKey.currentState?.save();
            _socketService.emit('emailVerify', formVals);
          } else {
            setState(() { _loading = false; });
          }
        },
        child: Text('Verify Email'),
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
                    _inputFields.inputEmail(formVals, 'email'),
                    _inputFields.inputText(formVals, 'emailVerificationKey', minLen: 2, label: 'Verification Key'),
                    _buildSubmit(context),
                    _buildMessage(context),
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