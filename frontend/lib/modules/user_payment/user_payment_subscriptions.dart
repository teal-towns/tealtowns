import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../common/buttons.dart';
import '../../common/date_time_service.dart';
import '../../common/link_service.dart';
import '../../common/paging.dart';
import '../../common/socket_service.dart';
import '../../common/style.dart';
import './user_payment_subscription_class.dart';
import '../user_auth/current_user_state.dart';

class UserPaymentSubscriptions extends StatefulWidget {
  @override
  _UserPaymentSubscriptionsState createState() => _UserPaymentSubscriptionsState();
}

class _UserPaymentSubscriptionsState extends State<UserPaymentSubscriptions> {
  Buttons _buttons = Buttons();
  DateTimeService _dateTime = DateTimeService();
  LinkService _linkService = LinkService();
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();
  Style _style = Style();

  List<UserPaymentSubscriptionClass> _userPaymentSubscriptions = [];
  Map<String, dynamic> _dataDefault = {
    'stringKeyVals': { 'userId': '', },
  };
  bool _loading = false;

  @override
  void initState() {
    super.initState();

    CurrentUserState currentUserState = Provider.of<CurrentUserState>(context, listen: false);
    if (!currentUserState.isLoggedIn) {
      Timer(Duration(milliseconds: 500), () {
        _linkService.Go('', context, currentUserState: currentUserState);
      });
    } else {
      _dataDefault['stringKeyVals']['userId'] = Provider.of<CurrentUserState>(context, listen: false).currentUser.id;
      // _loading = false;

      _routeIds.add(_socketService.onRoute('CancelUserPaymentSubscription', callback: (String resString) {
        var res = jsonDecode(resString);
        var data = res['data'];
        if (data['valid'] == 1) {
          setState(() { _loading = false; });
        }
      }));
    }
  }

  @override
  void dispose() {
    _socketService.offRouteIds(_routeIds);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Column(children: [ LinearProgressIndicator() ]);
    }
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
    String createdAt = _dateTime.Format(userPaymentSubscription.createdAt, 'M/d/y');
    Widget status = Text('${userPaymentSubscription.status}');
    if (userPaymentSubscription.status == 'complete') {
      status = Row(
        children: [
          Text('${userPaymentSubscription.status} '),
          InkWell(child: Text('Cancel', style: TextStyle( color: Theme.of(context).primaryColor )),
          onTap: () {
            _socketService.emit('CancelUserPaymentSubscription', { 'userPaymentSubscriptionId': userPaymentSubscription.id });
            setState(() { _loading = true; });
          }),
        ]
      );
    } else if (userPaymentSubscription.status == 'canceled') {
      status = Text('${userPaymentSubscription.status} (${userPaymentSubscription.credits} credits)');
    }
    return Container(
      child: Row(
        children: [
          Expanded(flex: 1, child: Text('-${userPaymentSubscription.amountUSD}')),
          Expanded(flex: 1, child: Text('${userPaymentSubscription.recurringInterval}')),
          Expanded(flex: 1, child: forLink),
          Expanded(flex: 1, child: status),
          Expanded(flex: 1, child: Text('${createdAt}')),
        ]
      )
    );
  }
}