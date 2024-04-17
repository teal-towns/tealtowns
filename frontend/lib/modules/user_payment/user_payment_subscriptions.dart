import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../common/buttons.dart';
import '../../common/paging.dart';
import '../../common/style.dart';
import './user_payment_subscription_class.dart';
import '../user_auth/current_user_state.dart';

class UserPaymentSubscriptions extends StatefulWidget {
  @override
  _UserPaymentSubscriptionsState createState() => _UserPaymentSubscriptionsState();
}

class _UserPaymentSubscriptionsState extends State<UserPaymentSubscriptions> {
  Buttons _buttons = Buttons();
  Style _style = Style();

  List<UserPaymentSubscriptionClass> _userPaymentSubscriptions = [];
  Map<String, dynamic> _dataDefault = {
    'stringKeyVals': { 'userId': '', },
  };

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
    return Paging(dataName: 'userPaymentSubscriptions', routeGet: 'SearchUserPaymentSubscriptions', itemsPerPage: 25,
      dataDefault: _dataDefault,
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
          _style.Text1('Subscriptions', size: 'large'),
          SizedBox(height: 10,),
          Row(
            children: [
              Expanded(flex: 1, child: Text('Amount (\$)')),
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
    Widget forLink = userPaymentSubscription.forLink.length > 0 ?
      _buttons.LinkInline(context, '${userPaymentSubscription.forType}', userPaymentSubscription.forLink) :
      Text('${userPaymentSubscription.forType}');
    String createdAt = DateFormat('M/d/y').format(DateTime.parse(userPaymentSubscription.createdAt));
    return Container(
      child: Row(
        children: [
          Expanded(flex: 1, child: Text('-${userPaymentSubscription.amountUSD}')),
          Expanded(flex: 1, child: Text('${userPaymentSubscription.recurringInterval}')),
          Expanded(flex: 1, child: forLink),
          Expanded(flex: 1, child: Text('${userPaymentSubscription.status}')),
          Expanded(flex: 1, child: Text('${createdAt}')),
        ]
      )
    );
  }
}