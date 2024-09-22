import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/form_input/input_fields.dart';
import '../../common/link_service.dart';
import '../../common/parse_service.dart';
import '../../common/socket_service.dart';
import '../user_auth/current_user_state.dart';

class UserPayout extends StatefulWidget {
  @override
  _UserPayoutState createState() => _UserPayoutState();
}

class _UserPayoutState extends State<UserPayout> {
  List<String> _routeIds = [];
  InputFields _inputFields = InputFields();
  LinkService _linkService = LinkService();
  SocketService _socketService = SocketService();
  ParseService _parseService = ParseService();

  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> _formVals = {
    'amountUSD': 0,
  };

  Map<String, dynamic> _userStripeAccount = {};
  bool _loading = false;
  String _message = '';

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('GetUserStripeAccount', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        _userStripeAccount = data['userStripeAccount'];
        setState(() { _userStripeAccount = _userStripeAccount; });
      } else {
        _message = data['message'].length > 0 ? data['message'] : 'Error.';
      }
      setState(() {
        _loading = false;
      });
    }));

    _routeIds.add(_socketService.onRoute('GetStripeAccountLink', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        if (data.containsKey('userStripeAccount') && data['userStripeAccount']['status'] == 'complete') {
          _userStripeAccount = data['userStripeAccount'];
          setState(() { _userStripeAccount = _userStripeAccount; });
        } else {
          _linkService.LaunchURL(data['url']);
        }
      } else {
        setState(() { _message = data['message'].length > 0 ? data['message'] : 'Error, please try again.'; });
        setState(() { _loading = false; });
      }
    }));

    // _routeIds.add(_socketService.onRoute('StripeAccountUpdated', callback: (String resString) {
    //   var res = jsonDecode(resString);
    //   var data = res['data'];
    //   String userId = Provider.of<CurrentUserState>(context, listen: false).currentUser.id;
    //   if (data.containsKey('userId') && data['userId'] == userId) {
    //     if (data.containsKey['userStripeAccount']) {
    //       _userStripeAccount = data['userStripeAccount'];
    //       setState(() { _userStripeAccount = _userStripeAccount; });
    //     }
    //   }
    //   setState(() { _loading = false; });
    // }));

    _routeIds.add(_socketService.onRoute('StripeWithdrawMoney', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
      } else {
        _message = data['message'].length > 0 ? data['message'] : 'Error.';
      }
      setState(() {
        _loading = false;
      });
    }));
  }

  @override
  void dispose() {
    _socketService.offRouteIds(_routeIds);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: LinearProgressIndicator(),
      );
    }

    double fieldWidth = 250;
    List<Widget> cols = [];
    if (_userStripeAccount.containsKey('status') && _userStripeAccount['status'] == 'complete') {
      cols += [
        Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(width: fieldWidth, child: _inputFields.inputNumber(_formVals, 'amountUSD',)),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  setState(() { _loading = true; });
                  var data = {
                    'userId': Provider.of<CurrentUserState>(context, listen: false).currentUser.id,
                    'amountUSD': _formVals['amountUSD'],
                  };
                  _socketService.emit('StripeWithdrawMoney', data);
                },
                child: Text('Withdraw Money'),
              ),
            ],
          ),
        ),
      ];
    } else {
      cols += [
        ElevatedButton(
          onPressed: () {
            setState(() { _loading = true; });
            var data = {
              'userId': Provider.of<CurrentUserState>(context, listen: false).currentUser.id,
            };
            _socketService.emit('GetStripeAccountLink', data);
          },
          child: Text('Add Bank Account'),
        ),
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...cols,
        SizedBox(height: 10),
        Text(_message),
      ]
    );
  }

  void GetUserStripeAccount() {
    var data = {
      'userId': Provider.of<CurrentUserState>(context, listen: false).currentUser.id,
    };
    _socketService.emit('GetUserStripeAccount', data);
  }
}