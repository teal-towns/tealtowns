// import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';

import '../../app_scaffold.dart';
import '../../common/buttons.dart';
import '../../common/layout_service.dart';
import '../../common/socket_service.dart';
import '../../common/style.dart';
import '../neighborhood/neighborhood_class.dart';

class AmbassadorNetworkView extends StatefulWidget {
  int maxMeters;
  double lat;
  double lng;
  AmbassadorNetworkView({ this.maxMeters = 8000, this.lat = 0.0, this.lng = 0.0, });

  @override
  _AmbassadorNetworkViewState createState() => _AmbassadorNetworkViewState();
}

class _AmbassadorNetworkViewState extends State<AmbassadorNetworkView> {
  Buttons _buttons = Buttons();
  LayoutService _layoutService = LayoutService();
  Style _style = Style();
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();

  List<NeighborhoodClass> _neighborhoods = [];
  bool _loading = false;
  // Map<String, int> _uNameIndices = {};
  Map<String, List<Map<String, dynamic>>> _ambassadorsByNeighborhoodUName = {};

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('SearchNeighborhoods', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        _neighborhoods = [];
        List<String> uNames = [];
        for (var i = 0; i < data['neighborhoods'].length; i++) {
          _neighborhoods.add(NeighborhoodClass.fromJson(data['neighborhoods'][i]));
          // Save for adding in ambassadors (userNeighborhoods).
          // _uNameIndices[data['neighborhoods'][i]['uName']] = i;
          uNames.add(data['neighborhoods'][i]['uName']);
        }
        setState(() { _neighborhoods = _neighborhoods; _loading = false; });

        // Look up ambassadors.
        var data1 = {
          'neighborhoodUNames': uNames,
          'roles': 'ambassador',
          // 'withUsers': 1,
        };
        _socketService.emit('SearchUserNeighborhoods', data1);
      }
    }));

    _routeIds.add(_socketService.onRoute('SearchUserNeighborhoods', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1 && data.containsKey('userNeighborhoods')) {
        _ambassadorsByNeighborhoodUName = {};
        for (var i = 0; i < data['userNeighborhoods'].length; i++) {
          if (data['userNeighborhoods'][i]['roles'].contains('ambassador')) {
            String uName = data['userNeighborhoods'][i]['neighborhoodUName'];
            if (!_ambassadorsByNeighborhoodUName.containsKey(uName)) {
              _ambassadorsByNeighborhoodUName[uName] = [];
            }
            Map<String, dynamic> userInfo = { 'username': data['userNeighborhoods'][i]['username'] };
            // if (data['userNeighborhoods'][i].containsKey('user')) {
            //   userInfo['user'] = data['userNeighborhoods'][i]['user'];
            // }
            _ambassadorsByNeighborhoodUName[uName]!.add(userInfo);
          }
        }
        setState(() { _ambassadorsByNeighborhoodUName = _ambassadorsByNeighborhoodUName; });
      }
    }));

    var data1 = {
      'location': { 'lngLat': [ widget.lng, widget.lat ], 'maxMeters': widget.maxMeters, },
    };
    _socketService.emit('SearchNeighborhoods', data1);
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
        body: Column( children: [ LinearProgressIndicator() ]),
      );
    }

    List<Widget> cols = [];
    if (_neighborhoods.length > 0) {
      cols += [
        _layoutService.WrapWidth(_neighborhoods.map((item) => OneNeighborhood(item, context)).toList(),),
      ];
    } else {
      cols += [
        _style.Text1('No Neighborhoods Found', size: 'medium'),
      ];
    }
    return AppScaffoldComponent(
      listWrapper: true,
      body: Column(
        // crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _style.Text1('${_neighborhoods.length} Nearby Neighborhoods', size: 'large'),
          _style.SpacingH('medium'),
          Align(
            alignment: Alignment.topRight,
            child: _buttons.LinkElevated(context, 'Build Your Ambassador Network', '/ambassador-network', checkLoggedIn: true),
          ),
          _style.SpacingH('medium'),
          ...cols,
          _style.SpacingH('medium'),
          _buttons.LinkElevated(context, 'Build Your Ambassador Network', '/ambassador-network', checkLoggedIn: true),
          _style.SpacingH('medium'),
        ],
      )
    );
  }

  Widget OneNeighborhood(NeighborhoodClass neighborhood, BuildContext context) {
    List<Widget> colsAmbassadors = [];
    if (_ambassadorsByNeighborhoodUName.containsKey(neighborhood.uName)) {
      colsAmbassadors += [
        _style.Text1('Ambassadors:'),
        _style.SpacingH('medium'),
      ];
      for (var i = 0; i < _ambassadorsByNeighborhoodUName[neighborhood.uName]!.length; i++) {
        String username = _ambassadorsByNeighborhoodUName[neighborhood.uName]![i]['username'];
        colsAmbassadors += [
          _buttons.LinkInline(context, '${username}', '/u/${username}', launchUrl: true),
          _style.SpacingH('medium'),
        ];
      }
    }
    return Card.outlined(
      color: Colors.white,
      child: Column(
        children: [
          _buttons.Link(context, '${neighborhood.uName}', '/n/${neighborhood.uName}', launchUrl: true),
          _style.SpacingH('medium'),
          ...colsAmbassadors,
          _style.SpacingH('medium'),
        ]
      ),
    );
  }

}
