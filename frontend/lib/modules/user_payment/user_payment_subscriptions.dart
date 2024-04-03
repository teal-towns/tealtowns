import 'package:flutter/material.dart';

import '../../common/paging.dart';
import './user_payment_subscription_class.dart';

class UserPaymentSubscriptions extends StatefulWidget {
  @override
  _UserPaymentSubscriptionsState createState() => _UserPaymentSubscriptionsState();
}

class _UserPaymentSubscriptionsState extends State<UserPaymentSubscriptions> {
  List<UserPaymentSubscriptionClass> _userPaymentSubscriptions = [];

  @override
  Widget build(BuildContext context) {
    return Paging(dataName: 'userPaymentSubscriptions', routeGet: 'SearchUserPaymentSubscriptions',
      onGet: (dynamic userPaymentSubscriptions) {
        _userPaymentSubscriptions = [];
        for (var item in userPaymentSubscriptions) {
          _userPaymentSubscriptions.add(UserPaymentSubscriptionClass.fromJson(item));
        }
        setState(() { _userPaymentSubscriptions = _userPaymentSubscriptions; });
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Subscriptions'),
          SizedBox(height: 10,),
          Row(
            children: [
              Expanded(flex: 1, child: Text('Amount')),
              Expanded(flex: 1, child: Text('Frequency')),
              Expanded(flex: 1, child: Text('For')),
              Expanded(flex: 1, child: Text('Status')),
              Expanded(flex: 1, child: Text('Date')),
            ]
          ),
          ..._userPaymentSubscriptions.map((item) => BuildUserPaymentSubscription(item, context) ).toList(),
        ]
      ), 
    );
  }

  Widget BuildUserPaymentSubscription(UserPaymentSubscriptionClass userPaymentSubscription, BuildContext context) {
    return Container(
      child: Row(
        children: [
          Expanded(flex: 1, child: Text('\$${userPaymentSubscription.amountUSD}')),
          Expanded(flex: 1, child: Text('${userPaymentSubscription.recurringInterval}')),
          Expanded(flex: 1, child: Text('${userPaymentSubscription.forType}')),
          Expanded(flex: 1, child: Text('${userPaymentSubscription.status}')),
          Expanded(flex: 1, child: Text('${userPaymentSubscription.createdAt}')),
        ]
      )
    );
  }
}