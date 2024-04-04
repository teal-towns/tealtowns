import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_scaffold.dart';
import '../../common/config_service.dart';
import '../../common/link_service.dart';
import '../../common/mapbox/mapbox.dart';
import '../../common/socket_service.dart';
import './event_class.dart';
import './user_event_class.dart';
import './user_weekly_event_save.dart';
import './weekly_event_class.dart';
import '../user_auth/current_user_state.dart';

class WeeklyEventView extends StatefulWidget {
  String uName;

  WeeklyEventView({ this.uName = '', });

  @override
  _WeeklyEventViewState createState() => _WeeklyEventViewState();
}

class _WeeklyEventViewState extends State<WeeklyEventView> {
  List<String> _routeIds = [];
  ConfigService _configService = ConfigService();
  LinkService _linkService = LinkService();
  SocketService _socketService = SocketService();

  bool _loading = true;
  String _message = '';

  bool _inited = false;
  WeeklyEventClass _weeklyEvent = WeeklyEventClass.fromJson({});
  EventClass _event = EventClass.fromJson({});
  EventClass _nextEvent = EventClass.fromJson({});
  int _rsvpDeadlinePassed = 0;
  int _attendeesCount = 0;
  int _nonHostAttendeesWaitingCount = 0;
  UserEventClass _userEvent = UserEventClass.fromJson({});

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('getWeeklyEventById', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        if (data.containsKey('weeklyEvent')) {
          _weeklyEvent = WeeklyEventClass.fromJson(data['weeklyEvent']);
          setState(() { _weeklyEvent = _weeklyEvent; });
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
          if (data.containsKey('attendeesCount')) {
            _attendeesCount = data['attendeesCount'];
            setState(() { _attendeesCount = _attendeesCount; });
          }
          if (data.containsKey('nonHostAttendeesWaitingCount')) {
            _nonHostAttendeesWaitingCount = data['nonHostAttendeesWaitingCount'];
            setState(() { _nonHostAttendeesWaitingCount = _nonHostAttendeesWaitingCount; });
          }
          if (data.containsKey('userEvent')) {
            _userEvent = UserEventClass.fromJson(data['userEvent']);
            setState(() { _userEvent = _userEvent; });
          }
        } else {
          _message = 'Error.';
        }
      } else {
        _message = data['message'].length > 0 ? data['message'] : 'Error.';
        context.go('/eat');
      }
      setState(() {
        _loading = false;
      });
    }));

    _routeIds.add(_socketService.onRoute('removeWeeklyEvent', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        context.go('/eat');
      } else {
        _message = data['message'].length > 0 ? data['message'] : 'Error.';
      }
      setState(() {
        _loading = false;
      });
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
    if (!_inited) {
      _inited = true;
      var data = {
        // 'id': widget.id,
        'uName': widget.uName,
        'withAdmins': 1,
        'withEvent': 1,
        'withUserEvents': 1,
        'withUserId': currentUserState.isLoggedIn ? currentUserState.currentUser.id : '',
      };
      _socketService.emit('getWeeklyEventById', data);
    }
    List<Widget> buttons = [];
    if (currentUserState.isLoggedIn && _weeklyEvent.adminUserIds.contains(currentUserState.currentUser.id)) {
      buttons = [
        ElevatedButton(
          onPressed: () {
            _linkService.Go('/weekly-event-save?id=${_weeklyEvent.id}', context, currentUserState);
          },
          child: Text('Edit'),
        ),
        SizedBox(width: 10),
        ElevatedButton(
          onPressed: () {
            _socketService.emit('removeWeeklyEvent', { 'id': _weeklyEvent.id });
          },
          child: Text('Delete'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Theme.of(context).errorColor,
          ),
        ),
        SizedBox(width: 10),
      ];
    }

    List<Widget> admins = [];
    if (_weeklyEvent.adminUsers.length > 0) {
      admins.add(Text('Admins'));
      for (var admin in _weeklyEvent.adminUsers) {
        admins.add(
          Text('${admin.firstName} ${admin.lastName} (${admin.email})'),
        );
      }
      admins.add(SizedBox(height: 10));
    }

    List<Widget> thisWeekEvent = [];
    if (_event.start.length > 0) {
      thisWeekEvent = [
        Text('This week\'s event starts at ${_event.start}'),
        SizedBox(height: 10),
      ];
    }

    bool alreadySignedUp = false;

    Map<String, dynamic> config = _configService.GetConfig();
    List<Widget> attendeeInfo = [
      Text('${_attendeesCount} attending, ${_nonHostAttendeesWaitingCount} waiting'),
      SizedBox(height: 10),
    ];
    if (_userEvent.id.length > 0) {
      if (_userEvent.hostGroupSizeMax > 0) {
        if (_userEvent.hostGroupSize == _userEvent.hostGroupSizeMax) {
          attendeeInfo += [
            Text('You are hosting ${_userEvent.hostGroupSize} people.'),
            SizedBox(height: 10),
          ];
        } else {
          int diff = _userEvent.hostGroupSizeMax - _userEvent.hostGroupSize;
          attendeeInfo += [
            Text('You are hosting ${_userEvent.hostGroupSize} people thus far, waiting on ${diff} more.'),
            SizedBox(height: 10),
            Text('Share this event with your neighbors to fill your spots: ${config['SERVER_URL']}/we/${_weeklyEvent.uName}'),
            SizedBox(height: 10),
          ];
        }
      }
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
            Text('Share this event with your neighbors: ${config['SERVER_URL']}/we/${_weeklyEvent.uName}'),
          ];
        } else {
          attendeeInfo += [
            Text('You are waiting on ${_userEvent.attendeeCountAsk} more spots.'),
            SizedBox(height: 10),
            Text('Share this event with your neighbors to get another host so you can join: ${config['SERVER_URL']}/we/${_weeklyEvent.uName}'),
            SizedBox(height: 10),
          ];
        }
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
    if (!alreadySignedUp) {
      String rsvpSignUpText = _rsvpDeadlinePassed > 0 ? 'RSVP deadline passed for this week\'s event, but you can sign up for next week\'s: ${_nextEvent.start}' : '';
      attendeeInfo += [
        Text(rsvpSignUpText),
        SizedBox(height: 10),
        UserWeeklyEventSave(weeklyEventId: _weeklyEvent.id),
        SizedBox(height: 10),
      ];
    }

    double width = 1200;
    return AppScaffoldComponent(
      listWrapper: true,
      width: width,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Mapbox(mapWidth: width!, mapHeight: 300,
            longitude: _weeklyEvent.location.coordinates[0], latitude: _weeklyEvent.location.coordinates[1],
            zoom: 17, markerLngLat: [_weeklyEvent.location.coordinates[0], _weeklyEvent.location.coordinates[1]],
          ),
          SizedBox(height: 10),
          Text('${_weeklyEvent.title}'),
          SizedBox(height: 10),
          Text('${_weeklyEvent.xDay}s ${_weeklyEvent.startTime} - ${_weeklyEvent.endTime}'),
          SizedBox(height: 10),
          ...thisWeekEvent,
          Text(_weeklyEvent.description),
          SizedBox(height: 10),
          ...admins,
          SizedBox(height: 10),
          Text('Share this event with your neighbors: ${config['SERVER_URL']}/we/${_weeklyEvent.uName}'),
          SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...buttons,
            ]
          ),
          SizedBox(height: 10),
          ...attendeeInfo,
          SizedBox(height: 10),
        ]
      ),
    );
  }
  
}
