import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:universal_html/html.dart' as html;

import '../../app_scaffold.dart';
import '../../common/buttons.dart';
import '../../common/form_input/input_fields.dart';
import '../../common/form_input/input_location.dart';
import '../../common/layout_service.dart';
import '../../common/link_service.dart';
import '../../common/location_service.dart';
import '../../common/socket_service.dart';
import './weekly_event_class.dart';
import '../user_auth/current_user_state.dart';

class WeeklyEvents extends StatefulWidget {
  final double lat;
  final double lng;
  final double maxMeters;
  final String type;
  final String routePath;
  final int showFilters;

  WeeklyEvents({ this.lat = 0, this.lng = 0, this.maxMeters = 1500, this.type = '',
    this.routePath = 'weekly-events', this.showFilters = 1 });

  @override
  _WeeklyEventsState createState() => _WeeklyEventsState();
}

class _WeeklyEventsState extends State<WeeklyEvents> {
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();
  Buttons _buttons = Buttons();
  InputFields _inputFields = InputFields();
  LayoutService _layoutService = LayoutService();
  LinkService _linkService = LinkService();
  LocationService _locationService = LocationService();

  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic?> _filters = {
    'maxMeters': 1500,
    'lngLat': [0, 0],
  };
  bool _loading = true;
  String _message = '';
  bool _canLoadMore = false;
  int _lastPageNumber = 1;
  int _itemsPerPage = 25;
  bool _skipCurrentLocation = false;
  bool _locationLoaded = false;

  List<WeeklyEventClass> _weeklyEvents = [];
  bool _firstLoadDone = false;

  List<Map<String, dynamic>> _selectOptsMaxMeters = [
    {'value': 500, 'label': '5 min walk'},
    {'value': 1500, 'label': '15 min walk'},
    {'value': 3500, 'label': '15 min bike'},
    {'value': 8000, 'label': '15 min car'},
  ];

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('searchWeeklyEvents', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        if (data.containsKey('weeklyEvents')) {
          _weeklyEvents = [];
          for (var item in data['weeklyEvents']) {
            _weeklyEvents.add(WeeklyEventClass.fromJson(item));
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
      setState(() {
        _loading = false;
      });
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
      _filters['lngLat'] = [widget.lng, widget.lat];
      _skipCurrentLocation = true;
    } else {
      _filters['lngLat'] = _locationService.GetLngLat();
      // if (_locationService.LocationValid(_filters['lngLat'])) {
      //   _skipCurrentLocation = true;
      // }
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

    List<Widget> columnsCreate = [];
    // if (currentUserState.isLoggedIn) {
    columnsCreate = [
      Align(
        alignment: Alignment.topRight,
        child: ElevatedButton(
          onPressed: () {
            String url = '/weekly-event-save';
            if (widget.type.length > 0) {
              url += '?type=${widget.type}';
            }
            _linkService.Go(url, context, currentUserState);
          },
          child: Text('Create New Event'),
        ),
      ),
      SizedBox(height: 10),
    ];
    // }

    Widget widgetFilters = SizedBox.shrink();
    if (widget.showFilters > 0) {
      widgetFilters = _layoutService.WrapWidth([
        InputLocation(formVals: _filters, formValsKey: 'lngLat', label: 'Location', guessLocation: !_skipCurrentLocation, onChange: (List<double?> val) {
          _search();
          }),
        _inputFields.inputSelect(_selectOptsMaxMeters, _filters, 'maxMeters',
            label: 'Range', onChanged: (String val) {
            _search();
          }),
      ], width: 225);
    }

    return AppScaffoldComponent(
      listWrapper: true,
      width: 1500,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
      ),
    );
  }

  void CheckFirstLoad() {
    if (!_firstLoadDone && _locationLoaded) {
      _firstLoadDone = true;
      _search();
    }
  }

  void _init() async {
    if (!_skipCurrentLocation || widget.showFilters <= 0) {
      if (_locationService.LocationValid(_filters['lngLat'])) {
        _search();
      }
      List<double> lngLat = await _locationService.GetLocation(context);
      if (_locationService.IsDifferent(lngLat, _filters['lngLat'])) {
        setState(() {
          _filters['lngLat'] = lngLat;
        });
        if (widget.showFilters <= 0) {
          _search();
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
    return SizedBox(
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(day),
          SizedBox(height: 10),
          ...weeklyEvents.map((event) {
            return _buildWeeklyEvent(event, context, currentUserState);
          }).toList(),
        ]
      )
    );
  }

  _buildWeeklyEvent(WeeklyEventClass weeklyEvent, BuildContext context, var currentUserState) {
    List<Widget> buttons = [];
    if (currentUserState.isLoggedIn && weeklyEvent.adminUserIds.contains(currentUserState.currentUser.id)) {
      List<Widget> buttons = [
        SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: () {
                _linkService.Go('/weekly-event-save?id=${weeklyEvent.id}', context, currentUserState);
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
                foregroundColor: Theme.of(context).errorColor,
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

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buttons.Link(context, '${weeklyEvent.startTime} ${weeklyEvent.title} (${weeklyEvent.xDistanceKm.toStringAsFixed(1)} km)', '/weekly-event?id=${weeklyEvent.id}'),
          ...buttons,
        ]
      )
    );
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

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: <Widget> [
              ...eventsByDay.asMap().entries.map((entry) {
                int dayIndex = entry.key;
                List<WeeklyEventClass> events = entry.value;
                return _buildWeeklyEventDay(daysOfWeek[dayIndex], events, context, currentUserState);
              }).toList(),
            ]
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
            _linkService.Go(url, context, currentUserState);
          },
          child: Text('Add the first event!'),
        ),
      ]
    );
  }

  void _search({int lastPageNumber = 0}) {
    if (_locationService.LocationValid(_filters['lngLat'])) {
      if(mounted) {
        setState(() {
          _loading = true;
          _message = '';
          _canLoadMore = false;
        });
      }
      var currentUser = Provider.of<CurrentUserState>(context, listen: false).currentUser;
      if (lastPageNumber != 0) {
        _lastPageNumber = lastPageNumber;
      } else {
        _lastPageNumber = 1;
      }
      var data = {
        'skip': (_lastPageNumber - 1) * _itemsPerPage,
        'limit': _itemsPerPage,
        'lngLat': _filters['lngLat'],
        'maxMeters': _filters['maxMeters'],
        'withAdmins': 0,
        'type': widget.type,
      };
      _socketService.emit('searchWeeklyEvents', data);
      _UpdateUrl();
    }
  }
  
  void _UpdateUrl() {
    if(kIsWeb) {
      String? lng = _filters['lngLat'][0]?.toString();
      String? lat = _filters['lngLat'][1]?.toString();
      String? maxMeters = _filters['maxMeters']?.toString();
      html.window.history.pushState({}, '', '/${widget.routePath}?lng=${lng}&lat=${lat}&range=${maxMeters}');
    }
  }
}
