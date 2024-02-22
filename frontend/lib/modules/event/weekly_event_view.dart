import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_scaffold.dart';
import '../../common/link_service.dart';
import '../../common/mapbox/mapbox.dart';
import '../../common/socket_service.dart';
import './weekly_event_class.dart';
import '../user_auth/current_user_state.dart';

class WeeklyEventView extends StatefulWidget {
  String id;

  WeeklyEventView({ this.id = '', });

  @override
  _WeeklyEventViewState createState() => _WeeklyEventViewState();
}

class _WeeklyEventViewState extends State<WeeklyEventView> {
  List<String> _routeIds = [];
  LinkService _linkService = LinkService();
  SocketService _socketService = SocketService();

  bool _loading = true;
  String _message = '';

  WeeklyEventClass _weeklyEvent = WeeklyEventClass.fromJson({});

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('getWeeklyEventById', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        if (data.containsKey('weeklyEvent')) {
          _weeklyEvent = WeeklyEventClass.fromJson(data['weeklyEvent']);
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
        context.go('/weekly-events');
      } else {
        _message = data['message'].length > 0 ? data['message'] : 'Error.';
      }
      setState(() {
        _loading = false;
      });
    }));

    var data = {
      'id': widget.id,
      'withHosts': 1,
    };
    _socketService.emit('getWeeklyEventById', data);
  }

  @override
  void dispose() {
    _socketService.offRouteIds(_routeIds);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var currentUserState = context.watch<CurrentUserState>();
    List<Widget> buttons = [];
    if (currentUserState.isLoggedIn && _weeklyEvent.hostUserIds.contains(currentUserState.currentUser.id)) {
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

    List<Widget> hosts = [];
    if (_weeklyEvent.hostUsers.length > 0) {
      hosts.add(Text('Hosts'));
      for (var host in _weeklyEvent.hostUsers) {
        hosts.add(
          Text('${host.firstName} ${host.lastName} (${host.email})'),
        );
      }
      hosts.add(SizedBox(height: 10));
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
          Text(_weeklyEvent.description),
          SizedBox(height: 10),
          ...hosts,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...buttons,
            ]
          ),
          SizedBox(height: 10),
        ]
      ),
    );
  }
  
}
