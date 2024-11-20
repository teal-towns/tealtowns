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
import '../user_auth/user_login_signup.dart';

class UserEventSave extends StatefulWidget {
  String eventId;
  Function()? onUpdate;
  UserEventClass? userEvent;
  EventClass? event;
  WeeklyEventClass? weeklyEvent;
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
  // Scenarios / flow:
  // 1. Host? If yes:
  // 1a. Self-host? (Do not pay, and host no matter what). NOTE: could self-host but NOT want to host for others.
  // 1b. NO self-host: pay, and MAY host (pending sign ups). IF host, will get credit / money (back), but still pay up front in case do NOT host.
  // 2. NO host: pay
  // In general, self host is rare, and only used up front when user does not have any credits yet.

  UserEventSave({this.eventId = '', this.onUpdate = null, this.userEvent = null, this.event = null,
    this.weeklyEvent = null, this.spotsPaidFor = null, this.availableUSD = null, this.availableCreditUSD = null,
    this.showRsvpNote = true, this.showSelfHost = false, this.showPay = true, this.showHost = true,
    this.autoSave = false, this.attendeeCountAsk = 0, this.hostGroupSizeMax = 0, this.selfHostCount = 0,
  });

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
  bool _userEventInited = false;
  final _formKey = GlobalKey<FormState>();
  int _spotsPaidFor = 0;
  double _availableUSD = 0;
  double _availableCreditUSD = 0;
  bool _loadingPayment = false;

  String _mySharedItemsState = '';
  List<dynamic> _mySharedItems = [];
  String _mode = '';

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('GetUserEvent', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        _userEvent = UserEventClass.fromJson(data['userEvent']);
        _formVals = _userEvent.toJson();
        CurrentUserState currentUserState = Provider.of<CurrentUserState>(context, listen: false);
        if (_formVals['_id'].length < 1) {
          _formVals['eventId'] = widget.eventId;
          if (currentUserState.isLoggedIn) {
            _formVals['userId'] = currentUserState.currentUser.id;
          }
        }
        if (_userEvent.id.length > 0) {
          _formVals = _userEvent.toJson();
        }
        InitFormVals();
        setState(() { _formVals = _formVals; _userEvent = _userEvent; });
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
        if (!_userEventInited) {
          _userEventInited = true;
          if (widget.autoSave && currentUserState.isLoggedIn) {
            JoinEvent();
          }
          setState(() { _userEventInited = _userEventInited; });
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

    InitFormVals();
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
    if (!_inited && widget.eventId.length > 0) {
      _inited = true;
      // Init from passed in values to avoid reloading every time (e.g. if switching between
      // UserEventSave and UserWeeklyEventSave).
      if (widget.userEvent != null && widget.event != null && widget.weeklyEvent != null &&
        widget.spotsPaidFor != null && widget.availableUSD != null && widget.availableCreditUSD != null) {
        _userEvent = widget.userEvent!;
        _event = widget.event!;
        _weeklyEvent = widget.weeklyEvent!;
        _spotsPaidFor = widget.spotsPaidFor!;
        _availableUSD = widget.availableUSD!;
        _availableCreditUSD = widget.availableCreditUSD!;
        _formVals = _userEvent.toJson();
        CurrentUserState currentUserState = Provider.of<CurrentUserState>(context, listen: false);
        if (_formVals['_id'].length < 1) {
          _formVals['eventId'] = widget.eventId;
          if (currentUserState.isLoggedIn) {
            _formVals['userId'] = currentUserState.currentUser.id;
          }
        }
        if (_userEvent.id.length > 0) {
          _formVals = _userEvent.toJson();
        }
        InitFormVals();
        _userEventInited = true;
        _loading = false;
        if (widget.autoSave && currentUserState.isLoggedIn) {
          JoinEvent();
        }
        // setState(() { _userEvent = _userEvent; _event = _event; _weeklyEvent = _weeklyEvent;
        //   _spotsPaidFor = _spotsPaidFor; _availableUSD = _availableUSD; _availableCreditUSD = _availableCreditUSD; });
      } else {
        GetUserEvent();
      }
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
    if (_weeklyEvent.priceUSD > 0 && widget.showHost) {
      // Do not allow changing if already complete and have a host group.
      if (!(_userEvent.id.length > 0 && _userEvent.hostStatus == 'complete' && _userEvent.hostGroupSize > 0)) {
        String hostLabel = 'How many people will you host? Earn 1 free event per ${_weeklyEvent.hostGroupSizeDefault} people.';
        colsHost += [
          _inputFields.inputNumber(_formVals, 'hostGroupSizeMax', required: true, label: hostLabel, onChanged: (double? val)  {
            if (val != null && val! >= 0) {
              _formVals['hostGroupSizeMax'] = val.toInt();
              // If fill in host first, assume user wants to self host.
              if (_formVals['attendeeCountAsk'] <= 0) {
                if (_formVals['hostGroupSizeMax'] > 0 && _formVals['selfHostCount'] <= 0) {
                  _formVals['selfHostCount'] = 1;
                } else {
                  _formVals['selfHostCount'] = 0;
                }
              }
              setState(() { _formVals = _formVals;});
            }
          },
          )
        ];
      }
    }
    double attendeeMin = _userEvent.attendeeCount > 0 ? _userEvent.attendeeCount.toDouble() : 0;

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
    if (_userEvent.attendeeCountAsk > 0 || _userEvent.selfHostCount > 0) {
      alreadySignedUp = true;
      if (_userEvent.attendeeCount > 0 || _userEvent.selfHostCount > 0) {
        int guestsGoing = _userEvent.attendeeCount + _userEvent.selfHostCount - 1;
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
    if (!alreadySignedUp && showJoin && widget.showPay) {
      colsAttendee += [
        _inputFields.inputNumber(_formVals, 'attendeeCountAsk', min: attendeeMin, required: true,
          label: 'How many total spots would you like (including yourself)?', onChanged: (double? val)  {
            if (val != null && val! >= 0) {
              _formVals['attendeeCountAsk'] = val.toInt();
              setState(() { _formVals = _formVals;});
            }
          },
        )
      ];
    }
    if (widget.showSelfHost) {
      colsAttendee += [
        _inputFields.inputNumber(_formVals, 'selfHostCount', min: 0, required: false,
          label: 'How many will you self host (no payment required)?', onChanged: (double? val)  {
            if (val != null && val! >= 0) {
              _formVals['selfHostCount'] = val.toInt();
              setState(() { _formVals = _formVals;});
            }
          },
        )
      ];
    }

    List<Widget> colsSignUp = [];
    if (showJoin) {
      List<Widget> colsNote = [];
      if (widget.showRsvpNote) {
        colsNote = [
          _inputFields.inputText(_formVals, 'rsvpNote', label: 'Note (optional)',),
        ];
      }
      colsSignUp = [
        _layoutService.WrapWidth([
          ...colsAttendee,
          ...colsHost,
          ...colsNote,
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
        double price = _weeklyEvent.priceUSD * _formVals['attendeeCountAsk'];
        colsSignUp += [
          ...colsCreditMoney,
        ];
        if (price > 0 || _formVals['selfHostCount'] > 0) {
          String text = 'Join Event';
          if (price > 0) {
            text += ' (\$${price.toStringAsFixed(0)})';
          }
          colsSignUp += [
            ElevatedButton(
              onPressed: () {
                setState(() { _message = ''; });
                if (_formKey.currentState?.validate() == true) {
                  JoinEvent();
                  _socketService.TrackEvent('Join Event');
                } else {
                  setState(() { _loading = false; });
                }
              },
              child: Text(text),
            )
          ];
        }
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

  void InitFormVals() {
    if (widget.attendeeCountAsk > 0) {
      _formVals['attendeeCountAsk'] = widget.attendeeCountAsk;
    }
    if (widget.hostGroupSizeMax > 0) {
      _formVals['hostGroupSizeMax'] = widget.hostGroupSizeMax;
    }
    if (widget.selfHostCount > 0) {
      _formVals['selfHostCount'] = widget.selfHostCount;
    }
  }

  void JoinEvent() {
    setState(() { _loading = true; });
    _formKey.currentState?.save();
    double price = _weeklyEvent.priceUSD * _formVals['attendeeCountAsk'];
    if (price > 0) {
      CurrentUserState currentUserState = Provider.of<CurrentUserState>(context, listen: false);
      CheckGetPaymentLink(currentUserState);
    } else {
      _socketService.emit('SaveUserEvent', { 'userEvent': _formVals, 'payType': 'selfHost' });
    }
  }

  void GetUserEvent() {
    CurrentUserState currentUserState = Provider.of<CurrentUserState>(context, listen: false);
    String userId = currentUserState.isLoggedIn ? currentUserState.currentUser.id : '';
    var data = {
      'eventId': widget.eventId,
      'userId': userId,
      'withEvent': 1,
      'withUserCheckPayment': 1,
      'withWeeklyEvent': 1,
    };
    _socketService.emit('GetUserEvent', data);
  }

  void CheckGetPaymentLink(currentUserState) {
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
