import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sentry/sentry.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../app_scaffold.dart';
import '../../common/alert_service.dart';
import '../../common/buttons.dart';
import '../../common/config_service.dart';
import '../../common/date_time_service.dart';
import '../../common/ip_service.dart';
import '../../common/link_service.dart';
import '../../common/location_service.dart';
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
import '../icebreaker/icebreaker_class.dart';
import '../user_auth/current_user_state.dart';

class WeeklyEventView extends StatefulWidget {
  String uName;

  WeeklyEventView({ this.uName = '', });

  @override
  _WeeklyEventViewState createState() => _WeeklyEventViewState();
}

class _WeeklyEventViewState extends State<WeeklyEventView> {
  List<String> _routeIds = [];
  AlertService _alertService = AlertService();
  Buttons _buttons = Buttons();
  ConfigService _configService = ConfigService();
  DateTimeService _dateTime = DateTimeService();
  IPService _ipService = IPService();
  LocationService _locationService = LocationService();
  LinkService _linkService = LinkService();
  SocketService _socketService = SocketService();
  Style _style = Style();
  late YoutubePlayerController _youtubeController;

  bool _loading = true;
  String _message = '';
  bool _loadingIP = true;
  bool _initedIP = false;

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
  List<IcebreakerClass> _icebreakers = [];

  // Stopwatch stopwatch = new Stopwatch()..start();
  bool _initialLoadDone = false;
  final _transaction = Sentry.startTransaction('weekly_event_view render', 'task');
  bool _initialWeeklyEventLoaded = false;

  @override
  void initState() {
    super.initState();

    _youtubeController = YoutubePlayerController.fromVideoId(
      videoId: '2Rm2kM36c5g',
      autoPlay: false,
      params: const YoutubePlayerParams(showFullscreenButton: false),
    );

    _routeIds.add(_socketService.onRoute('GetWeeklyEventByIdWithData', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        var states = {};
        if (data.containsKey('weeklyEvent') && data['weeklyEvent'].containsKey('_id') && data['weeklyEvent']['uName'] == widget.uName) {
          if (!_initialWeeklyEventLoaded) {
            _weeklyEvent = WeeklyEventClass.fromJson(data['weeklyEvent']);
            setState(() { _weeklyEvent = _weeklyEvent; });
            _socketService.emit('GetRandomIcebreakers', {'count': 1});
            _initialWeeklyEventLoaded = true;
          }
        }
        if (data.containsKey('event') && data['event'].containsKey('_id') &&
          data.containsKey('nextEvent') && data['nextEvent'].containsKey('_id')) {
          _event = EventClass.fromJson(data['event']);
          _nextEvent = EventClass.fromJson(data['nextEvent']);
          _rsvpDeadlinePassed = data['rsvpDeadlinePassed'];
          setState(() { _event = _event; _nextEvent = _nextEvent; _rsvpDeadlinePassed = _rsvpDeadlinePassed; });
        }
        if (data.containsKey('attendeesCount')) {
          _attendeesCount = data['attendeesCount'];
          _nonHostAttendeesWaitingCount = data['nonHostAttendeesWaitingCount'];
          setState(() { _attendeesCount = _attendeesCount; _nonHostAttendeesWaitingCount = _nonHostAttendeesWaitingCount; });
        }
        if (data.containsKey('userEvent')) {
          _userEvent = UserEventClass.fromJson(data['userEvent']);
          setState(() { _userEvent = _userEvent; });
        }
        if (data.containsKey('eventInsight') && data['eventInsight'] != null &&
          data['eventInsight'].containsKey('_id')) {
          _eventInsight = EventInsightClass.fromJson(data['eventInsight']);
          setState(() { _eventInsight = _eventInsight; });
        }
        setState(() {
          _loading = false;
        });
        // } else {
        //   _message = data['message'].length > 0 ? data['message'] : 'Error.';
        //   context.go('/weekly-events');
        // }
      } else {
        _message = data['message'].length > 0 ? data['message'] : 'Error.';
        context.go('/weekly-events');
      }
      // setState(() {
      //   _loading = false;
      // });
    }));

    _routeIds.add(_socketService.onRoute('GetUserEventStats', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        if (data.containsKey('attendeesCount')) {
          _attendeesCount = data['attendeesCount'];
          _nonHostAttendeesWaitingCount = data['nonHostAttendeesWaitingCount'];
          setState(() { _attendeesCount = _attendeesCount; _nonHostAttendeesWaitingCount = _nonHostAttendeesWaitingCount; });
        }
      }
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

    _routeIds.add(_socketService.onRoute('GetRandomIcebreakers', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        _icebreakers = [];
        for (var i = 0; i < data['icebreakers'].length; i++) {
          _icebreakers.add(IcebreakerClass.fromJson(data['icebreakers'][i]));
        }
        setState(() { _icebreakers = _icebreakers; });
      }
    }));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init();
    });
  }

  @override
  void dispose() {
    _socketService.offRouteIds(_routeIds);
    super.dispose();
  }

  void _init() async {
    await _ipService.GetIPAddress();
    setState(() { _loadingIP = false; });
  }

  @override
  Widget build(BuildContext context) {
    var currentUserState = context.watch<CurrentUserState>();
    if (_ipService.IsLoaded() || currentUserState.isLoggedIn) {
      _loadingIP = false;
    }
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
        // 'userOrIP': currentUserState.isLoggedIn ? 'user_' + currentUserState.currentUser.id : _ipService.IP(),
        'addEventView': 0,
      };
      _socketService.emit('GetWeeklyEventByIdWithData', data);
    }
    if (!_initedIP && !_loadingIP && _event.id.length > 0) {
      _initedIP = true;
      var data = {
        'eventId': _event.id,
        'userOrIP': currentUserState.isLoggedIn ? 'user_' + currentUserState.currentUser.id : _ipService.IP(),
      };
      _socketService.emit('AddEventInsightView', data);
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
    if (currentUserState.isLoggedIn && (_weeklyEvent.adminUserIds.contains(currentUserState.currentUser.id)
      || currentUserState.hasRole('admin'))) {
      buttons = [
        TextButton(
          onPressed: () {
            _linkService.Go('/weekly-event-save?id=${_weeklyEvent.id}', context, currentUserState: currentUserState);
          },
          child: Text('Edit'),
        ),
        SizedBox(width: 10),
        TextButton(
          onPressed: () {
            _socketService.emit('removeWeeklyEvent', { 'id': _weeklyEvent.id });
          },
          child: Text('Delete'),
          style: TextButton.styleFrom(
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
      String startTime = _dateTime.Format(_event.start, 'HH:mm');
      String endTime = _dateTime.Format(_event.end, 'HH:mm');
      thisWeekEvent = [
        // Text('This week\'s event starts at ${_event.start}'),
        // SizedBox(height: 10),
        _style.Text1('${startDate}', left: Icon(Icons.calendar_today)),
        SizedBox(height: 10),
        // _style.Text1('${_weeklyEvent.startTime} - ${_weeklyEvent.endTime}', left: Icon(Icons.schedule)),
        _style.Text1('${startTime} - ${endTime}', left: Icon(Icons.schedule)),
        SizedBox(height: 10),
      ];
    }

    bool alreadySignedUp = false;
    if (_userEvent.id.length > 0) {
      if (_userEvent.attendeeCountAsk > 0) {
        alreadySignedUp = true;
      }
    }

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
    List<Widget> attendeeInfo = [];
    if (_attendeesCount > 0 || _nonHostAttendeesWaitingCount > 0) {
      attendeeInfo = [
        // Text(text1),
        TextButton(
          onPressed: () {
            _socketService.emit('GetUserEventUsers', { 'eventId': _event.id });
          },
          child: Text(text1),
        ),
        SizedBox(height: 10),
      ];
    }
    if (_userEvents.length > 0) {
      List<String> hostTexts = [];
      List<String> attendeeTexts = [];
      List<String> waitingHostTexts = [];
      List<String> waitingTexts = [];
      bool showEmail = currentUserState.isLoggedIn && _weeklyEvent.adminUserIds.contains(currentUserState.currentUser.id) ? true : false;
      for (int i = 0; i < _userEvents.length; i++) {
        String rsvpNote = _userEvents[i].rsvpNote;
        String text = '';
        if (_userEvents[i].attendeeCount == 0) {
          text = '${_userEvents[i].user['firstName']} ${_userEvents[i].user['lastName']}';
          if (showEmail) {
            text += ' (${_userEvents[i].user['email']})';
          }
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
          if (showEmail) {
            text += ' (${_userEvents[i].user['email']})';
          }
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

    if (_nextEvent.start.length > 0) {
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
          UserEventSave(eventId: _userEvent.eventId, onUpdate: () {
            _alertService.Show(context, 'RSVP Updated');
            setState(() { _userEvents = []; });
            _socketService.emit('GetUserEventStats', { 'eventId': _userEvent.eventId });
          }),
          SizedBox(height: 10),
        ];
      }
    }

    List<Widget> colsCalendar = [];
    if (_event.start.length > 0) {
      String format = 'yMMdTHHmmss';
      String start1 = _dateTime.Format(_event.start, format, local: true);
      String end1 = _event.end.length > 0 ? _event.end : _event.start;
      end1 = _dateTime.Format(end1, format, local: true);
      // String timezone = _weeklyEvent.timezone;
      String timezone = Uri.encodeComponent(_dateTime.TZ(_event.start, local: true));
      String details = Uri.encodeComponent(shareUrl);
      String title = Uri.encodeComponent(_weeklyEvent.title);
      String location = Uri.encodeComponent('${_weeklyEvent.location.coordinates[1]},${_weeklyEvent.location.coordinates[0]}');
      // https://www.labnol.org/calendar/
      // https://calendar.google.com/calendar/render?action=TEMPLATE&dates=20240517T021500Z%2F20240517T024500Z&details=https%3A%2F%2Ftest.com%2Fyes&text=Todos%20Santos%20Park%20Day
      List<Map<String, String>> calendarLinks = [
        { 'name': 'Google', 'url': 'https://calendar.google.com/calendar/render?action=TEMPLATE&dates=${start1}%2F${end1}&details=${details}&text=${title}&location=${location}&ctz=${timezone}' },
      ];
      colsCalendar = [
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
    }

    List<Widget> colsInsights = [];
    if (_eventInsight.uniqueViewsAt.length > 0) {
      colsInsights += [
        Text('${_eventInsight.uniqueViewsAt.length} unique views'),
        SizedBox(height: 10),
      ];
    }

    List<Widget> colsIcebreakers = [];
    if (_icebreakers.length > 0 && alreadySignedUp) {
      colsIcebreakers += [
        Text('Icebreaker: ${_icebreakers[0].icebreaker}'),
        SizedBox(height: 10),
      ];
    }

    List<Widget> colsAddress = [];
    String address = _locationService.JoinAddress(_weeklyEvent.locationAddress);
    if (address.length > 0) {
      colsAddress += [
        Text(address),
        SizedBox(height: 10),
      ];
    }

    List<Widget> colsSharedItem = [];
    if (_weeklyEvent.type == 'sharedItem') {
      String linkTemp = '/own?lng=${_weeklyEvent.location.coordinates[0]}&lat=${_weeklyEvent.location.coordinates[1]}&range=3500';
      colsSharedItem += [
        _buttons.Link(context, 'View and Post Shared Items', linkTemp, launchUrl: true),
        SizedBox(height: 10),
      ];
    }

    List<Widget> colsTags = [];
    if (_weeklyEvent.tags.length > 0) {
      colsTags += [
        Text('Tags: ${_weeklyEvent.tags.join(', ')}'),
        SizedBox(height: 10),
      ];
    }
    Widget content1 = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _weeklyEvent.imageUrls.length <= 0 ?
          Image.asset('assets/images/shared-meal.jpg', height: 300, width: double.infinity, fit: BoxFit.cover,)
            : Image.network(_weeklyEvent.imageUrls![0], height: 300, width: double.infinity, fit: BoxFit.cover),
        SizedBox(height: 10),
        _style.Text1('${_weeklyEvent.title}', size: 'xlarge', colorKey: 'primary'),
        SizedBox(height: 30),
        Row(
          children: [
            Image.asset('assets/images/logo.png', width: 30, height: 30),
            SizedBox(width: 10),
            _style.Text1('Description', size: 'large', colorKey: 'primary'),
          ]
        ),
        SizedBox(height: 10),
        MarkdownBody(
          selectable: true,
          data: _weeklyEvent.description!,
          onTapLink: (text, href, title) {
            launch(href!);
          },
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
            h1: Theme.of(context).textTheme.displayLarge,
            h2: Theme.of(context).textTheme.displayMedium,
            h3: Theme.of(context).textTheme.displaySmall,
            h4: Theme.of(context).textTheme.headlineMedium,
            h5: Theme.of(context).textTheme.headlineSmall,
            h6: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        SizedBox(height: 10),
        ...colsTags,
        ...colsSharedItem,
        SizedBox(height: 20),
        Row(
          children: [
            Image.asset('assets/images/logo.png', width: 30, height: 30),
            SizedBox(width: 10),
            _style.Text1('Event Details', size: 'large', colorKey: 'primary'),
          ]
        ),
        SizedBox(height: 10),
        // _style.Text1('${_weeklyEvent.xDay}s ${_weeklyEvent.startTime} - ${_weeklyEvent.endTime}',
        //     left: Icon(Icons.calendar_today)),
        ...thisWeekEvent,
        ...attendeeInfo,
        SizedBox(height: 10),
        EventFeedback(weeklyEventId: _weeklyEvent.id, showDetails: 0,),
        SizedBox(height: 10),
        ...colsIcebreakers,
        SizedBox(height: 10),
        // Container(height: 300, width: 533,
        YoutubePlayer(
          controller: _youtubeController,
          aspectRatio: 16 / 9,
        ),
        // ),
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
        ...colsAddress,
        ...admins,
        SizedBox(height: 10),
        ...colsCalendar,
        SizedBox(height: 10),
        Text('Share this event with your neighbors:'),
        SizedBox(height: 10),
        ...colsShareQR,
        _buttons.Link(context, 'Print Flyer', '/wep/${_weeklyEvent.uName}'),
        SizedBox(height: 10),
        Text('Can\'t make this time or interested in other events?'),
        SizedBox(height: 10),
        _buttons.LinkElevated(context, 'View All Events', '/ne/${_weeklyEvent.neighborhoodUName}'),
        SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...buttons,
          ]
        ),
        SizedBox(height: 10),
        ...colsInsights,
        SizedBox(height: 10),
      ]
    );

    double width = 1200;
    if (!_initialLoadDone) {
      _initialLoadDone = true;
      // final transaction = Sentry.getSpan();
      // transaction?.setMeasurement('weekly_event_view.render',
      //   stopwatch.elapsedMilliseconds / 1000);
      _transaction.finish();
      // print ('render ${stopwatch.elapsedMilliseconds / 1000}');
      // stopwatch.stop();
    }
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
