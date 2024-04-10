import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// import '../../app_scaffold.dart';
import '../../common/form_input/input_fields.dart';
import '../../common/layout_service.dart';
import '../../common/link_service.dart';
import '../../common/socket_service.dart';
import './event_payment_service.dart';
import './event_class.dart';
import './user_event_save.dart';
import './user_event_class.dart';
import './user_weekly_event_class.dart';
import './weekly_event_class.dart';
import '../user_auth/current_user_state.dart';
import '../user_auth/user_phone.dart';

class UserWeeklyEventSave extends StatefulWidget {
  String weeklyEventId;
  UserWeeklyEventSave({this.weeklyEventId = '',});

  @override
  _UserWeeklyEventSaveState createState() => _UserWeeklyEventSaveState();
}

class _UserWeeklyEventSaveState extends State<UserWeeklyEventSave> {
  List<String> _routeIds = [];
  EventPaymentService _eventPaymentService = EventPaymentService();
  LayoutService _layoutService = LayoutService();
  LinkService _linkService = LinkService();
  SocketService _socketService = SocketService();
  InputFields _inputFields = InputFields();

  bool _loading = true;
  String _message = '';
  Map<String, dynamic> _formVals = UserWeeklyEventClass.fromJson({}).toJson();
  WeeklyEventClass _weeklyEvent = WeeklyEventClass.fromJson({});
  EventClass _event = EventClass.fromJson({});
  EventClass _nextEvent = EventClass.fromJson({});
  int _rsvpDeadlinePassed = 0;
  bool _inited = false;
  Map<String, dynamic> _formValsPay = {
    'subscription': 'month',
  };
  final _formKey = GlobalKey<FormState>();
  Map<String, double> _subscriptionPrices = {
    'month': 0,
    'year': 0,
  };
  bool _loadingPayment = false;

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('GetUserWeeklyEvent', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        _formVals = UserWeeklyEventClass.fromJson(data['userWeeklyEvent']).toJson();
        if (_formVals['_id'].length < 1) {
          _formVals['weeklyEventId'] = widget.weeklyEventId;
          _formVals['userId'] = Provider.of<CurrentUserState>(context, listen: false).currentUser.id;
        }
        setState(() { _formVals = _formVals; });
        if (data.containsKey('weeklyEvent')) {
          _weeklyEvent = WeeklyEventClass.fromJson(data['weeklyEvent']);
          setState(() { _weeklyEvent = _weeklyEvent; });
        }
        if (data.containsKey('event')) {
          _event = EventClass.fromJson(data['event']);
          setState(() { _event = _event; });
        }
        if (data.containsKey('nextEvent')) {
          _nextEvent = EventClass.fromJson(data['nextEvent']);
          setState(() { _nextEvent = _nextEvent; });
        }
        if (data.containsKey('rsvpDeadlinePassed')) {
          _rsvpDeadlinePassed = data['rsvpDeadlinePassed'];
          setState(() { _rsvpDeadlinePassed = _rsvpDeadlinePassed; });
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
      if (data.containsKey('forId') && data['forId'] == _weeklyEvent.id &&
        data.containsKey('forType') && data['forType'] == 'weeklyEvent') {
          _socketService.emit('SaveUserWeeklyEvent', { 'userWeeklyEvent': _formVals });
      }
    }));

    _routeIds.add(_socketService.onRoute('SaveUserWeeklyEvent', callback: (String resString) {
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

    if (currentUserState.currentUser.phoneNumber!.length < 1 || currentUserState.currentUser.phoneNumberVerified < 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Text messages are used to notify you when you are accepted to an event. Enter your phone number to get started.'),
          SizedBox(height: 10),
          UserPhone(),
        ]
      );
    }

    if (!_inited && widget.weeklyEventId.length > 0) {
      _inited = true;
      GetUserWeeklyEvent();
    }

    if (_loading) {
      List<Widget> cols = [];
      if (_loadingPayment) {
        cols += [
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              GetUserWeeklyEvent();
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

    if (_formVals['_id'].length > 1) {
      return Text('You are already subscribed to this weekly event!');
    }

    Widget widgetForm = SizedBox.shrink();
    if (_formValsPay['subscription'] == 'single') {
      String eventId = _rsvpDeadlinePassed > 0 ? _nextEvent.id : _event.id;
      widgetForm = UserEventSave(eventId: eventId);
    } else {
      double fieldWidth = 250;
      widgetForm = Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _layoutService.WrapWidth([
              _inputFields.inputNumber(_formVals, 'attendeeCountAsk', required: true,
                label: 'How many spots (including yourself)?', onChange: (double? val)  {
                  setState(() { _formVals = _formVals;});
                }),
              ], width: fieldWidth),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                setState(() { _message = ''; });
                if (_formKey.currentState?.validate() == true) {
                  setState(() { _loading = true; });
                  _formKey.currentState?.save();
                  GetPaymentLink(currentUserState);
                } else {
                  setState(() { _loading = false; });
                }
              },
              child: Text('Subscribe'),
            ),
          ]
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BuildSubscriptions(),
        SizedBox(height: 10),
        widgetForm,
      ]
    );
  }

  void GetUserWeeklyEvent() {
    String userId = Provider.of<CurrentUserState>(context, listen: false).isLoggedIn ?
      Provider.of<CurrentUserState>(context, listen: false).currentUser.id : '';
    var data = {
      'weeklyEventId': widget.weeklyEventId,
      'userId': userId,
      'withWeeklyEvent': 1,
      'withEvent': 1,
    };
    _socketService.emit('GetUserWeeklyEvent', data);
  }

  Widget BuildSubscriptions() {
    Map<String, double> prices = _eventPaymentService.GetSubscriptionDiscounts(_weeklyEvent.priceUSD,
      _weeklyEvent.hostGroupSizeDefault.toDouble());
    double spots = _formVals['attendeeCountAsk'];
    double singlePrice = _weeklyEvent.priceUSD * spots;
    double monthlyPrice = prices['monthlyPrice']! * spots;
    double yearlyPrice = prices['yearlyPrice']! * spots;
    double monthlySavingsPerYear = prices['monthlySavingsPerYear']! * spots;
    double yearlySavingsPerYear = prices['yearlySavingsPerYear']! * spots;

    _subscriptionPrices['month'] = monthlyPrice;
    _subscriptionPrices['year'] = yearlyPrice;

    return Column(
      children: [
        SegmentedButton<String>(
          segments: [
            ButtonSegment<String>(
              value: 'single',
              label: Text('Single Event: \$${singlePrice}'),
            ),
            ButtonSegment<String>(
              value: 'month',
              label: Column(
                children: [
                  Text('Monthly: \$${monthlyPrice}'),
                  Text('Save \$${monthlySavingsPerYear} per year'),
                ]
              ),
            ),
            ButtonSegment<String>(
              value: 'year',
              label: Column(
                children: [
                  Text('Yearly: \$${yearlyPrice}'),
                  Text('Save \$${yearlySavingsPerYear} per year'),
                ]
              ),
            ),
          ],
          selected: <String>{_formValsPay['subscription']},
          onSelectionChanged: (Set<String> newSelection) {
            // By default there is only a single segment that can be
            // selected at one time, so its value is always the first
            // item in the selected set.
            _formValsPay['subscription'] = newSelection.first;
            setState(() {
              _formValsPay = _formValsPay;
            });
          },
        ),
        SizedBox(height: 10),
      ]
    );
  }

  void GetPaymentLink(currentUserState) {
    double price = _subscriptionPrices[_formValsPay['subscription']]!;
    String title = _formVals['attendeeCountAsk'] > 1 ?
        '${_formVals['attendeeCountAsk']} spots: ${_weeklyEvent.title}' : _weeklyEvent.title;
    var data = {
      'amountUSD': price,
      'userId': currentUserState.currentUser.id,
      'title': title,
      'forId': _weeklyEvent.id!,
      'forType': 'weeklyEvent',
      'recurringInterval': _formValsPay['subscription'],
    };
    _socketService.emit('StripeGetPaymentLink', data);
    setState(() { _loadingPayment = true; });
  }
}
