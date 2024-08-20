import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app_scaffold.dart';
import '../../common/buttons.dart';
import '../../common/config_service.dart';
import '../../common/socket_service.dart';
import '../../common/style.dart';
import '../event/weekly_events.dart';
import './neighborhood_class.dart';
import '../user_auth/user_interests.dart';

class NeighborhoodEvents extends StatefulWidget {
  String uName;
  NeighborhoodEvents({this.uName = '',});

  @override
  _NeighborhoodEventsState createState() => _NeighborhoodEventsState();
}

class _NeighborhoodEventsState extends State<NeighborhoodEvents> {
  Buttons _buttons = Buttons();
  ConfigService _configService = ConfigService();
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();
  Style _style = Style();

  NeighborhoodClass _neighborhood = NeighborhoodClass.fromJson({});
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('GetNeighborhoodByUName', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        _neighborhood = NeighborhoodClass.fromJson(data['neighborhood']);
        setState(() {
          _neighborhood = _neighborhood;
          _loading = false;
        });
      } else {
        context.go('/neighborhoods');
      }
    }));

    var data = { 'uName': widget.uName, };
    _socketService.emit('GetNeighborhoodByUName', data);
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
            LinearProgressIndicator(),
          ]
        )
      );
    }

    Map<String, dynamic> config = _configService.GetConfig();
    return AppScaffoldComponent(
      listWrapper: true,
      body: Column(
        children: [
          WeeklyEvents(lat: _neighborhood.location.coordinates[1], lng: _neighborhood.location.coordinates[0],
            pageWrapper: 0, updateLngLatOnInit: 0,),
          _style.SpacingH('medium'),
          _style.Text1('Pending Events By Interest', size: 'large'),
          _style.SpacingH('medium'),
          _buttons.LinkElevated(context, 'Add Your Interests to Get Events Started!', '/interests',
            checkLoggedIn: true,),
          _style.SpacingH('medium'),
          UserInterests(neighborhoodUName: _neighborhood.uName,),
          _style.SpacingH('medium'),
          _style.Text1('Share with your neighbors', size: 'large'),
          _style.SpacingH('medium'),
          QrImageView(
            data: '${config['SERVER_URL']}/ne/${_neighborhood.uName}',
            version: QrVersions.auto,
            size: 200.0,
          ),
          _style.SpacingH('medium'),
          Text('${config['SERVER_URL']}/ne/${_neighborhood.uName}'),
          _style.SpacingH('large'),
          _buttons.LinkElevated(context, 'View Neighborhood', '/n/${_neighborhood.uName}', checkLoggedIn: true,),
          _style.SpacingH('medium'),
        ]
      )
    );
  }
}
