import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app_scaffold.dart';
import '../../common/buttons.dart';
import '../../common/config_service.dart';
import '../../common/date_time_service.dart';
import '../../common/link_service.dart';
import '../../common/map/map_it.dart';
import '../../common/socket_service.dart';
import '../../common/style.dart';
import './event_class.dart';
import './event_insight_class.dart';
import './event_feedback.dart';
import './user_event_class.dart';
import './user_weekly_event_save.dart';
import './user_event_save.dart';
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
  Buttons _buttons = Buttons();
  ConfigService _configService = ConfigService();
  DateTimeService _dateTime = DateTimeService();
  LinkService _linkService = LinkService();
  SocketService _socketService = SocketService();
  Style _style = Style();

  bool _loading = true;
  String _message = '';

  bool _inited = false;
  WeeklyEventClass _weeklyEvent = WeeklyEventClass.fromJson({});
  EventClass _event = EventClass.fromJson({});
  EventClass _nextEvent = EventClass.fromJson({});
  EventInsightClass _eventInsight = EventInsightClass.fromJson({});
  int _rsvpDeadlinePassed = 0;
  int _attendeesCount = 0;
  int _nonHostAttendeesWaitingCount = 0;
  UserEventClass _userEvent = UserEventClass.fromJson({});
  List<UserEventClass> _userEvents = [];

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('getWeeklyEventById', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        if (data.containsKey('weeklyEvent')) {
          _weeklyEvent = WeeklyEventClass.fromJson(data['weeklyEvent']);
          if (data.containsKey('event')) {
            _event = EventClass.fromJson(data['event']);
          }
          if (data.containsKey('nextEvent')) {
            _nextEvent = EventClass.fromJson(data['nextEvent']);
          }
          if (data.containsKey('rsvpDeadlinePassed')) {
            _rsvpDeadlinePassed = data['rsvpDeadlinePassed'];
          }
          if (data.containsKey('attendeesCount')) {
            _attendeesCount = data['attendeesCount'];
          }
          if (data.containsKey('nonHostAttendeesWaitingCount')) {
            _nonHostAttendeesWaitingCount = data['nonHostAttendeesWaitingCount'];
          }
          if (data.containsKey('userEvent')) {
            _userEvent = UserEventClass.fromJson(data['userEvent']);
          }
          if (data.containsKey('eventInsight')) {
            _eventInsight = EventInsightClass.fromJson(data['eventInsight']);
          }
          setState(() {
            _weeklyEvent = _weeklyEvent;
            _event = _event;
            _nextEvent = _nextEvent;
            _rsvpDeadlinePassed = _rsvpDeadlinePassed;
            _attendeesCount = _attendeesCount;
            _nonHostAttendeesWaitingCount = _nonHostAttendeesWaitingCount;
            _userEvent = _userEvent;
            _eventInsight = _eventInsight;
          });
        } else {
          _message = 'Error.';
        }
      } else {
        _message = data['message'].length > 0 ? data['message'] : 'Error.';
        context.go('/weekly-events');
      }
      setState(() {
        _loading = false;
      });
    }));

    _routeIds.add(_socketService.onRoute('removeWeeklyEvent', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        context.go('/weekly-events');
      } else {
        _message = data['message'].length > 0 ? data['message'] : 'Error.';
      }
      setState(() {
        _loading = false;
      });
    }));

    _routeIds.add(_socketService.onRoute('GetUserEventUsers', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        _userEvents = [];
        for (var i = 0; i < data['userEvents'].length; i++) {
          _userEvents.add(UserEventClass.fromJson(data['userEvents'][i]));
        }
        setState(() { _userEvents = _userEvents; });
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
    if (!_inited) {
      _inited = true;
      var data = {
        // 'id': widget.id,
        'uName': widget.uName,
        'withAdmins': 1,
        'withEvent': 1,
        'withUserEvents': 1,
        'withUserId': currentUserState.isLoggedIn ? currentUserState.currentUser.id : '',
        'withEventInsight': 1,
      };
      _socketService.emit('getWeeklyEventById', data);
    }

    if (_loading) {
      return AppScaffoldComponent(
        listWrapper: true,
        body: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Column( children: [ LinearProgressIndicator() ] ),
        )
      );
    }

    List<Widget> buttons = [];
    if (currentUserState.isLoggedIn && _weeklyEvent.adminUserIds.contains(currentUserState.currentUser.id)) {
      buttons = [
        ElevatedButton(
          onPressed: () {
            _linkService.Go('/weekly-event-save?id=${_weeklyEvent.id}', context, currentUserState: currentUserState);
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
            foregroundColor: Theme.of(context).colorScheme.error,
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
      String startDate = _dateTime.Format(_event.start, 'EEEE M/d/y');
      thisWeekEvent = [
        // Text('This week\'s event starts at ${_event.start}'),
        // SizedBox(height: 10),
        _style.Text1('${startDate}', left: Icon(Icons.calendar_today)),
        SizedBox(height: 10),
        _style.Text1('${_weeklyEvent.startTime} - ${_weeklyEvent.endTime}', left: Icon(Icons.schedule)),
        SizedBox(height: 10),
      ];
    }

    bool alreadySignedUp = false;

    Map<String, dynamic> config = _configService.GetConfig();

    String shareUrl = '${config['SERVER_URL']}/we/${_weeklyEvent.uName}';
    List<Widget> colsShareQR = [
      QrImageView(
        data: shareUrl,
        version: QrVersions.auto,
        size: 200.0,
      ),
      SizedBox(height: 10),
      Text(shareUrl),
      SizedBox(height: 10),
    ];
    List<Widget> colsShare = [
      Text(shareUrl),
      SizedBox(height: 10),
    ];

    String text1 = '${_attendeesCount} attending';
    if (_nonHostAttendeesWaitingCount > 0) {
      text1 += ', ${_nonHostAttendeesWaitingCount} waiting';
    }
    List<Widget> attendeeInfo = [
      // Text(text1),
      TextButton(
        onPressed: () {
          _socketService.emit('GetUserEventUsers', { 'eventId': _event.id });
        },
        child: Text(text1),
      ),
      SizedBox(height: 10),
    ];
    if (_userEvents.length > 0) {
      List<String> hostTexts = [];
      List<String> attendeeTexts = [];
      List<String> waitingHostTexts = [];
      List<String> waitingTexts = [];
      for (int i = 0; i < _userEvents.length; i++) {
        String rsvpNote = _userEvents[i].rsvpNote;
        String text = '';
        if (_userEvents[i].attendeeCount == 0) {
          text = '${_userEvents[i].user['firstName']} ${_userEvents[i].user['lastName']}';
          if (rsvpNote.length > 0) {
            if (_userEvents[i].hostGroupSizeMax > 0) {
              text += ' (${_userEvents[i].hostGroupSizeMax}, ${rsvpNote})';
            } else {
              text += ' (${rsvpNote})';
            }
          } else if (_userEvents[i].hostGroupSizeMax > 0) {
            text += ' (${_userEvents[i].hostGroupSizeMax})';
          }
          if (_userEvents[i].hostGroupSizeMax > 0) {
            waitingHostTexts.add(text);
          } else {
            waitingTexts.add(text);
          }
        } else {
          String text = '${_userEvents[i].user['firstName']} ${_userEvents[i].user['lastName']}';
          if (_userEvents[i].attendeeCount > 1) {
            if (rsvpNote.length > 0) {
              text += ' (+${_userEvents[i].attendeeCount - 1}, ${rsvpNote})';
            } else {
              text += ' (+${_userEvents[i].attendeeCount - 1})';
            }
          } else if (rsvpNote.length > 0) {
            text += ' (${rsvpNote})';
          }
          if (_userEvents[i].hostGroupSize > 0) {
            hostTexts.add(text);
          } else {
            attendeeTexts.add(text);
          }
        }
      }
      if (hostTexts.length > 0) {
        hostTexts.sort();
        attendeeInfo += [
          Text('${hostTexts.length} Hosting'),
          Text('${hostTexts.join(', ')}'),
        ];
      }
      if (waitingHostTexts.length > 0) {
        waitingHostTexts.sort();
        attendeeInfo += [
          Text('${waitingHostTexts.length} Waiting to Host'),
          Text('${waitingHostTexts.join(', ')}'),
        ];
      }
      if (attendeeTexts.length > 0) {
        attendeeTexts.sort();
        attendeeInfo += [
          Text('${attendeeTexts.length} Attending'),
          Text('${attendeeTexts.join(', ')}'),
        ];
      }
      if (waitingTexts.length > 0) {
        waitingTexts.sort();
        attendeeInfo += [
          Text('${waitingTexts.length} Waiting'),
          Text('${waitingTexts.join(', ')}'),
        ];
      }
      attendeeInfo += [ SizedBox(height: 10) ];
    }
    if (_weeklyEvent.priceUSD == 0) {
      attendeeInfo += [
        // Text('This is a free event, no RSVP required!'),
        // SizedBox(height: 10),
        ...colsShare,
      ];
    } else {
      if (_userEvent.id.length > 0) {
        if (_userEvent.attendeeCountAsk > 0) {
          alreadySignedUp = true;
        }
        // This is already shown in UserEventSave
        // if (_userEvent.hostGroupSizeMax > 0) {
        //   if (_userEvent.hostGroupSize == _userEvent.hostGroupSizeMax) {
        //     attendeeInfo += [
        //       Text('You are hosting ${_userEvent.hostGroupSize} people.'),
        //       SizedBox(height: 10),
        //     ];
        //   } else {
        //     int diff = _userEvent.hostGroupSizeMax - _userEvent.hostGroupSize;
        //     attendeeInfo += [
        //       Text('You are hosting ${_userEvent.hostGroupSize} people thus far, waiting on ${diff} more.'),
        //       SizedBox(height: 10),
        //       Text('Share this event with your neighbors to fill your spots:'),
        //       SizedBox(height: 10),
        //       ...colsShare,
        //     ];
        //   }
        // }
        // if (_userEvent.attendeeCountAsk > 0) {
        //   if (_userEvent.attendeeCount > 0) {
        //     int guestsGoing = _userEvent.attendeeCount - 1;
        //     int guestsWaiting = _userEvent.attendeeCountAsk - _userEvent.attendeeCount - 1;
        //     String text1 = 'You are going';
        //     if (guestsGoing > 0) {
        //       text1 += ', with ${guestsGoing} guests';
        //     }
        //     if (guestsWaiting > 0) {
        //       text1 += ', waiting on ${guestsWaiting} more spots';
        //     }
        //     attendeeInfo += [
        //       Text(text1),
        //       SizedBox(height: 10),
        //       Text('Share this event with your neighbors:'),
        //       SizedBox(height: 10),
        //       ...colsShare,
        //     ];
        //   } else {
        //     attendeeInfo += [
        //       Text('You are waiting on ${_userEvent.attendeeCountAsk} more spots.'),
        //       SizedBox(height: 10),
        //       Text('Share this event with your neighbors to get another host so you can join:'),
        //       SizedBox(height: 10),
        //       ...colsShare,
        //     ];
        //   }
        // }
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
    }
    if (!alreadySignedUp) {
      String startDate = _dateTime.Format(_nextEvent.start, 'EEEE M/d/y');
      String rsvpSignUpText = _rsvpDeadlinePassed > 0 ? 'RSVP deadline passed for this week\'s event, but you can sign up for next week\'s: ${startDate}' : '';
      attendeeInfo += [
        Text(rsvpSignUpText),
        SizedBox(height: 10),
        UserWeeklyEventSave(weeklyEventId: _weeklyEvent.id),
        SizedBox(height: 10),
      ];
    } else {
      attendeeInfo += [
        UserEventSave(eventId: _userEvent.eventId),
        SizedBox(height: 10),
      ];
    }

    String format = 'yMMdTHHmmss';
    String start1 = _dateTime.Format(_event.start, format);
    String end1 = _event.end.length > 0 ? _event.end : _event.start;
    end1 = _dateTime.Format(end1, format);
    String timezone = _weeklyEvent.timezone;
    String details = Uri.encodeComponent(shareUrl);
    String title = Uri.encodeComponent(_weeklyEvent.title);
    String location = Uri.encodeComponent('${_weeklyEvent.location.coordinates[1]},${_weeklyEvent.location.coordinates[0]}');
    // https://www.labnol.org/calendar/
    // https://calendar.google.com/calendar/render?action=TEMPLATE&dates=20240517T021500Z%2F20240517T024500Z&details=https%3A%2F%2Ftest.com%2Fyes&text=Todos%20Santos%20Park%20Day
    List<Map<String, String>> calendarLinks = [
      { 'name': 'Google', 'url': 'https://calendar.google.com/calendar/render?action=TEMPLATE&dates=${start1}%2F${end1}&details=${details}&text=${title}&location=${location}&ctz=${timezone}' },
    ];
    List<Widget> colsCalendar = [
      Text('Add to your calendar:'),
      SizedBox(height: 10),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          ...calendarLinks.map<Widget>((link) {
            return _buttons.Link(context, link['name']!, link['url']!, launchUrl: true);
          })
        ]
      )
    ];

    List<Widget> colsInsights = [];
    if (_eventInsight.viewsAt.length > 0) {
      colsInsights += [
        Text('${_eventInsight.viewsAt.length} views'),
        SizedBox(height: 10),
      ];
    }

    Widget content1 = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _style.Text1('${_weeklyEvent.title}', size: 'xlarge'),
        SizedBox(height: 10),
        _weeklyEvent.imageUrls.length <= 0 ?
          Image.asset('assets/images/shared-meal.jpg', height: 300, width: double.infinity, fit: BoxFit.cover,)
            : Image.network(_weeklyEvent.imageUrls![0], height: 300, width: double.infinity, fit: BoxFit.cover),
        SizedBox(height: 10),
        Text(_weeklyEvent.description),
        SizedBox(height: 10),
        // _style.Text1('${_weeklyEvent.xDay}s ${_weeklyEvent.startTime} - ${_weeklyEvent.endTime}',
        //     left: Icon(Icons.calendar_today)),
        ...thisWeekEvent,
        ...attendeeInfo,
        SizedBox(height: 10),
        EventFeedback(weeklyEventId: _weeklyEvent.id),
        SizedBox(height: 10),
      ]
    );

    Widget content2 = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MapIt(mapHeight: 300,
          longitude: _weeklyEvent.location.coordinates[0], latitude: _weeklyEvent.location.coordinates[1],
          zoom: 17, markerLngLat: [_weeklyEvent.location.coordinates[0], _weeklyEvent.location.coordinates[1]],
        ),
        SizedBox(height: 10),
        ...admins,
        SizedBox(height: 10),
        ...colsCalendar,
        SizedBox(height: 10),
        Text('Share this event with your neighbors:'),
        SizedBox(height: 10),
        ...colsShareQR,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...buttons,
          ]
        ),
        ...colsInsights,
        SizedBox(height: 10),
      ]
    );

    double width = 1200;
    return AppScaffoldComponent(
      listWrapper: true,
      width: width,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: content1),
                SizedBox(width: 10),
                Expanded(flex: 1, child: content2),
              ]
            );
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                content1,
                SizedBox(height: 10),
                content2,
              ]
            );
          }
        }
      )
    );
  }
  
}
