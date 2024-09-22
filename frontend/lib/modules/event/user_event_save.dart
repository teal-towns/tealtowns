import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../common/buttons.dart';
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
  Function()? onUpdate;
  UserEventSave({this.eventId = '', this.onUpdate = null,});

  @override
  _UserEventSaveState createState() => _UserEventSaveState();
}

class _UserEventSaveState extends State<UserEventSave> {
  Buttons _buttons = Buttons();
  InputFields _inputFields = InputFields();
  LayoutService _layoutService = LayoutService();
  LinkService _linkService = LinkService();
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();

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
  double _availableCreditUSD = 0;
  bool _loadingPayment = false;

  String _mySharedItemsState = '';
  List<dynamic> _mySharedItems = [];

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
        if (_userEvent.id.length > 0) {
          _formVals = _userEvent.toJson();
        }
        setState(() { _formVals = _formVals; _userEvent = _userEvent; });
        if (data.containsKey('event')) {
          _event = EventClass.fromJson(data['event']);
          setState(() { _formVals = _formVals; });
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
      setState(() { _loading = false; _loadingPayment = false; });
    }));

    _routeIds.add(_socketService.onRoute('StripeGetPaymentLink', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        if (data.containsKey('forId') && data.containsKey('forType') &&
          data['forType'] == 'event' && data['forId'] == _event.id!) {
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
      if (data.containsKey('forId') && data['forId'] == _event.id &&
        data.containsKey('forType') && data['forType'] == 'event') {
        _socketService.emit('SaveUserEvent', { 'userEvent': _formVals, 'payType': 'paid' });
      }
    }));

    _routeIds.add(_socketService.onRoute('SaveUserEvent', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        // context.go('/weekly-events');
        GetUserEvent();
        if (widget.onUpdate != null) {
          widget.onUpdate!();
        }
      }
    }));

    _routeIds.add(_socketService.onRoute('searchSharedItems', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        _mySharedItems = data['sharedItems'];
        setState(() { _mySharedItems = _mySharedItems; _mySharedItemsState = 'loaded'; });
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
          _linkService.Go('', context, currentUserState: currentUserState);
          _socketService.TrackEvent('Join Event');
        },
        child: Text('Join Event'),
      );
    }
    if (!_inited && widget.eventId.length > 0) {
      _inited = true;
      GetUserEvent();
    }

    if (_loading || _loadingPayment) {
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

    List<Widget> colsHost = [];
    if (_weeklyEvent.priceUSD > 0) {
      // Do not allow changing if already complete and have a host group.
      if (!(_userEvent.id.length > 0 && _userEvent.hostStatus == 'complete' && _userEvent.hostGroupSize > 0)) {
        String hostLabel = 'How many people will you host? Earn 1 free event per ${_weeklyEvent.hostGroupSizeDefault} people.';
        colsHost += [ _inputFields.inputNumber(_formVals, 'hostGroupSizeMax', required: true, label: hostLabel,) ];
      }
    }
    double attendeeMin = _userEvent.attendeeCount > 0 ? _userEvent.attendeeCount.toDouble() : 1;

    List<Widget> colsCreditMoney = [];
    if (_weeklyEvent.priceUSD > 0) {
      if (_availableUSD >= _weeklyEvent.priceUSD || _availableCreditUSD >= 1) {
        String text = '';
        if (_availableCreditUSD >= 1) {
          text += 'You have \$${_availableCreditUSD.toStringAsFixed(2)} credit. ';
        }
        if (_availableUSD >= _weeklyEvent.priceUSD) {
          text += 'You have \$${_availableUSD.toStringAsFixed(2)}. ';
        }
        colsCreditMoney = [
          Text(text),
          SizedBox(height: 10),
        ];
      }
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
    }

    bool showJoin = true;
    if (_weeklyEvent.type == 'sharedItem') {
      if (_mySharedItemsState == '') {
        _mySharedItemsState = 'loading';
        var data1 = { 'status': 'available', 'currentOwnerUserId': currentUserState.currentUser.id,
          'lngLat': _weeklyEvent.location.coordinates, 'maxMeters': 8000, };
        _socketService.emit('searchSharedItems', data1);
      } else if (_mySharedItemsState == 'loaded' && _mySharedItems.length < 1) {
        showJoin = false;
      }
    }

    double fieldWidth = 350;
    List<Widget> colsAttendee = [];
    if (!alreadySignedUp && showJoin) {
      colsAttendee += [ _inputFields.inputNumber(_formVals, 'attendeeCountAsk', min: attendeeMin, required: true, label: 'How many total spots would you like (including yourself)?',) ];
    }
    List<Widget> colsSignUp = [];
    if (showJoin) {
      colsSignUp = [
        _layoutService.WrapWidth([
          ...colsAttendee,
          ...colsHost,
          _inputFields.inputText(_formVals, 'rsvpNote', label: 'Note (optional)',),
        ], width: fieldWidth, align: 'left'),
        SizedBox(height: 10),
      ];
    }
    if (!alreadySignedUp) {
      if (_weeklyEvent.type == 'sharedItem') {
        if (_mySharedItemsState == 'loaded' && _mySharedItems.length < 1) {
          colsSignUp += [
            _buttons.LinkElevated(context, 'Add a Shared Item to Join', '/shared-item-save', launchUrl: true),
          ];
        }
      }

      if (showJoin) {
        colsSignUp += [
          ...colsCreditMoney,
          ElevatedButton(
            onPressed: () {
              setState(() { _message = ''; });
              if (_formKey.currentState?.validate() == true) {
                setState(() { _loading = true; });
                _formKey.currentState?.save();
                CheckGetGetPaymentLink(currentUserState);
                _socketService.TrackEvent('Join Event');
              } else {
                setState(() { _loading = false; });
              }
            },
            child: Text('Join Event'),
          )
        ];
      }
    } else {
      colsSignUp += [
        ElevatedButton(
          onPressed: () {
            setState(() { _message = ''; });
            if (_formKey.currentState?.validate() == true) {
              setState(() { _loading = true; });
              _formKey.currentState?.save();
              _socketService.emit('SaveUserEvent', { 'userEvent': _formVals, 'payType': 'unchanged' });
            } else {
              setState(() { _loading = false; });
            }
          },
          child: Text('Update RSVP'),
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
      'withWeeklyEvent': 1,
    };
    _socketService.emit('GetUserEvent', data);
  }

  void CheckGetGetPaymentLink(currentUserState) {
    double price = _weeklyEvent.priceUSD * _formVals['attendeeCountAsk'];
    if (_weeklyEvent.priceUSD == 0) {
      _socketService.emit('SaveUserEvent', { 'userEvent': _formVals, 'payType': 'free' });
    } else if (_availableCreditUSD >= price) {
      _socketService.emit('SaveUserEvent', { 'userEvent': _formVals, 'payType': 'creditUSD' });
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
        'quantity': _formVals['attendeeCountAsk'],
        'forType': 'event',
      };
      _socketService.emit('StripeGetPaymentLink', data);
      setState(() { _loadingPayment = true; });
    }
  }
}
