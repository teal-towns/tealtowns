import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:universal_html/html.dart' as html;

import '../../app_scaffold.dart';
import '../../common/buttons.dart';
import '../../common/colors_service.dart';
import '../../common/date_time_service.dart';
import '../../common/form_input/input_fields.dart';
import '../../common/form_input/input_location.dart';
import '../../common/layout_service.dart';
import '../../common/link_service.dart';
import '../../common/location_service.dart';
import '../../common/socket_service.dart';
import '../../common/style.dart';
import '../about/welcome_about.dart';
import '../neighborhood/neighborhood_state.dart';
import '../user_auth/current_user_state.dart';
import '../user_auth/user_login_signup.dart';
// import './user_event_save_service.dart';
import './event_pay.dart';
import './weekly_event_class.dart';

class WeeklyEvents extends StatefulWidget {
  final double lat;
  final double lng;
  final double maxMeters;
  final String type;
  final String routePath;
  final int showFilters;
  final int pageWrapper;
  final int updateLngLatOnInit;
  int showCreateButton;
  int viewOnly;
  bool eventPayWithSubscribe;

  WeeklyEvents({ this.lat = 0, this.lng = 0, this.maxMeters = 1500, this.type = '',
    this.routePath = 'weekly-events', this.showFilters = 1, this.pageWrapper = 1, this.updateLngLatOnInit = 1,
    this.showCreateButton = 1, this.viewOnly = 0, this.eventPayWithSubscribe = false,});

  @override
  _WeeklyEventsState createState() => _WeeklyEventsState();
}

class _WeeklyEventsState extends State<WeeklyEvents> {
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();
  Buttons _buttons = Buttons();
  ColorsService _colors = ColorsService();
  DateTimeService _dateTime = DateTimeService();
  InputFields _inputFields = InputFields();
  LayoutService _layoutService = LayoutService();
  LinkService _linkService = LinkService();
  LocationService _locationService = LocationService();
  Style _style = Style();
  // UserEventSaveService _userEventSaveService = UserEventSaveService();

  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic?> _filters = {
    'maxMeters': 1500,
    'inputLocation': { 'lngLat': [0, 0], 'address': {} },
  };
  bool _loading = true;
  String _message = '';
  // bool _canLoadMore = false;
  // int _lastPageNumber = 1;
  // int _itemsPerPage = 25;
  bool _skipCurrentLocation = false;
  bool _locationLoaded = false;

  List<WeeklyEventClass> _weeklyEvents = [];
  bool _firstLoadDone = false;
  bool _showUserLoginSignup = false;
  bool _showEventPay = false;
  WeeklyEventClass _selectedWeeklyEvent = WeeklyEventClass.fromJson({});
  bool _alreadySignedUp = false;
  bool _showPay = true;
  bool _showHost = true;
  bool _autoSave = false;
  int _hostGroupSizeMax = 0;
  int _selfHostCount = 0;
  int _attendeeCountAsk = 0;

  List<Map<String, dynamic>> _selectOptsMaxMeters = [
    {'value': 500, 'label': '5 min walk'},
    {'value': 1500, 'label': '15 min walk'},
    {'value': 3500, 'label': '15 min bike'},
    {'value': 8000, 'label': '15 min car'},
  ];

  @override
  void initState() {
    super.initState();

    var neighborhoodState = Provider.of<NeighborhoodState>(context, listen: false);

    _routeIds.add(_socketService.onRoute('SearchNearWeeklyEvents', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        if (data.containsKey('weeklyEvents')) {
          _weeklyEvents = [];
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
            _weeklyEvents.add(weeklyEvent);
          }
          if (_weeklyEvents.length == 0) {
            _message = 'No results found.';
          }
        } else {
          _message = 'Error.';
        }
      } else {
        _message = data['message'].length > 0 ? data['message'] : 'Error.';
      }
      setState(() { _loading = false; _message = _message; });
    }));

    _routeIds.add(_socketService.onRoute('removeWeeklyEvent', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        _search();
      } else {
        _message = data['message'].length > 0 ? data['message'] : 'Error.';
      }
      setState(() {
        _loading = false;
      });
    }));

    if (widget.lat != 0 && widget.lng != 0) {
      _filters['inputLocation']['lngLat'] = [widget.lng, widget.lat];
      _skipCurrentLocation = true;
    } else {
      _filters['inputLocation']['lngLat'] = _locationService.GetLngLat();
    }
    for (int ii = 0; ii < _selectOptsMaxMeters.length; ii++) {
      if (_selectOptsMaxMeters[ii]['value'] == widget.maxMeters) {
        _filters['maxMeters'] = widget.maxMeters;
        break;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init();
    });
  }

  @override
  void dispose() {
    _socketService.offRouteIds(_routeIds);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    CheckFirstLoad();

    var currentUserState = context.watch<CurrentUserState>();

    if (_showUserLoginSignup) {
      Widget content = Column(
        children: [
          UserLoginSignup(onSave: (Map<String, dynamic> data) {
            setState(() { _showUserLoginSignup = false; });
          }),
          _style.SpacingH('xLarge'),
        ]
      );
      if (widget.pageWrapper > 0) {
        return AppScaffoldComponent(listWrapper: true, body: content);
      }
      return content;
    }

    List<Widget> colsEventPay = [];
    if (_showEventPay) {
      colsEventPay = [
        Align(
          alignment: Alignment.center,
          child: Column(
            children: [
              EventPay(weeklyEvent: _selectedWeeklyEvent, event: _selectedWeeklyEvent.xEvent,
                alreadySignedUp: _alreadySignedUp, withEventInfo: true, withSubscribe: widget.eventPayWithSubscribe,
                showRsvpNote: false, showPay: _showPay, showHost: _showHost, autoSave: _autoSave,
                hostGroupSizeMax: _hostGroupSizeMax, selfHostCount: _selfHostCount, attendeeCountAsk: _attendeeCountAsk,
                onUpdate: () {
                  setState(() { _showEventPay = false; _alreadySignedUp = false; _selectedWeeklyEvent = WeeklyEventClass.fromJson({}); });
                  _search();
                }
              ),
              _style.SpacingH('medium'),
              TextButton(
                onPressed: () {
                  setState(() { _showEventPay = false; _alreadySignedUp = false; _selectedWeeklyEvent = WeeklyEventClass.fromJson({}); });
                },
                child: Text('Back to Events'),
              ),
            ]
          ),
        ),
        _style.SpacingH('xlarge'),
      ];
    }

    List<Widget> columnsCreate = [];
    if (widget.showCreateButton > 0 && !_showEventPay) {
      columnsCreate = [
        Align(
          alignment: Alignment.topRight,
          child: TextButton(
            onPressed: () {
              String url = '/weekly-event-save';
              if (widget.type.length > 0) {
                url += '?type=${widget.type}';
              }
              _linkService.Go(url, context, currentUserState: currentUserState);
            },
            child: Text('Create New Event'),
          ),
        ),
        SizedBox(height: 10),
      ];
    }

    Widget widgetFilters = SizedBox.shrink();
    if (widget.showFilters > 0 && !_showEventPay) {
      widgetFilters = _layoutService.WrapWidth([
        InputLocation(formVals: _filters, formValsKey: 'inputLocation', label: 'Location',
          guessLocation: !_skipCurrentLocation, onChanged: (Map<String, dynamic> val) {
          _search();
          }),
        _inputFields.inputSelect(_selectOptsMaxMeters, _filters, 'maxMeters',
            label: 'Range', onChanged: (String val) {
            _search();
          }),
      ], width: 150);
    }

    Widget body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...colsEventPay,
        // WelcomeAbout(),
        // SizedBox(height: 10),
        ...columnsCreate,
        Align(
          alignment: Alignment.center,
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: widgetFilters,
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: _buildResults(context, currentUserState),
        ),
      ]
    );

    if (widget.pageWrapper < 1) {
      return body;
    }

    return AppScaffoldComponent(
      listWrapper: true,
      width: 1500,
      body: body,
    );
  }

  void CheckFirstLoad() {
    if (!_firstLoadDone && _locationLoaded) {
      _firstLoadDone = true;
      bool updateUrl = widget.updateLngLatOnInit > 0;
      _search(updateUrl: updateUrl);
    }
  }

  void _init() async {
    if ((!_skipCurrentLocation || widget.showFilters <= 0) && widget.updateLngLatOnInit > 0) {
      if (_locationService.LocationValid(_filters['inputLocation']['lngLat'])) {
        _search();
      }
      List<double> lngLat = await _locationService.GetLocation(context);
      // Since async, could have changed pages and will thus get an error.
      if(mounted) {
        if (_locationService.IsDifferent(lngLat, _filters['inputLocation']['lngLat'])) {
          setState(() {
            _filters['inputLocation']['lngLat'] = lngLat;
          });
          if (widget.showFilters <= 0) {
            _search();
          }
        }
      }
    }

    _locationLoaded = true;
    CheckFirstLoad();
  }

  Widget _buildMessage(BuildContext context) {
    if (_message.length > 0) {
      return Container(
        padding: EdgeInsets.only(top: 20, bottom: 20, left: 10, right: 10),
        child: Text(_message),
      );
    }
    return SizedBox.shrink();
  }

  _buildWeeklyEventDay(String day, List<WeeklyEventClass> weeklyEvents, BuildContext context, var currentUserState) {
    if (weeklyEvents.length < 1) {
      return SizedBox.shrink();
    }
    bool withImage = weeklyEvents.length <= 3 ? true : false;
    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _style.Text1(day, size: 'large', colorKey: 'primary'),
          _style.SpacingH('medium'),
          ...weeklyEvents.map((event) {
            return _buildWeeklyEvent(event, context, currentUserState, withImage: withImage);
          }).toList(),
        ]
      )
    );
  }

  _buildWeeklyEvent(WeeklyEventClass weeklyEvent, BuildContext context, var currentUserState, { bool withImage = false,}) {
    List<Widget> buttons = [];
    if (currentUserState.isLoggedIn && weeklyEvent.adminUserIds.contains(currentUserState.currentUser.id)) {
      List<Widget> buttons = [
        SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: () {
                _linkService.Go('/weekly-event-save?id=${weeklyEvent.id}', context, currentUserState: currentUserState);
              },
              child: Text('Edit'),
            ),
            SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                _socketService.emit('removeWeeklyEvent', { 'id': weeklyEvent.id });
              },
              child: Text('Delete'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
            SizedBox(width: 10),
          ]
        ),
      ];
    }

    // var columnsDistance = [];
    // if (weeklyEvent.xDistanceKm >= 0) {
    //   columnsDistance = [
    //     Text('${weeklyEvent.xDistanceKm.toStringAsFixed(1)} km away'),
    //     SizedBox(height: 10),
    //   ];
    // }

    List<Widget> colsImage = [];
    if (withImage) {
      colsImage = [
        weeklyEvent.imageUrls.length <= 0 ?
          Image.asset('assets/images/shared-meal.jpg', height: 100, width: double.infinity, fit: BoxFit.cover,)
          : Image.network(weeklyEvent.imageUrls![0], height: 100, width: double.infinity, fit: BoxFit.cover),
        // SizedBox(height: 10),
      ];
    }

    Widget action = SizedBox.shrink();
    String actionText = '';
    Color actionColor = _colors.colors['black'];
    bool alreadyRsvped = false;
    if (weeklyEvent.xUserEvent.containsKey('attendeeCount')) {
      int attendees = weeklyEvent.xUserEvent['attendeeCount'];
      int attendeeAsks = weeklyEvent.xUserEvent['attendeeCountAsk'];
      int hosting = weeklyEvent.xUserEvent['hostGroupSize'];
      int hostingAsks = weeklyEvent.xUserEvent['hostGroupSizeMax'];
      int selfHosts = weeklyEvent.xUserEvent['selfHostCount'];
      if (attendees > 0 || attendeeAsks > 0 || selfHosts > 0) {
        alreadyRsvped = true;
        actionText = 'Going ';
        if (attendeeAsks > 1) {
          if (attendees == attendeeAsks) {
            actionText += '(${attendees}) ';
          } else {
            actionText += '(${attendees}/${attendeeAsks}) ';
          }
        }
      }
      if (hosting > 0 || hostingAsks > 0) {
        actionText += weeklyEvent.type == 'sharedMeal' ? 'Cooking' : 'Hosting';
        if (hostingAsks > 1) {
          if (hosting == hostingAsks) {
            actionText += '(${hosting}) ';
          } else {
            actionText += '(${hosting}/${hostingAsks}) ';
          }
        }
      }
      if (actionText.length > 0) {
        action = Positioned(top: 0, left: 0, child: Container(color: actionColor, padding: EdgeInsets.all(5),
          child: Text(actionText, style: TextStyle(color: Colors.white),),
        ),
        );
      }
    }

    bool newPage = widget.pageWrapper < 1 ? true : false;
    String joinText = alreadyRsvped ? 'Update RSVP' : 'Join';
    bool defaultJoinButtons = false;
    List<Widget> joinButtons = [];
    if (widget.viewOnly <= 0) {
      if (!currentUserState.isLoggedIn) {
        joinButtons += [
          TextButton(child: Text('Join'), onPressed: () {
            setState(() { _showUserLoginSignup = true; });
          }),
          _style.SpacingV('medium'),
        ];
      } else if (weeklyEvent.priceUSD == 0) {
        // joinButton = TextButton(child: Text('Join'), onPressed: () {
        //   // _userEventSaveService.JoinEvent(weeklyEvent.title, weeklyEvent.priceUSD, currentUserState.currentUser.id, (Map<String, dynamic> data) {
        //     // TODO - track event as joined (need to fetch user joined events for ALL events; just re-fetch here?)
        //   // });
        // });
        if (alreadyRsvped) {
          joinButtons += [
            _buttons.Link(context, 'View', '/we/${weeklyEvent.uName}', launchUrl: newPage),
            _style.SpacingV('medium'),
          ];
        }
      } else {
        // joinButton = _buttons.Link(context, '${joinText} (\$${weeklyEvent.priceUSD.toStringAsFixed(0)})', '/we/${weeklyEvent.uName}', launchUrl: newPage);
        defaultJoinButtons = true;
      }
    } else if (weeklyEvent.priceUSD != 0) {
      // joinButton = _buttons.Link(context, '${joinText} (\$${weeklyEvent.priceUSD.toStringAsFixed(0)})', '/we/${weeklyEvent.uName}', launchUrl: newPage);
      defaultJoinButtons = true;
    }
    
    if (defaultJoinButtons) {
      if (!alreadyRsvped) {
        joinText = 'Join';
        String hostButtonText = weeklyEvent.type == 'sharedMeal' ? 'Cook' : 'Host';
        joinButtons += [
          // 2 click pay button (allow adding attendees, otherwise would do 1 click).
          TextButton(child: Text('Pay (\$${weeklyEvent.priceUSD.toStringAsFixed(0)})'), onPressed: () {
            ResetEventPay();
            setState(() { _showEventPay = true; _selectedWeeklyEvent = weeklyEvent; _alreadySignedUp = alreadyRsvped;
              _showHost = false; _attendeeCountAsk = 1;
            });
          }),
          _style.SpacingV('medium'),
          // One click to host button. Default to self host (no payment).
          TextButton(child: Text('${hostButtonText}'), onPressed: () {
            ResetEventPay();
            setState(() { _showEventPay = true; _selectedWeeklyEvent = weeklyEvent; _alreadySignedUp = alreadyRsvped;
              _showPay = false; _hostGroupSizeMax = weeklyEvent.hostGroupSizeDefault; _selfHostCount = 1; _autoSave = true;
            });
          }),
        ];
      } else {
        // Default event pay button.
        joinButtons += [
          TextButton(child: Text('${joinText} (\$${weeklyEvent.priceUSD.toStringAsFixed(0)})'), onPressed: () {
            ResetEventPay();
            setState(() { _showEventPay = true; _selectedWeeklyEvent = weeklyEvent; _alreadySignedUp = alreadyRsvped; });
          }),
        ];
      }
    }

    // List<Widget> colsAddress = [];
    // String address = _locationService.JoinAddress(weeklyEvent.locationAddress);
    // if (address.length > 0) {
    //   colsAddress += [
    //     _style.Text1(address),
    //   ];
    // }

    List<Widget> colsAttendees = [];
    String text = '';
    if (weeklyEvent.xEvent.userEventsAttendeeCache.containsKey('attendeesCount') &&
      weeklyEvent.xEvent.userEventsAttendeeCache['attendeesCount'] > 0) {
      text += '${weeklyEvent.xEvent.userEventsAttendeeCache['attendeesCount']} going ';
    }
    if (weeklyEvent.xEvent.userEventsAttendeeCache.containsKey('nonHostAttendeesWaitingCount') &&
      weeklyEvent.xEvent.userEventsAttendeeCache['nonHostAttendeesWaitingCount'] > 0) {
      text += '${weeklyEvent.xEvent.userEventsAttendeeCache['nonHostAttendeesWaitingCount']} waiting ';
    }
    if (text.length > 0) {
      colsAttendees = [
        _style.Text1(text),
        _style.SpacingH('medium'),
      ];
    }

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buttons.LinkWrapper(context, Column(
            children: [
              Stack(
                children: [
                  ...colsImage,
                  action,
                ]
              ),
              _style.SpacingH('medium'),
              // _style.Text1('${weeklyEvent.title} (${weeklyEvent.xDistanceKm.toStringAsFixed(1)} km)'),
              _style.Text1('${weeklyEvent.title}', fontWeight: FontWeight.bold),
            ]
          ), '/we/${weeklyEvent.uName}', launchUrl: newPage),
          _style.SpacingH('medium'),
          // _style.SpacingH('medium'),
          _style.Text1('${_dateTime.ToAmPm(weeklyEvent.startTime)}'),
          // ...colsAddress,
          ...colsAttendees,
          Row(
            children: [
              ...joinButtons,
            ]
          ),
          _style.SpacingH('medium'),
          ...buttons,
        ]
      )
    );
  }

  void ResetEventPay() {
    _showPay = true;
    _showHost = true;
    _autoSave = false;
    _hostGroupSizeMax = 0;
    _selfHostCount = 0;
    _attendeeCountAsk = 0;
    setState(() {
      _showPay = _showPay;
      _showHost = _showHost;
      _autoSave = _autoSave;
      _hostGroupSizeMax = _hostGroupSizeMax;
      _selfHostCount = _selfHostCount;
      _attendeeCountAsk = _attendeeCountAsk;
    });
  }

  _buildResults(BuildContext context, CurrentUserState currentUserState) {
    if (_weeklyEvents.length > 0) {
      List<List<WeeklyEventClass>> eventsByDay = [];
      List<String> daysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      int currentEventIndex = 0;
      int eventsLength = _weeklyEvents.length;
      for (int i = 0; i < daysOfWeek.length; i++) {
        List<WeeklyEventClass> events = [];
        while (currentEventIndex < eventsLength && _weeklyEvents[currentEventIndex].dayOfWeek == i) {
          events.add(_weeklyEvents[currentEventIndex]);
          currentEventIndex++;
        }
        eventsByDay.add(events);
      }

      List<Widget> items = [];
      for (var entry in eventsByDay.asMap().entries) {
        int dayIndex = entry.key;
        List<WeeklyEventClass> events = entry.value;
        if (events.length > 0) {
          items.add(_buildWeeklyEventDay(daysOfWeek[dayIndex], events, context, currentUserState));
        }
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.start,
            children: items,
          ),
        ]
      );
    }
    return Column(
      children: [
        _buildMessage(context),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            String url = '/weekly-event-save';
            if (widget.type.length > 0) {
              url += '?type=${widget.type}';
            }
            _linkService.Go(url, context, currentUserState: currentUserState);
          },
          child: Text('Add the first event!'),
        ),
      ]
    );
  }

  void _search({int lastPageNumber = 0, bool updateUrl = true}) {
    if (mounted && _locationService.LocationValid(_filters['inputLocation']['lngLat'])) {
      setState(() {
        _loading = true;
        _message = '';
        // _canLoadMore = false;
      });
      // if (lastPageNumber != 0) {
      //   _lastPageNumber = lastPageNumber;
      // } else {
      //   _lastPageNumber = 1;
      // }
      var data = {
        // 'skip': (_lastPageNumber - 1) * _itemsPerPage,
        // 'limit': _itemsPerPage,
        'lngLat': _filters['inputLocation']['lngLat'],
        'maxMeters': _filters['maxMeters'],
        'withAdmins': 0,
        'type': widget.type,
        'withEvents': 1,
      };
      CurrentUserState currentUserState = Provider.of<CurrentUserState>(context, listen: false);
      if (currentUserState.isLoggedIn) {
        data['withUserEventUserId'] = currentUserState.currentUser.id;
      }
      _socketService.emit('SearchNearWeeklyEvents', data);
      if (updateUrl) {
        _UpdateUrl();
      }
    }
  }
  
  void _UpdateUrl() {
    if(kIsWeb) {
      String? lng = _filters['inputLocation']['lngLat'][0]?.toString();
      String? lat = _filters['inputLocation']['lngLat'][1]?.toString();
      String? maxMeters = _filters['maxMeters']?.toString();
      html.window.history.pushState({}, '', '/${widget.routePath}?lng=${lng}&lat=${lat}&range=${maxMeters}');
    }
  }
}
