import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_scaffold.dart';
import '../../common/buttons.dart';
import '../../common/date_time_service.dart';
import '../../common/socket_service.dart';
import '../../common/style.dart';
import '../event/event_feedback.dart';
import './neighborhood_stats_class.dart';
import './user_neighborhoods.dart';

class NeighborhoodStats extends StatefulWidget {
  String uName;
  bool showFreePaid;
  NeighborhoodStats({this.uName = '', this.showFreePaid = false, });

  @override
  _NeighborhoodStatsState createState() => _NeighborhoodStatsState();
}

class _NeighborhoodStatsState extends State<NeighborhoodStats> {
  Buttons _buttons = Buttons();
  DateTimeService _dateTime = DateTimeService();
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();
  Style _style = Style();

  bool _loading = true;
  Map<String, dynamic> _neighborhoodStats = {};
  Map<String, dynamic> _previousNeighborhoodStats = {};
  bool _showEvents = false;
  bool _showNeighbors = false;
  Map<String, bool> _showEventIds = {};

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('ComputeNeighborhoodStats', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        _neighborhoodStats = NeighborhoodStatsClass.fromJson(data['neighborhoodStats']).toJson();
        _previousNeighborhoodStats = NeighborhoodStatsClass.fromJson(data['previousNeighborhoodStats']).toJson();
        setState(() {
          _loading = false;
          _neighborhoodStats = _neighborhoodStats;
          _previousNeighborhoodStats = _previousNeighborhoodStats;
        });
      } else {
        context.go('/neighborhoods');
      }
    }));

    _socketService.emit('ComputeNeighborhoodStats', {'uName': widget.uName,});
  }

  @override
  void dispose() {
    _socketService.offRouteIds(_routeIds);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return AppScaffoldComponent(
        listWrapper: true,
        body: Column(
          children: [
            LinearProgressIndicator()
          ]
        )
      );
    }

    String start = _dateTime.Format(_neighborhoodStats['start'], 'M/d/y', local: false);
    String end = _dateTime.Format(_neighborhoodStats['end'], 'M/d/y', local: false);
    List<Widget> cols = [];
    Map<String, dynamic> keysInfo = {
      'usersCount': { 'title': 'Neighbors', },
      'weeklyEventsCount': { 'title': 'Weekly Events', },
      'uniqueEventUsersCount': { 'title': 'Unique Attendees', },
    };
    if (widget.showFreePaid) {
      keysInfo['freeEventsCount'] = { 'title': 'Free Events', };
      keysInfo['paidEventsCount'] = { 'title': 'Paid Events', };
      keysInfo['totalEventUsersCount'] = { 'title': 'Total Attendees', };
      keysInfo['totalFreeEventUsersCount'] = { 'title': 'Total Free Attendees', };
      keysInfo['totalPaidEventUsersCount'] = { 'title': 'Total Paid Attendees', };
      keysInfo['totalCutUSD'] = { 'title': 'Total Earnings', };
    }
    for (var keyVal in keysInfo.entries) {
      String key = keyVal.key;
      String title = keyVal.value['title'];
      String prefix = '';
      if (key == 'totalCutUSD') {
        prefix = '\$';
      }
      double percentChange = 0;
      if (_previousNeighborhoodStats[key] != 0) {
        percentChange = (_neighborhoodStats[key] - _previousNeighborhoodStats[key]) / _previousNeighborhoodStats[key];
        percentChange *= 100;
      }
      String change = percentChange > 0 ? '+${percentChange.toStringAsFixed(1)}%' : '${percentChange.toStringAsFixed(1)}%';
      String value = (key == 'totalCutUSD') ? '${_neighborhoodStats[key].toStringAsFixed(2)}' : '${_neighborhoodStats[key]}';
      cols += [
        _style.Text1('${title}: ${prefix}${value} (${change})', size: 'large'),
        _style.SpacingH('medium'),
      ];
    }

    List<Widget> colsNeighbors = [];
    if (_showNeighbors) {
      colsNeighbors = [
        UserNeighborhoods(neighborhoodUName: _neighborhoodStats['neighborhoodUName']),
        _style.SpacingH('medium'),
      ];
    }

    List<Widget> colsEvents = [];
    if (_showEvents) {
      _neighborhoodStats['eventInfos'].sort((a, b) => a["start"].toString().compareTo(b["start"].toString()));
      for (int i = 0; i < _neighborhoodStats['eventInfos'].length; i++) {
        String start = _dateTime.Format(_neighborhoodStats['eventInfos'][i]['start'], 'M/d/y');
        String eventId = _neighborhoodStats['eventInfos'][i]['id'];
        // String link = '/event-feedback?eventId=${eventId}';
        int newAttendeeCount = _neighborhoodStats['eventInfos'][i].containsKey('firstEventAttendeeCount') ?
          _neighborhoodStats['eventInfos'][i]['firstEventAttendeeCount'] : 0;
        colsEvents += [
          // _style.Text1('${start}', size: 'large'),
          // _buttons.Link(context, '${start} (${_neighborhoodStats['eventInfos'][i]['attendeeCount']} attendees)', link),
          TextButton(child: Text('${start} (${_neighborhoodStats['eventInfos'][i]['attendeeCount']} attendees, ${newAttendeeCount} new)'),
            onPressed: () {
              if (!_showEventIds.containsKey(eventId)) {
                _showEventIds[eventId] = true;
              } else {
                _showEventIds[eventId] = !_showEventIds[eventId]!;
              }
              setState(() { _showEventIds = _showEventIds; });
            },
          ),
          _style.SpacingH('medium'),
        ];
        if (_showEventIds.containsKey(eventId) && _showEventIds[eventId]!) {
          String weeklyEventUName = '';
          if (_neighborhoodStats['eventInfos'][i].containsKey('weeklyEventUName')) {
            weeklyEventUName = _neighborhoodStats['eventInfos'][i]['weeklyEventUName'];
          }
          if (weeklyEventUName.length > 0) {
            String link = '/we/${weeklyEventUName}';
            colsEvents += [
              _buttons.Link(context, 'View Event', link),
              _style.SpacingH('medium'),
            ];
          }
          colsEvents += [
            Container(
              padding: EdgeInsets.only(left: 20,),
              child: EventFeedback(eventId: eventId,),
            ),
            _style.SpacingH('medium'),
          ];
        }
      }
    }

    return AppScaffoldComponent(
      listWrapper: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _style.Text1('${widget.uName} Neighborhood Stats (${start} - ${end})', size: 'xlarge'),
          _style.SpacingH('medium'),
          ...cols,
          _style.SpacingH('medium'),
          TextButton(child: Text('${_neighborhoodStats['usersCount']} Neighbors'),
            onPressed: () {
              setState(() { _showNeighbors = !_showNeighbors; });
            },
          ),
          _style.SpacingH('medium'),
          ...colsNeighbors,
          _style.SpacingH('medium'),
          TextButton(child: Text('${_neighborhoodStats['eventInfos'].length} Events'),
            onPressed: () {
              setState(() { _showEvents = !_showEvents; });
            },
          ),
          _style.SpacingH('medium'),
          ...colsEvents,
        ],
      )
    );
  }
}
