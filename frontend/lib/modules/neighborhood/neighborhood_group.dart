import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_scaffold.dart';
import '../../common/buttons.dart';
import '../../common/date_time_service.dart';
import '../../common/socket_service.dart';
import '../../common/style.dart';
import '../user_auth/current_user_state.dart';
import './neighborhood_stats_class.dart';
import './neighborhood_group_class.dart';

class NeighborhoodGroup extends StatefulWidget {
  String uName;
  NeighborhoodGroup({this.uName = '', });

  @override
  _NeighborhoodGroupState createState() => _NeighborhoodGroupState();
}

class _NeighborhoodGroupState extends State<NeighborhoodGroup> {
  Buttons _buttons = Buttons();
  DateTimeService _dateTime = DateTimeService();
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();
  Style _style = Style();

  NeighborhoodGroupClass _neighborhoodGroup = NeighborhoodGroupClass.fromJson({});
  List<NeighborhoodStatsClass> _neighborhoodInfos = [];
  List<NeighborhoodStatsClass> _previousNeighborhoodInfos = [];
  int _countTotal = 1;
  int _countDone = 0;
  bool _badUName = false;

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('ComputeNeighborhoodGroupStats', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        if (data.containsKey('countTotal')) {
          _countTotal = data['countTotal'];
          _countDone = data['countDone'];
          _neighborhoodInfos = [];
          _previousNeighborhoodInfos = [];
          for (var i = 0; i < data['neighborhoodInfos'].length; i++) {
            _neighborhoodInfos.add(NeighborhoodStatsClass.fromJson(data['neighborhoodInfos'][i]));
          }
          for (var i = 0; i < data['previousNeighborhoodInfos'].length; i++) {
            _previousNeighborhoodInfos.add(NeighborhoodStatsClass.fromJson(data['previousNeighborhoodInfos'][i]));
          }
          setState(() {
            _neighborhoodInfos = _neighborhoodInfos;
            _previousNeighborhoodInfos = _previousNeighborhoodInfos;
            _countTotal = _countTotal;
            _countDone = _countDone;
          });
        }
      } else {
        _badUName = true;
        setState(() { _badUName = _badUName; });
      }
    }));

    if (widget.uName.length > 0) {
      _socketService.emit('ComputeNeighborhoodGroupStats', {'uName': widget.uName});
    }
  }

  @override
  void dispose() {
    _socketService.offRouteIds(_routeIds);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.uName.length < 1 || _badUName) {
      return AppScaffoldComponent(
        listWrapper: true,
        body: Column(children: [ Text('Invalid neighborhood group uName, please try again') ] )
      );
    }
    if (_countDone < _countTotal) {
      return AppScaffoldComponent(
        listWrapper: true,
        body: Column(
          children: [
            Text('Loading ${_countDone} of ${_countTotal}..'),
            LinearProgressIndicator(),
          ]
        )
      );
    }

    String start = '';
    String end = '';
    if (_neighborhoodInfos.length > 0) {
      start = _dateTime.Format(_neighborhoodInfos[0].start, 'M/d/y', local: false);
      end = _dateTime.Format(_neighborhoodInfos[0].end, 'M/d/y', local: false);
    }
    Map<String, dynamic> totals = {
      'users': 0,
      'freeEvents': 0,
      'paidEvents': 0,
      'attendees': 0,
      'earnings': 0,
    };
    List<Widget> colsTable = [
      Row(
          children: [
            Expanded(flex: 1, child: Text('Neighborhood')),
            Expanded(flex: 1, child: Text('Neighbors')),
            Expanded(flex: 1, child: Text('Free Events')),
            Expanded(flex: 1, child: Text('Paid Events')),
            Expanded(flex: 1, child: Text('Event Attendees')),
            Expanded(flex: 1, child: Text('Earnings')),
          ]
        )
    ];
    for (var i = 0; i < _neighborhoodInfos.length; i++) {
      totals['users'] = totals['users']! + _neighborhoodInfos[i].usersCount;
      totals['freeEvents'] = totals['freeEvents']! + _neighborhoodInfos[i].freeEventsCount;
      totals['paidEvents'] = totals['paidEvents']! + _neighborhoodInfos[i].paidEventsCount;
      totals['attendees'] = totals['attendees']! + _neighborhoodInfos[i].totalEventUsersCount;
      totals['earnings'] = totals['earnings']! + _neighborhoodInfos[i].totalCutUSD;
      colsTable.add(
        Row(
          children: [
            // Expanded(flex: 1, child: Text('${_neighborhoodInfos[i]['neighborhoodUName']}')),
            Expanded(flex: 1, child: _buttons.Link(context, '${_neighborhoodInfos[i].neighborhoodUName}', '/neighborhood-stats/${_neighborhoodInfos[i].neighborhoodUName}')),
            Expanded(flex: 1, child: Text('${_neighborhoodInfos[i].usersCount}')),
            Expanded(flex: 1, child: Text('${_neighborhoodInfos[i].freeEventsCount}')),
            Expanded(flex: 1, child: Text('${_neighborhoodInfos[i].paidEventsCount}')),
            Expanded(flex: 1, child: Text('${_neighborhoodInfos[i].totalEventUsersCount}')),
            Expanded(flex: 1, child: Text('\$${_neighborhoodInfos[i].totalCutUSD}')),
          ]
        )
      );
    }

    return AppScaffoldComponent(
      listWrapper: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _style.Text1('${widget.uName} Neighborhoods Stats (${start} - ${end})', size: 'xlarge'),
          _style.SpacingH('medium'),
          _style.Text1('${_neighborhoodInfos.length} neighborhoods'),
          _style.SpacingH('medium'),
          _style.Text1('Totals: ${totals['users']} neighbors, ${totals['freeEvents']} free events, ${totals['paidEvents']} paid events, ${totals['attendees']} attendees, \$${totals['earnings']}'),
          _style.SpacingH('medium'),
          ...colsTable,
        ],
      ),
    );
  }

}
