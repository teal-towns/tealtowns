import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../common/alert_service.dart';
import '../../common/date_time_service.dart';
import '../../common/socket_service.dart';
import '../../common/style.dart';
import '../user_auth/current_user_state.dart';
import './event_class.dart';
import './user_weekly_event_save.dart';
import './user_event_save.dart';
import './user_event_class.dart';
import './weekly_event_class.dart';

class EventPay extends StatefulWidget {
  WeeklyEventClass weeklyEvent;
  EventClass event;
  bool alreadySignedUp;
  int rsvpDeadlinePassed;
  bool withEventInfo;
  bool withSubscribe;
  bool showRsvpNote;
  bool showSelfHost;
  bool showPay;
  bool showHost;
  bool autoSave;
  int attendeeCountAsk;
  int hostGroupSizeMax;
  int selfHostCount;
  Function()? onUpdate;
  EventPay({required this.weeklyEvent, required this.event, this.alreadySignedUp = false,
    this.rsvpDeadlinePassed = 0, this.withEventInfo = false, this.withSubscribe = true,
    this.showRsvpNote = true, this.showPay = true, this.showHost = true, this.showSelfHost = false, this.autoSave = false,
    this.attendeeCountAsk = 0, this.selfHostCount = 0, this.hostGroupSizeMax = 0,
    this.onUpdate = null});

  @override
  _EventPayState createState() => _EventPayState();
}

class _EventPayState extends State<EventPay> {
  AlertService _alertService = AlertService();
  DateTimeService _dateTime = DateTimeService();
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();
  Style _style = Style();

  UserEventClass? _userEvent = null;
  EventClass? _event = null;
  WeeklyEventClass? _weeklyEvent = null;
  int? _spotsPaidFor = null;
  double? _availableUSD = null;
  double? _availableCreditUSD = null;

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('GetUserEvent', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        _userEvent = UserEventClass.fromJson(data['userEvent']);
        setState(() { _userEvent = _userEvent; });
        if (data.containsKey('event')) {
          _event = EventClass.fromJson(data['event']);
          setState(() { _event = _event; });
        }
        if (data.containsKey('weeklyEvent')) {
          _weeklyEvent = WeeklyEventClass.fromJson(data['weeklyEvent']);
          setState(() { _weeklyEvent = _weeklyEvent; });
        }
        if (data.containsKey('userCheckPayment')) {
            setState(() {
              _spotsPaidFor = data['userCheckPayment']['spotsPaidFor'];
              _availableUSD = data['userCheckPayment']['availableUSD'];
              _availableCreditUSD = data['userCheckPayment']['availableCreditUSD'];
              _weeklyEvent = WeeklyEventClass.fromJson(data['userCheckPayment']['weeklyEvent']);
            });
        }
      }
      // setState(() { _loading = false; _loadingPayment = false; });
    }));

    String userId = Provider.of<CurrentUserState>(context, listen: false).isLoggedIn ?
      Provider.of<CurrentUserState>(context, listen: false).currentUser.id : '';
    var data = {
      'eventId': widget.event.id,
      'userId': userId,
      'withUserCheckPayment': 1,
      // 'withEvent': 1,
      // 'withWeeklyEvent': 1,
    };
    _socketService.emit('GetUserEvent', data);
  }

  @override
  void dispose() {
    _socketService.offRouteIds(_routeIds);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.event.id.length == 0) {
      return Column( children: [ LinearProgressIndicator() ]);
    }

    List<Widget> cols = [];
    String startDate = _dateTime.Format(widget.event.start, 'EEEE M/d/y h:mm a');
    if (widget.withEventInfo) {
      cols += [
        _style.Text1(widget.weeklyEvent.title, size: 'large'),
        _style.SpacingH('medium'),
        _style.Text1(startDate),
        _style.SpacingH('medium'),
      ];
    }

    bool alreadySignedUp = widget.alreadySignedUp;
    List<Widget> colsSinglePay = [
      UserEventSave(eventId: widget.event.id,
        userEvent: _userEvent, event: _event, weeklyEvent: _weeklyEvent, spotsPaidFor: _spotsPaidFor,
        availableUSD: _availableUSD, availableCreditUSD: _availableCreditUSD,
        showRsvpNote: widget.showRsvpNote, showSelfHost: widget.showSelfHost, showPay: widget.showPay,
        showHost: widget.showHost, autoSave: widget.autoSave, attendeeCountAsk: widget.attendeeCountAsk,
        hostGroupSizeMax: widget.hostGroupSizeMax, selfHostCount: widget.selfHostCount,
        onUpdate: () {
          _alertService.Show(context, 'RSVP Updated');
          if (widget.onUpdate != null) {
            widget.onUpdate!();
          }
        }
      ),
    ];
    if (!alreadySignedUp) {
      List<Widget> colsRsvp = [];
      String rsvpSignUpText = widget.rsvpDeadlinePassed > 0 ? 'RSVP deadline passed for this week\'s event, but you can sign up for next week\'s: ${startDate}' : '';
      if (rsvpSignUpText.length > 0) {
        colsRsvp += [
          _style.Text1(rsvpSignUpText),
          _style.SpacingH('medium'),
        ];
      }
      List<Widget> colsPay = [];
      if (widget.withSubscribe) {
        colsPay += [
          UserWeeklyEventSave(weeklyEventId: widget.weeklyEvent.id, alreadySignedUp: alreadySignedUp,
            userEvent: _userEvent, spotsPaidFor: _spotsPaidFor,
            availableUSD: _availableUSD, availableCreditUSD: _availableCreditUSD,
            showRsvpNote: widget.showRsvpNote, showSelfHost: widget.showSelfHost, showPay: widget.showPay,
            showHost: widget.showHost, autoSave: widget.autoSave, attendeeCountAsk: widget.attendeeCountAsk,
            hostGroupSizeMax: widget.hostGroupSizeMax, selfHostCount: widget.selfHostCount,
          ),
        ];
      } else {
        colsPay = colsSinglePay;
      }
      cols += [
        ...colsRsvp,
        ...colsPay,
        _style.SpacingH('medium'),
      ];
    } else {
      cols += [
        ...colsSinglePay,
        _style.SpacingH('medium'),
      ];
    }
    return Column(
      children: [
        ...cols,
      ]
    );
  }
}