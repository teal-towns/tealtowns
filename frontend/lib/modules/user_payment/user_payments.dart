import 'package:flutter/material.dart';

import '../../common/paging.dart';
import './user_payment_class.dart';

class UserPayments extends StatefulWidget {
  @override
  _UserPaymentsState createState() => _UserPaymentsState();
}

class _UserPaymentsState extends State<UserPayments> {
  List<UserPaymentClass> _userPayments = [];

  @override
  Widget build(BuildContext context) {
    return Paging(dataName: 'userPayments', routeGet: 'SearchUserPayments',
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
          Text('Payments'),
          SizedBox(height: 10,),
          Row(
            children: [
              Expanded(flex: 1, child: Text('Amount')),
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
    return Container(
      child: Row(
        children: [
          Expanded(flex: 1, child: Text('\$${userPayment.amountUSD}')),
          Expanded(flex: 1, child: Text('${userPayment.forType}')),
          Expanded(flex: 1, child: Text('${userPayment.status}')),
          Expanded(flex: 1, child: Text('${userPayment.createdAt}')),
        ]
      )
    );
  }
}