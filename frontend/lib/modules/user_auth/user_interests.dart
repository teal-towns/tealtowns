import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// import '../../common/colors_service.dart';
import '../../common/layout_service.dart';
import '../../common/parse_service.dart';
import '../../common/socket_service.dart';
import '../../common/style.dart';
import './current_user_state.dart';

class UserInterests extends StatefulWidget {
  String neighborhoodUName;
  double imageHeight;
  UserInterests({ this.neighborhoodUName = '', this.imageHeight = 200, });

  @override
  _UserInterestsState createState() => _UserInterestsState();
}

class _UserInterestsState extends State<UserInterests> {
  LayoutService _layoutService = LayoutService();
  ParseService _parseService = ParseService();
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();
  Style _style = Style();

  String _message = '';
  bool _loading = true;
  List<Map<String, dynamic>> _interestsGrouped = [];
  List<Map<String, dynamic>> _interestsGroupedEvents = [];
  Map<String, Map<String, dynamic>> _eventInterests = {};

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('GetInterestsByNeighborhood', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1 && data.containsKey('interestsGrouped')) {
        if (data.containsKey('type') && data['type'] == 'event') {
          _interestsGroupedEvents = _parseService.parseListMapStringDynamic(data['interestsGrouped']);
          setState(() { _interestsGroupedEvents = _interestsGroupedEvents; _loading = false; });
        } else {
          _interestsGrouped = _parseService.parseListMapStringDynamic(data['interestsGrouped']);
          setState(() { _interestsGrouped = _interestsGrouped; _loading = false; });
        }
      }
    }));

    _routeIds.add(_socketService.onRoute('GetEventInterests', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1 && data.containsKey('eventInterests')) {
        _eventInterests = {};
        for (var key in data['eventInterests'].keys) {
          _eventInterests[key] = _parseService.parseMapStringDynamic(data['eventInterests'][key]);
        }
        setState(() { _eventInterests = _eventInterests; });
      }
    }));

    if (widget.neighborhoodUName.length > 0) {
      var data1 = {'neighborhoodUName': widget.neighborhoodUName, 'groupByInterest': 1,
        'groupedSortKey': '-count', 'type': 'common', };
      _socketService.emit('GetInterestsByNeighborhood', data1);
      // Go a 2nd time for events type, which we will display differently (with event interest details).
      data1['type'] = 'event';
      _socketService.emit('GetInterestsByNeighborhood', data1);
      _socketService.emit('GetEventInterests', {});
    }
  }

  @override
  void dispose() {
    _socketService.offRouteIds(_routeIds);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Column(children: [ LinearProgressIndicator() ]);
    }
    List<Widget> interestsEvents = [];
    for (int i = 0; i < _interestsGroupedEvents.length; i++) {
      List<Widget> colsTemp = [];
      if (_eventInterests.containsKey(_interestsGroupedEvents[i]['interest'])) {
        Map<String, dynamic> interestDetails = _eventInterests[_interestsGroupedEvents[i]['interest']]!;
        colsTemp += [
          interestDetails['imageUrls'].length <= 0 ?
            Image.asset('assets/images/shared-meal.jpg', height: widget.imageHeight, width: double.infinity, fit: BoxFit.cover,)
              : Image.network(interestDetails['imageUrls']![0], height: widget.imageHeight, width: double.infinity, fit: BoxFit.cover),
          _style.SpacingH('medium'),
          _style.Text1('${interestDetails[i]['title']}'),
          _style.SpacingH('medium'),
          _style.Text1('${interestDetails[i]['description']}'),
          _style.SpacingH('medium'),
          _style.Text1('${_interestsGroupedEvents[i]['count']} interested'),
          _style.SpacingH('medium'),
        ];
      } else {
        colsTemp += [
          _style.Text1('${_interestsGroupedEvents[i]['interest']}', size: 'large'),
          _style.SpacingH('medium'),
          _style.Text1('${_interestsGroupedEvents[i]['count']} interested'),
          _style.SpacingH('medium'),
        ];
      }
      interestsEvents.add(Column(
        children: [
          ...colsTemp,
        ]
      ));
    }
    List<Widget> interests = [];
    for (int i = 0; i < _interestsGrouped.length; i++) {
      interests.add(Column(
        children: [
          _style.Text1('${_interestsGrouped[i]['interest']}', size: 'large'),
          _style.SpacingH('medium'),
          _style.Text1('${_interestsGrouped[i]['count']} interested'),
          _style.SpacingH('medium'),
        ],
      ));
    }
    return Column(
      children: [
        // _style.Text1('Interests', size: 'large'),
        // _style.SpacingH('medium'),
        _layoutService.WrapWidth(interestsEvents),
        _style.SpacingH('medium'),
        _layoutService.WrapWidth(interests),
      ],
    );
  }
}