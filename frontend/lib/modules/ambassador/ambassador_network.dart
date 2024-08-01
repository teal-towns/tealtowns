import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_scaffold.dart';
import '../../common/buttons.dart';
import '../../common/config_service.dart';
import '../../common/colors_service.dart';
import '../../common/date_time_service.dart';
import '../../common/form_input/input_fields.dart';
import '../../common/form_input/input_location.dart';
import '../../common/layout_service.dart';
import '../../common/socket_service.dart';
import '../../common/style.dart';
import '../../common/video.dart';
import '../user_auth/current_user_state.dart';

import '../event/weekly_event_class.dart';
import '../event/weekly_event_templates.dart';
import '../neighborhood/neighborhood_state.dart';

class AmbassadorNetwork extends StatefulWidget {
  int maxMeters;
  AmbassadorNetwork({ this.maxMeters = 1500, });

  @override
  _AmbassadorNetworkState createState() => _AmbassadorNetworkState();
}

class _AmbassadorNetworkState extends State<AmbassadorNetwork> {
  Buttons _buttons = Buttons();
  ColorsService _colors = ColorsService();
  ConfigService _configService = ConfigService();
  DateTimeService _dateTime = DateTimeService();
  InputFields _inputFields = InputFields();
  LayoutService _layoutService = LayoutService();
  Style _style = Style();
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();
  Video _video = Video();

  String _step = 'invite';
  Map<String, dynamic> _formVals = {
    'inputLocation': { 'lngLat': { 'coordinates': [0.0, 0.0] }, 'address': {} },
    'neighborhoodUName': '',
    'invitesString': '',
  };
  List<String> _invites = [];
  List<WeeklyEventClass> _weeklyEvents = [];
  List<WeeklyEventClass> _existingWeeklyEvents = [];
  bool _existingWeeklyEventsLoaded = false;
  String _message = '';
  bool _saving = false;
  String _eventsStep = 'existingEvents';
  List<double> _lngLat = [0.0, 0.0];

  @override
  void initState() {
    super.initState();

    var neighborhoodState = Provider.of<NeighborhoodState>(context, listen: false);
    if (neighborhoodState.defaultUserNeighborhood != null) {
      _lngLat = neighborhoodState.defaultUserNeighborhood!.neighborhood.location.coordinates;
      _formVals['neighborhoodUName'] = neighborhoodState.defaultUserNeighborhood!.neighborhood.uName;
      _formVals['inputLocation'] = { 'lngLat': {
          'coordinates': neighborhoodState.defaultUserNeighborhood!.neighborhood.location.coordinates,
        },
        'address': {},
      };
      var data = {
        'lngLat': _lngLat,
        'maxMeters': widget.maxMeters,
        'withAdmins': 0,
        'type': 'sharedItem',
      };
      _socketService.emit('SearchNearWeeklyEvents', data);
    } else {
      Timer(Duration(milliseconds: 200), () {
        context.go('/neighborhoods');
      });
    }

   _routeIds.add(_socketService.onRoute('SearchNearWeeklyEvents', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        if (data.containsKey('weeklyEvents')) {
          _existingWeeklyEvents = [];
          for (var item in data['weeklyEvents']) {
            WeeklyEventClass weeklyEvent = WeeklyEventClass.fromJson(item);
            if (neighborhoodState.defaultUserNeighborhood != null &&
              neighborhoodState.defaultUserNeighborhood.neighborhood.timezone.length > 0 &&
              neighborhoodState.defaultUserNeighborhood.neighborhood.timezone != weeklyEvent.timezone) {
              Map<String, dynamic> ret = _dateTime.WeekdayTimezone(weeklyEvent.dayOfWeek, weeklyEvent.startTime,
                weeklyEvent.timezone, neighborhoodState.defaultUserNeighborhood.neighborhood.timezone);
              weeklyEvent.timezone = neighborhoodState.defaultUserNeighborhood.neighborhood.timezone;
              weeklyEvent.dayOfWeek = ret['dayOfWeek'];
              weeklyEvent.startTime = ret['startTime'];
            }
            _existingWeeklyEvents.add(weeklyEvent);
          }
          _existingWeeklyEventsLoaded = true;
          setState(() { _existingWeeklyEvents = _existingWeeklyEvents;
            _existingWeeklyEventsLoaded = _existingWeeklyEventsLoaded; });
        }
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
      return AppScaffoldComponent(
        listWrapper: true,
        width: 1200,
        body: Text("You must be logged in"),
      );
    }
    String userId = currentUserState.currentUser!.id;
    Map<String, dynamic> config = _configService.GetConfig();

    List<Widget> cols = [];
    if (_step == 'invite') {
      cols += [
        Container(width: 800,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _style.Text1('Building a network of support of 10 other local ambassadors is the key to success. We suggest a weekly Share Something Walk to start the process of sharing small items with each other - board games, tools, sports equipment, and more.'),
              _style.SpacingH('medium'),
              _inputFields.inputText(_formVals, 'invitesString', minLen: 2, label: 'Add the emails or phones of some local friends',
                helpText: 'Who are 5 - 10 people within 15 minutes of you who you would like to start sharing with?',
                hint: '1-555-123-4567, joe@email.com',
              ),
              _style.SpacingH('medium'),
              ElevatedButton(child: Text('Next'), onPressed: () {
                _invites = [];
                if (_formVals['invitesString'].trim().length > 0) {
                  _invites = _formVals['invitesString'].trim().split(',');
                  for (var i = 0; i < _invites.length; i++) {
                    _invites[i] = _invites[i].trim();
                  }
                }
                if (_invites.length > 0) {
                  _step = 'events';
                  setState(() { _step = _step; });
                  _socketService.emit('UserInsightSetActionAt', { 'userId': userId, 'field': 'ambassadorNetworkStepsAt.events' });
                } else {
                  setState(() { _message = 'Please enter at least one invite.'; });
                }
              }),
            ],
          ),
        ),
      ];
    } else if (_step == 'events') {
      if (_eventsStep == 'existingEvents') {
        if (!_existingWeeklyEventsLoaded) {
          cols += [
            LinearProgressIndicator(),
          ];
        } else {
          if (_existingWeeklyEvents.length > 0) {
            List<Widget> items = [];
            for (var i = 0; i < _existingWeeklyEvents.length; i++) {
              items.add(
                Container(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Image.network(_existingWeeklyEvents[i].imageUrls[0], height: 100, width: double.infinity, fit: BoxFit.cover),
                      _style.SpacingH('medium'),
                      _style.Text1(_existingWeeklyEvents[i].title),
                      _style.SpacingH('medium'),
                      _style.Text1('${_existingWeeklyEvents[i].xDay} ${_existingWeeklyEvents[i].startTime}'),
                      _style.SpacingH('medium'),
                      ElevatedButton(child: Text('Select'), onPressed: () {
                        _weeklyEvents = [ _existingWeeklyEvents[i], ];
                        _step = 'confirm';
                        setState(() { _weeklyEvents = _weeklyEvents; _step = _step; });
                        _socketService.emit('UserInsightSetActionAt', { 'userId': userId, 'field': 'ambassadorNetworkStepsAt.confirm' });
                        var data = { 'invites': _invites, 'weeklyEventUName': _weeklyEvents[0].uName, 'userId': userId };
                        _socketService.emit('SendWeeklyEventInvites', data);
                      }),
                    ],
                  )
                )
              );
            }
            cols += [
              _style.Text1('Join an existing event near you, or create your own', size: 'large'),
              _style.SpacingH('medium'),
              _layoutService.WrapWidth(items, width: 200,),
              _style.SpacingH('medium'),
              TextButton(child: Text('OR Create New Event'), onPressed: () {
                _eventsStep = 'locationSelect';
                setState(() { _eventsStep = _eventsStep; });
              }),
            ];
          } else {
            _eventsStep = 'locationSelect';
            setState(() { _eventsStep = _eventsStep; });
          }
        }
      }
      if (_eventsStep == 'locationSelect') {
        String helpText = 'Pick a (green) space such as a park within 5 to 10 minutes from your home for a weekly Share Something Walk.';
        cols += [
          Container(width: 400,
            child: InputLocation(formVals: _formVals, formValsKey: 'inputLocation', label: 'Where will you have your event?', helpText: helpText,
              nestedCoordinates: true, guessLocation: true, fullScreen: true,
              onChanged: (Map<String, dynamic> val) {
                _eventsStep = 'eventTemplate';
                setState(() { _eventsStep = _eventsStep; });
              }
            ),
          ),
        ];
      }
      if (_eventsStep == 'eventTemplate') {
        cols += [
          WeeklyEventTemplates(location: _formVals['inputLocation']['lngLat'],
            locationAddress: _formVals['inputLocation']['address'],
            neighborhoodUName: _formVals['neighborhoodUName'],
            selectedKeys: ['shareSomethingWalk'],
            types: ['sharedItem'], maxEvents: 1,
            title: 'When would you like to have your weekly Share Something Walk?',
            onSave: (dynamic data) {
              _weeklyEvents = [];
              for (var weeklyEvent in data['weeklyEvents']) {
                _weeklyEvents.add(WeeklyEventClass.fromJson(weeklyEvent));
              }
              _step = 'confirm';
              setState(() { _weeklyEvents = _weeklyEvents; _step = _step; _saving = false; });
              _socketService.emit('UserInsightSetActionAt', { 'userId': userId, 'field': 'ambassadorNetworkStepsAt.confirm' });
              var data1 = { 'invites': _invites, 'weeklyEventUName': _weeklyEvents[0].uName, 'userId': userId };
              _socketService.emit('SendWeeklyEventInvites', data1);
            }
          ),
        ];
      }
    } else if (_step == 'confirm') {
      cols += [
        Container(width: 800,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _style.Text1('Event created and invites sent, the last step is to add the first items you would like to share!', size: 'large', colorKey: 'primary'),
              _style.SpacingH('medium'),
              // _style.Text1('Join the Slack and join and post an introduction in #8-ambassadors to get support on your journey.'),
              // _style.SpacingH('medium'),
              // _buttons.Link(context, 'Join Slack',
              //   'https://join.slack.com/t/tealtowns/shared_invite/zt-291gxxen8-LRs~9JmLHq8mqYUlzGncIQ', launchUrl: true),
              // _style.SpacingH('medium'),
              _style.Text1('Join the Ambassador Circle on WhatsApp to get support on your journey.'),
              _style.SpacingH('medium'),
              _buttons.Link(context, 'Join WhatsApp Ambassador Circle',
                'https://chat.whatsapp.com/F43i2Nwvhig695B8TN4NNk', launchUrl: true),
              _style.SpacingH('medium'),
              _buttons.LinkElevated(context, 'Sign Up for and Share Your Event', '/we/${_weeklyEvents[0].uName}'),
              _style.SpacingH('medium'),
            ],
          ),
        ),
      ];
    }

    List<Widget> colsMessage = [];
    if (_message.length > 0) {
      colsMessage += [
        _style.SpacingH('medium'),
        _style.Text1(_message),
        _style.SpacingH('medium'),
      ];
    }
    if (_saving) {
      colsMessage += [
        _style.SpacingH('medium'),
        LinearProgressIndicator(),
        _style.SpacingH('medium'),
      ];
    }

    // Video messes up full screen location select, so skip it.
    List<Widget> colsVideo = [];
    // TODO - create video and update video id
    // if (_step != 'events' || _eventsStep != 'locationSelect') {
    //   colsVideo += [
    //     _style.SpacingH('xlarge'),
    //     Container(height: 300,
    //       child: _video.Youtube('B-Gz9VCGoa0'),
    //     ),
    //     _style.SpacingH('medium'),
    //   ];
    // }

    return AppScaffoldComponent(
      listWrapper: true,
      width: 1200,
      body: Column(
        children: [
          _style.Text1('Build your Local Ambassador Network!', size: 'xlarge'),
          _style.SpacingH('medium'),
          ...cols,
          ...colsMessage,
          ...colsVideo,
        ]
      )
    );
  }
}
