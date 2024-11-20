import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// import '../../app_scaffold.dart';
import '../../common/colors_service.dart';
import '../../common/form_input/input_fields.dart';
import '../../common/layout_service.dart';
import '../../common/link_service.dart';
import '../../common/socket_service.dart';
import '../../common/style.dart';
import './event_payment_service.dart';
import './event_class.dart';
import './user_event_save.dart';
import './user_event_class.dart';
import './user_weekly_event_class.dart';
import './weekly_event_class.dart';
import '../user_auth/current_user_state.dart';
import '../user_auth/user_login_signup.dart';
import '../user_auth/user_phone.dart';

class UserWeeklyEventSave extends StatefulWidget {
  String weeklyEventId;
  bool alreadySignedUp;
  UserEventClass? userEvent;
  int? spotsPaidFor;
  double? availableUSD;
  double? availableCreditUSD;
  bool showRsvpNote;
  bool showSelfHost;
  bool showPay;
  bool showHost;
  bool autoSave;
  int attendeeCountAsk;
  int hostGroupSizeMax;
  int selfHostCount;

  UserWeeklyEventSave({this.weeklyEventId = '', this.alreadySignedUp = false,
    this.userEvent = null, this.spotsPaidFor = null, this.availableUSD = null, this.availableCreditUSD = null,
    this.showRsvpNote = true, this.showSelfHost = false, this.showPay = false, this.showHost = false,
    this.autoSave = false, this.attendeeCountAsk = 0, this.hostGroupSizeMax = 0, this.selfHostCount = 0,
  });

  @override
  _UserWeeklyEventSaveState createState() => _UserWeeklyEventSaveState();
}

class _UserWeeklyEventSaveState extends State<UserWeeklyEventSave> {
  List<String> _routeIds = [];
  ColorsService _colors = ColorsService();
  EventPaymentService _eventPaymentService = EventPaymentService();
  LayoutService _layoutService = LayoutService();
  LinkService _linkService = LinkService();
  SocketService _socketService = SocketService();
  Style _style = Style();
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
    '3month': 0,
    'year': 0,
  };
  bool _loadingPayment = false;
  String _mode = '';

  @override
  void initState() {
    super.initState();

    _formVals['attendeeCountAsk'] = 1;

    _routeIds.add(_socketService.onRoute('GetUserWeeklyEvent', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        _formVals = UserWeeklyEventClass.fromJson(data['userWeeklyEvent']).toJson();
        if (_formVals['_id'].length < 1) {
          _formVals['weeklyEventId'] = widget.weeklyEventId;
          _formVals['userId'] = Provider.of<CurrentUserState>(context, listen: false).currentUser.id;
          _formVals['attendeeCountAsk'] = 1;
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
        if (data.containsKey('forId') && data.containsKey('forType') &&
          data['forType'] == 'weeklyEvent' && data['forId'] == _weeklyEvent.id) {
          _linkService.LaunchURL(data['url']);
        }
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
        GetUserWeeklyEvent();
        // context.go('/weekly-events');
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
      if (_mode == 'loginSignup') {
        return UserLoginSignup(withHeader: false, mode: 'signup', logInText: 'Log In to Join',
          signUpText: 'Sign Up to Join', onSave: (Map<String, dynamic> data) {
        });
      }
      return ElevatedButton(
        onPressed: () {
          // _linkService.Go('', context, currentUserState: currentUserState);
          // _socketService.TrackEvent('Join Event');
          _mode = 'loginSignup';
          setState(() { _mode = _mode; });
        },
        child: Text('Join Event'),
      );
    }

    if (!_inited && widget.weeklyEventId.length > 0) {
      _inited = true;
      GetUserWeeklyEvent();
    }

    if (_loading || _loadingPayment) {
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
      return Text('You are already subscribed to this weekly event. The RSVP deadline has passed for this week, but you will be signed up for next week!');
    }

    List<Widget> colsSubscription = [];
    if (_weeklyEvent.priceUSD != 0) {
      colsSubscription = [
        BuildSubscriptions(),
        SizedBox(height: 10),
      ];
    }
    Widget widgetForm = SizedBox.shrink();
    if (_formValsPay['subscription'] == 'single' || _weeklyEvent.priceUSD == 0) {
      EventClass event = _rsvpDeadlinePassed > 0 ? _nextEvent : _event;
      String eventId = event.id;
      widgetForm = UserEventSave(eventId: eventId,
        userEvent: widget.userEvent, event: event, weeklyEvent: _weeklyEvent, spotsPaidFor: widget.spotsPaidFor,
        availableUSD: widget.availableUSD, availableCreditUSD: widget.availableCreditUSD,
        showRsvpNote: widget.showRsvpNote, showSelfHost: widget.showSelfHost, showPay: widget.showPay,
        showHost: widget.showHost, autoSave: widget.autoSave, attendeeCountAsk: widget.attendeeCountAsk,
        hostGroupSizeMax: widget.hostGroupSizeMax, selfHostCount: widget.selfHostCount,);
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
                label: 'How many spots (including yourself)?', min: 1, onChanged: (double? val)  {
                  if (val != null && val! >= 1) {
                    _formVals['attendeeCountAsk'] = val.toInt();
                    setState(() { _formVals = _formVals;});
                  }
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
              child: Text('Subscribe \$${_subscriptionPrices[_formValsPay['subscription']]!.toStringAsFixed(0)}'),
            ),
          ]
        ),
      );
    }

    List<Widget> colsPhone = [];
    if (widget.alreadySignedUp &&
      ((currentUserState.currentUser.phoneNumber!.length < 1 || currentUserState.currentUser.phoneNumberVerified < 1) &&
      (currentUserState.currentUser.whatsappNumber!.length < 1 || currentUserState.currentUser.whatsappNumberVerified < 1))) {
      colsPhone = [
        Text('Text messages are used to notify you when you are accepted to an event. Enter your phone number to get started.'),
        SizedBox(height: 10),
        UserPhone(),
        SizedBox(height: 30),
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...colsSubscription,
        widgetForm,
        _style.SpacingH('large'),
        ...colsPhone,
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
    double monthlySavingsPerYear = prices['monthlySavingsPerYear']! * spots;
    double monthlyPricePerEvent = prices['monthlyPricePerEvent']! * spots;
    double monthly3Price = prices['monthly3Price']! * spots;
    double monthly3SavingsPerYear = prices['monthly3SavingsPerYear']! * spots;
    double montly3PricePerEvent = prices['monthly3PricePerEvent']! * spots;
    // double yearlyPrice = prices['yearlyPrice']! * spots;
    // double yearlySavingsPerYear = prices['yearlySavingsPerYear']! * spots;

    _subscriptionPrices['month'] = monthlyPrice;
    _subscriptionPrices['3month'] = monthly3Price;
    // _subscriptionPrices['year'] = yearlyPrice;

    List<Map<String, dynamic>> opts = [
      {'value': 'single', 'label': 'Single Event: \$${singlePrice}'},
      // {'value': 'month', 'label': 'Monthly Subscription: \$${monthlyPrice} (\$${monthlyPricePerEvent.toStringAsFixed(0)} / event; save \$${monthlySavingsPerYear} / year)'},
      // {'value': '3month', 'label': '3 Month Subscription: \$${monthly3Price}; \$${montly3PricePerEvent.toStringAsFixed(0)} / event; save \$${monthly3SavingsPerYear} / year)'},
      {'value': 'month', 'label': 'Monthly Subscription: \$${monthlyPricePerEvent.toStringAsFixed(0)} (\$${monthlyPrice} / mo)'},
      {'value': '3month', 'label': '3 Month Subscription: \$${montly3PricePerEvent.toStringAsFixed(0)} (\$${monthly3Price} / 3 mo)'},
    ];
    return _inputFields.inputSelectButtons(opts, _formValsPay, 'subscription', onChanged: (val) {
      _formValsPay['subscription'] = val;
      setState(() { _formValsPay = _formValsPay; });
    });
  }

  void GetPaymentLink(currentUserState) {
    double price = _subscriptionPrices[_formValsPay['subscription']]!;
    String title = _formVals['attendeeCountAsk'] > 1 ?
        '${_formVals['attendeeCountAsk']} spots: ${_weeklyEvent.title}' : _weeklyEvent.title;
    int recurringIntervalCount = 1;
    String interval = _formValsPay['subscription'];
    if (_formValsPay['subscription'] == '3month') {
      recurringIntervalCount = 3;
      interval = 'month';
    }
    var data = {
      'amountUSD': price,
      'userId': currentUserState.currentUser.id,
      'title': title,
      'forId': _weeklyEvent.id!,
      'forType': 'weeklyEvent',
      'quantity': _formVals['attendeeCountAsk'],
      'recurringInterval': interval,
      'recurringIntervalCount': recurringIntervalCount,
    };
    _socketService.emit('StripeGetPaymentLink', data);
    setState(() { _loadingPayment = true; });
  }
}
