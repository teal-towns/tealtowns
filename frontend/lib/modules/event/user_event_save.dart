import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../common/form_input/input_fields.dart';
import '../../common/layout_service.dart';
import '../../common/link_service.dart';
import '../../common/socket_service.dart';
import './user_event_class.dart';
import './event_class.dart';
import './weekly_event_class.dart';
import '../user_auth/current_user_state.dart';

class UserEventSave extends StatefulWidget {
  String eventId;
  UserEventSave({this.eventId = '',});

  @override
  _UserEventSaveState createState() => _UserEventSaveState();
}

class _UserEventSaveState extends State<UserEventSave> {
  List<String> _routeIds = [];
  LayoutService _layoutService = LayoutService();
  LinkService _linkService = LinkService();
  SocketService _socketService = SocketService();
  InputFields _inputFields = InputFields();

  bool _loading = true;
  String _message = '';
  Map<String, dynamic> _formVals = UserEventClass.fromJson({}).toJson();
  UserEventClass _userEvent = UserEventClass.fromJson({});
  EventClass _event = EventClass.fromJson({});
  WeeklyEventClass _weeklyEvent = WeeklyEventClass.fromJson({});
  bool _inited = false;
  final _formKey = GlobalKey<FormState>();
  int _spotsPaidFor = 0;
  double _availableUSD = 0;
  double _availableCredits = 0;
  bool _loadingPayment = false;

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('GetUserEvent', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        _userEvent = UserEventClass.fromJson(data['userEvent']);
        _formVals = _userEvent.toJson();
        if (_formVals['_id'].length < 1) {
          _formVals['eventId'] = widget.eventId;
          _formVals['userId'] = Provider.of<CurrentUserState>(context, listen: false).currentUser.id;
        }
        setState(() { _formVals = _formVals; _userEvent = _userEvent; });
        if (data.containsKey('event')) {
          _event = EventClass.fromJson(data['event']);
          setState(() { _formVals = _formVals; });
        }
        if (data.containsKey('userCheckPayment')) {
            setState(() {
              _spotsPaidFor = data['userCheckPayment']['spotsPaidFor'];
              _availableUSD = data['userCheckPayment']['availableUSD'];
              _availableCredits = data['userCheckPayment']['availableCredits'];
              _weeklyEvent = WeeklyEventClass.fromJson(data['userCheckPayment']['weeklyEvent']);
            });
        }
      }
      setState(() { _loading = false; _loadingPayment = false; });
    }));

    _routeIds.add(_socketService.onRoute('StripeGetPaymentLink', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        _linkService.LaunchURL(data['url']);
      } else {
        setState(() { _message = data['message'].length > 0 ? data['message'] : 'Error, please try again.'; });
      }
      setState(() { _loading = false; });
    }));

    _routeIds.add(_socketService.onRoute('StripePaymentComplete', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data.containsKey('forId') && data['forId'] == _event.id &&
        data.containsKey('forType') && data['forType'] == 'event') {
        _socketService.emit('SaveUserEvent', { 'userEvent': _formVals, 'payType': 'paid' });
      }
    }));

    _routeIds.add(_socketService.onRoute('SaveUserEvent', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        context.go('/eat');
      }
    }));
  }

  @override
  void dispose() {
    _socketService.offRouteIds(_routeIds);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var currentUserState = context.watch<CurrentUserState>();
    if (!currentUserState.isLoggedIn) {
      return ElevatedButton(
        onPressed: () {
          context.go('/login');
        },
        child: Text('Join Event'),
      );
    }
    if (!_inited && widget.eventId.length > 0) {
      _inited = true;
      GetUserEvent();
    }

    if (_loading) {
      List<Widget> cols = [];
      if (_loadingPayment) {
        cols += [
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              GetUserEvent();
            },
            child: Text('Refresh Once Payment Is Made'),
          )
        ];
      }
      return Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10.0),
            child: LinearProgressIndicator(),
          ),
          ...cols,
        ]
      );
    }

    String hostLabel = 'How many people will you host? Earn 1 free event per ${_weeklyEvent.hostGroupSizeDefault} people.';
    Widget widgetHost = _inputFields.inputNumber(_formVals, 'hostGroupSizeMax', required: true, label: hostLabel,);
    // Do not allow changing if already complete and have a host group.
    if (_userEvent.id.length > 0 && _userEvent.hostStatus == 'complete' && _userEvent.hostGroupSize > 0) {
      widgetHost = SizedBox.shrink();
    }
    double attendeeMin = _userEvent.attendeeCount > 0 ? _userEvent.attendeeCount.toDouble() : 1;

    List<Widget> colsCreditsMoney = [];
    if (_availableUSD >= _weeklyEvent.priceUSD || _availableCredits >= 1) {
      String text = '';
      if (_availableCredits >= 1) {
        text += 'You have ${_availableCredits.toStringAsFixed(2)} credits. ';
      }
      if (_availableUSD >= _weeklyEvent.priceUSD) {
        text += 'You have \$${_availableUSD.toStringAsFixed(2)}. ';
      }
      colsCreditsMoney = [
        Text(text),
        SizedBox(height: 10),
      ];
    }

    bool alreadySignedUp = false;

    List<Widget> attendeeInfo = [
      // Text('${_attendeesCount} attending, ${_nonHostAttendeesWaitingCount} waiting'),
      // SizedBox(height: 10),
    ];
    if (_userEvent.attendeeCountAsk > 0) {
      alreadySignedUp = true;
      if (_userEvent.attendeeCount > 0) {
        int guestsGoing = _userEvent.attendeeCount - 1;
        int guestsWaiting = _userEvent.attendeeCountAsk - _userEvent.attendeeCount - 1;
        String text1 = 'You are going';
        if (guestsGoing > 0) {
          text1 += ', with ${guestsGoing} guests';
        }
        if (guestsWaiting > 0) {
          text1 += ', waiting on ${guestsWaiting} more spots';
        }
        attendeeInfo += [
          Text(text1),
          SizedBox(height: 10),
        ];
      } else {
        attendeeInfo += [
          Text('You are waiting on ${_userEvent.attendeeCountAsk} more spots.'),
          SizedBox(height: 10),
        ];
      }
      if (_userEvent.creditsEarned > 0 || _userEvent.creditsRedeemed > 0) {
        String text1 = '';
        if (_userEvent.creditsEarned > 0) {
          text1 += '${_userEvent.creditsEarned} credits earned. ';
        }
        if (_userEvent.creditsRedeemed > 0) {
          text1 += '${_userEvent.creditsRedeemed} credits redeemed. ';
        }
        attendeeInfo += [
          Text(text1),
          SizedBox(height: 10),
        ];
      }
    }

    double fieldWidth = 350;
    List<Widget> colsSignUp = [];
    if (!alreadySignedUp) {
      colsSignUp = [
        _layoutService.WrapWidth([
          _inputFields.inputNumber(_formVals, 'attendeeCountAsk', min: attendeeMin, required: true, label: 'How many total spots would you like (including yourself)?',),
          widgetHost,
        ], width: fieldWidth),
        SizedBox(height: 10),
        ...colsCreditsMoney,
        ElevatedButton(
          onPressed: () {
            setState(() { _message = ''; });
            if (_formKey.currentState?.validate() == true) {
              setState(() { _loading = true; });
              _formKey.currentState?.save();
              CheckGetGetPaymentLink(currentUserState);
            } else {
              setState(() { _loading = false; });
            }
          },
          child: Text('Join Event'),
        )
      ];
    }

    return Column(
      children: [
        Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...attendeeInfo,
              SizedBox(height: 10),
              ...colsSignUp,
            ]
          ),
        )
      ]
    );
  }

  void GetUserEvent() {
    String userId = Provider.of<CurrentUserState>(context, listen: false).isLoggedIn ?
      Provider.of<CurrentUserState>(context, listen: false).currentUser.id : '';
    var data = {
      'eventId': widget.eventId,
      'userId': userId,
      'withEvent': 1,
      'withUserCheckPayment': 1,
    };
    _socketService.emit('GetUserEvent', data);
  }

  void CheckGetGetPaymentLink(currentUserState) {
    double price = _weeklyEvent.priceUSD * _formVals['attendeeCountAsk'];
    if (_availableCredits >= _formVals['attendeeCountAsk']) {
      _socketService.emit('SaveUserEvent', { 'userEvent': _formVals, 'payType': 'credits' });
    } else if (_availableUSD >= price) {
      _socketService.emit('SaveUserEvent', { 'userEvent': _formVals, 'payType': 'userMoney' });
    } else {
      String title = _formVals['attendeeCountAsk'] > 1 ?
        '${_formVals['attendeeCountAsk']} spots: ${_weeklyEvent.title}' : _weeklyEvent.title;
      var data = {
        'amountUSD': price,
        'userId': currentUserState.currentUser.id,
        'title': title,
        'forId': _event.id!,
        'forType': 'event',
      };
      _socketService.emit('StripeGetPaymentLink', data);
      setState(() { _loadingPayment = true; });
    }
  }
}
