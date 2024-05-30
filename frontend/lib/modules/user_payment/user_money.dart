import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_scaffold.dart';
import '../../common/currency_service.dart';
import '../../common/parse_service.dart';
import '../../common/socket_service.dart';
import '../user_auth/current_user_state.dart';
import './user_money_class.dart';
import './user_payment_class.dart';
import './user_payout.dart';
import './user_payments.dart';
import './user_payment_subscriptions.dart';

class UserMoney extends StatefulWidget {
  @override
  _UserMoneyState createState() => _UserMoneyState();
}

class _UserMoneyState extends State<UserMoney> {
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();
  CurrencyService _currency = CurrencyService();
  ParseService _parseService = ParseService();

  UserMoneyClass _userMoney = UserMoneyClass.fromJson({});
  List<UserPaymentClass> _userPayments = [];
  double _availableUSD = 0;
  bool _loading = false;
  String _message = '';

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('GetUserMoneyAndPending', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        _userMoney = UserMoneyClass.fromJson(data['userMoney']);
        _userPayments = [];
        for (var userPayment in data['userPayments']) {
          _userPayments.add(UserPaymentClass.fromJson(userPayment));
        }
        _availableUSD = _parseService.toDoubleNoNull(data['availableUSD']);
      } else {
        _message = data['message'].length > 0 ? data['message'] : 'Error.';
      }
      setState(() {
        _loading = false;
      });
    }));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init();
    });
  }

  @override
  void dispose() {
    _socketService.offRouteIds(_routeIds);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffoldComponent(
      listWrapper: true,
      innerWidth: 900,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${_currency.Format(_availableUSD, 'USD')} available'),
          // TODO - display (pending) payments
          SizedBox(height: 10),
          UserPayout(),
          SizedBox(height: 10),
          UserPaymentSubscriptions(),
          SizedBox(height: 10),
          UserPayments(),
          SizedBox(height: 10),
        ]
      ),
    );
  }

  void _init() async {
    GetUserMoney();
  }

  void GetUserMoney() {
    var data = {
      'userId': Provider.of<CurrentUserState>(context, listen: false).currentUser.id,
    };
    _socketService.emit('GetUserMoneyAndPending', data);
  }
}