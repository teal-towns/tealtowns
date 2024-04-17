import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../common/buttons.dart';
import '../../common/paging.dart';
import '../../common/style.dart';
import './user_payment_class.dart';
import '../user_auth/current_user_state.dart';

class UserPayments extends StatefulWidget {
  @override
  _UserPaymentsState createState() => _UserPaymentsState();
}

class _UserPaymentsState extends State<UserPayments> {
  Buttons _buttons = Buttons();
  Style _style = Style();

  List<UserPaymentClass> _userPayments = [];
  Map<String, dynamic> _dataDefault = {
    'stringKeyVals': { 'userId': '', },
  };
  // bool _loading = true;

  @override
  void initState() {
    super.initState();

    if (!Provider.of<CurrentUserState>(context, listen: false).isLoggedIn) {
      Timer(Duration(milliseconds: 500), () {
        context.go('/login');
      });
    } else {
      _dataDefault['stringKeyVals']['userId'] = Provider.of<CurrentUserState>(context, listen: false).currentUser.id;
      // _loading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Paging(dataName: 'userPayments', routeGet: 'SearchUserPayments', itemsPerPage: 25, dataDefault: _dataDefault,
      onGet: (dynamic userPayments) {
        _userPayments = [];
        for (var item in userPayments) {
          _userPayments.add(UserPaymentClass.fromJson(item));
        }
        setState(() { _userPayments = _userPayments; });
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _style.Text1('Payments', size: 'large'),
          SizedBox(height: 10,),
          Row(
            children: [
              Expanded(flex: 1, child: Text('Amount (\$)')),
              Expanded(flex: 1, child: Text('For')),
              Expanded(flex: 1, child: Text('Status')),
              Expanded(flex: 1, child: Text('Date')),
            ]
          ),
          ..._userPayments.map((userPayment) => BuildUserPayment(userPayment, context) ).toList(),
        ]
      ), 
    );
  }

  Widget BuildUserPayment(UserPaymentClass userPayment, BuildContext context) {
    Widget forLink = userPayment.forLink.length > 0 ?
      _buttons.LinkInline(context, '${userPayment.forType}', userPayment.forLink) : Text('${userPayment.forType}');
    String createdAt = DateFormat('M/d/y').format(DateTime.parse(userPayment.createdAt));
    return Container(
      child: Row(
        children: [
          Expanded(flex: 1, child: Text('${userPayment.amountUSDPreFee}')),
          Expanded(flex: 1, child: forLink),
          Expanded(flex: 1, child: Text('${userPayment.status}')),
          Expanded(flex: 1, child: Text('${createdAt}')),
        ]
      )
    );
  }
}