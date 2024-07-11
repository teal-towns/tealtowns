import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_scaffold.dart';
import '../../common/buttons.dart';
import '../../common/config_service.dart';
import '../../common/colors_service.dart';
import '../../common/form_input/input_fields.dart';
import '../../common/form_input/input_location.dart';
import '../../common/ip_service.dart';
import '../../common/layout_service.dart';
import '../../common/socket_service.dart';
import '../../common/style.dart';
import '../../common/video.dart';
import '../user_auth/current_user_state.dart';

// import '../neighborhood/neighborhood_save.dart';
import '../neighborhood/user_neighborhood_save.dart';
import '../neighborhood/neighborhood_state.dart';
import '../neighborhood/neighborhood_class.dart';
import '../user_auth/user_signup.dart';
import '../event/weekly_event_class.dart';
import '../event/weekly_event_templates.dart';

class AmbassadorStart extends StatefulWidget {
  @override
  _AmbassadorStartState createState() => _AmbassadorStartState();
}

class _AmbassadorStartState extends State<AmbassadorStart> {
  Buttons _buttons = Buttons();
  ColorsService _colors = ColorsService();
  ConfigService _configService = ConfigService();
  InputFields _inputFields = InputFields();
  IPService _ipService = IPService();
  LayoutService _layoutService = LayoutService();
  Style _style = Style();
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();
  Video _video = Video();

  String _step = 'signUp';
  Map<String, dynamic> _formVals = {
    'inputLocation': { 'lngLat': { 'coordinates': [0.0, 0.0] }, 'address': {} },
    'neighborhoodUName': '',
    'motivations': [],
    'vision': '',
  };
  List<WeeklyEventClass> _weeklyEvents = [];
  String _message = '';
  bool _saving = false;
  bool _loadingIP = true;
  bool _initedIP = false;

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('SaveNeighborhood', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        var currentUserState = Provider.of<CurrentUserState>(context, listen: false);
        var userNeighborhood = {};
        if (data.containsKey('userNeighborhood')) {
          userNeighborhood = data['userNeighborhood'];
        } else {
          userNeighborhood['status'] = 'default';
        }
        userNeighborhood['userId'] = currentUserState.currentUser!.id;
        userNeighborhood['neighborhoodUName'] = _formVals['neighborhoodUName'];
        userNeighborhood['motivations'] = _formVals['motivations'];
        userNeighborhood['vision'] = _formVals['vision'];
        Map<String, dynamic> dataSend = {
          'userNeighborhood': userNeighborhood,
        };
        _socketService.emit('SaveUserNeighborhood', dataSend);
        setState(() { _message = ''; });
      } else {
        setState(() { _message = data['message'].length > 0 ? data['message'] : 'Error, please try again.'; _saving = false; });
      }
    }));

    _routeIds.add(_socketService.onRoute('SaveUserNeighborhood', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        String userId = Provider.of<CurrentUserState>(context, listen: false).isLoggedIn ?
          Provider.of<CurrentUserState>(context, listen: false).currentUser.id : '';
        if (userId.length > 0) {
          var neighborhoodState = Provider.of<NeighborhoodState>(context, listen: false);
          neighborhoodState.CheckAndGet(userId);
        }
        _step = 'events';
        setState(() { _step = _step; _saving = false; });
        _socketService.emit('UserInsightSetActionAt', { 'userId': userId, 'field': 'ambassadorSignUpStepsAt.events' });
      } else {
        setState(() { _message = data['message'].length > 0 ? data['message'] : 'Error, please try again.'; _saving = false; });
      }
    }));

    // _routeIds.add(_socketService.onRoute('SaveWeeklyEvents', callback: (String resString) {
    //   var res = json.decode(resString);
    //   var data = res['data'];
    //   if (data['valid'] == 1) {
    //     _weeklyEvents = [];
    //     for (var weeklyEvent in data['weeklyEvents']) {
    //       _weeklyEvents.add(WeeklyEventClass.fromJson(weeklyEvent));
    //     }
    //     _step = 'resources';
    //     setState(() { _weeklyEvents = _weeklyEvents; _step = _step; _saving = false; });
    //     String userId = Provider.of<CurrentUserState>(context, listen: false).currentUser.id;
    //     _socketService.emit('UserInsightSetActionAt', { 'userId': userId, 'field': 'ambassadorSignUpStepsAt.resources' });
    //   } else {
    //     setState(() { _message = data['message'].length > 0 ? data['message'] : 'Error, please try again.'; _saving = false; });
    //   }
    // }));

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
    if (!_initedIP && (_ipService.IsLoaded() || currentUserState.isLoggedIn)) {
      _initedIP = true;
      _loadingIP = false;
      var data = {
        'fieldKey': 'ambassadorSignUpUniqueViewsAt',
        'userOrIP': currentUserState.isLoggedIn ? 'user_' + currentUserState.currentUser.id : _ipService.IP(),
      };
      _socketService.emit('AddAppInsightView', data);
    }

    if (currentUserState.isLoggedIn && _step == 'signUp') {
      _step = 'userNeighborhoodSave';
      _socketService.emit('UserInsightSetActionAt', { 'userId': currentUserState.currentUser.id, 'field': 'ambassadorSignUpStepsAt.userNeighborhoodSave' });
    }

    List<Widget> cols = [];
    if (_step == 'signUp') {
      cols += [
        Container(width: 400,
          child: UserSignup(withScaffold: false, redirectOnDone: false, onSave: (dynamic data) {
            _step = 'userNeighborhoodSave';
            setState(() { _step = _step; });
            _socketService.emit('UserInsightSetActionAt', { 'userId': currentUserState.currentUser.id, 'field': 'ambassadorSignUpStepsAt.userNeighborhoodSave' });
          }),
        ),
      ];
    } else if (_step == 'userNeighborhoodSave') {
      List<Widget> colsText = [
        _style.Text1('To be an ambassador, the weekly responsibilities (about 1 hour per week) are:'),
        _style.SpacingH('medium'),
        _style.Text1('1. Invite 10 neighbors to join an event.'),
        _style.SpacingH('medium'),
        _style.Text1('2. Attend 1 event (and fill out feedback).'),
        _style.SpacingH('medium'),
      ];
      cols += [
        UserNeighborhoodSave(withScaffold: false, colsText: colsText, requireNeighborhoodUName: false,
          routeSave: '', onSave: (dynamic data) {
          _formVals['motivations'] = data['motivations'];
          _formVals['vision'] = data['vision'];
          _step = 'locationSelect';
          setState(() { _step = _step; });
          _socketService.emit('UserInsightSetActionAt', { 'userId': currentUserState.currentUser.id, 'field': 'ambassadorSignUpStepsAt.locationSelect' });
        }),
      ];
    } else if (_step == 'locationSelect') {
      String helpText = 'Pick a space 1-2 minutes walk from you, such as your front yard, street in front of your house, apartment courtyard, or park across the street.';
      cols += [
        Container(width: 400,
          child: InputLocation(formVals: _formVals, formValsKey: 'inputLocation', label: 'Where will you have your event?', helpText: helpText,
            nestedCoordinates: true, guessLocation: true, fullScreen: true,
            onChanged: (Map<String, dynamic> val) {
              _step = 'neighborhoodUName';
              setState(() { _step = _step; });
              _socketService.emit('UserInsightSetActionAt', { 'userId': currentUserState.currentUser.id, 'field': 'ambassadorSignUpStepsAt.neighborhoodUName' });
            }
          ),
        ),
      ];
    } else if (_step == 'neighborhoodUName') {
      cols += [
        Container(width: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _inputFields.inputText(_formVals, 'neighborhoodUName', minLen: 2, label: 'Choose a short name for your neighborhood',
                onChanged: (String val) {
                  setState(() { _formVals['neighborhoodUName'] = val; });
                }
              ),
              _style.SpacingH('medium'),
              ElevatedButton(child: Text('Next'), onPressed: () {
                Map<String, dynamic> data = {
                  'neighborhood': {
                    'location': _formVals['inputLocation']['lngLat'],
                    'uName': _formVals['neighborhoodUName'],
                    'title': _formVals['neighborhoodUName'],
                  },
                  'userId': Provider.of<CurrentUserState>(context, listen: false).currentUser.id,
                };
                data['neighborhood'] = NeighborhoodClass.fromJson(data['neighborhood']).toJson();
                setState(() { _saving = true; });
                _socketService.emit('SaveNeighborhood', data);
              }),
            ],
          ),
        ),
      ];
    // } else if (_step == 'neighborhoodSave') {
    //   cols += [
    //     NeighborhoodSave(withScaffold: false, onSave: (dynamic data) {
    //       _step = 'userNeighborhoodSave';
    //       setState(() { _step = _step; });
    //     }),
    //   ];
    } else if (_step == 'events') {
      cols += [
        WeeklyEventTemplates(location: _formVals['inputLocation']['lngLat'],
          locationAddress: _formVals['inputLocation']['address'],
          neighborhoodUName: _formVals['neighborhoodUName'],
          onSave: (dynamic data) {
            _weeklyEvents = [];
            for (var weeklyEvent in data['weeklyEvents']) {
              _weeklyEvents.add(WeeklyEventClass.fromJson(weeklyEvent));
            }
            _step = 'resources';
            setState(() { _weeklyEvents = _weeklyEvents; _step = _step; _saving = false; });
            String userId = Provider.of<CurrentUserState>(context, listen: false).currentUser.id;
            _socketService.emit('UserInsightSetActionAt', { 'userId': userId, 'field': 'ambassadorSignUpStepsAt.resources' });
          }
        ),
      ];
    } else if (_step == 'resources') {
      Map<String, dynamic> config = _configService.GetConfig();
      String globalEventsUrl = '${config['SERVER_URL']}/ne/global';
      cols += [
        Container(width: 800,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _style.Text1('Events created, the last step is to Invite Your Neighbors!', size: 'large', colorKey: 'primary'),
              _style.SpacingH('medium'),
              _style.Text1('Join the Slack and join and post an introduction in #5-ambassadors to get support on your journey.'),
              _style.SpacingH('medium'),
              _buttons.LinkElevated(context, 'Join Slack',
                'https://join.slack.com/t/tealtowns/shared_invite/zt-291gxxen8-LRs~9JmLHq8mqYUlzGncIQ', launchUrl: true),
              _style.SpacingH('medium'),
              _style.Text1('Join your virtual neighbors in Global Eat Together events to share ideas to grown your neighborhood.'),
              _style.SpacingH('medium'),
              _buttons.LinkElevated(context, 'Global Eat Together Events', globalEventsUrl, launchUrl: true),
              _style.SpacingH('medium'),
              _style.Text1('You can print flyers to post on your neighbor\'s doors or knock on doors and show the QR code on your phone.'),
              _style.SpacingH('medium'),
              _buttons.LinkElevated(context, 'View and Share Your Event', '/we/${_weeklyEvents[0].uName}'),
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
    if (_step != 'locationSelect') {
      colsVideo += [
        _style.SpacingH('xlarge'),
        Container(height: 300,
          child: _video.Youtube('B-Gz9VCGoa0'),
        ),
        _style.SpacingH('medium'),
      ];
    }

    return AppScaffoldComponent(
      listWrapper: true,
      width: 1200,
      body: Column(
        children: [
          _style.Text1('Become an Ambassador for your Neighborhood!', size: 'xlarge'),
          _style.SpacingH('medium'),
          ...cols,
          ...colsMessage,
          ...colsVideo,
        ]
      )
    );
  }
}
