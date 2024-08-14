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
  UserInterests({ this.neighborhoodUName = '',});

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

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('GetInterestsByNeighborhood', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1 && data.containsKey('interestsGrouped')) {
        _interestsGrouped = _parseService.parseListMapStringDynamic(data['interestsGrouped']);
        setState(() { _interestsGrouped = _interestsGrouped; _loading = false; });
      }
    }));

    if (widget.neighborhoodUName.length > 0) {
      var data1 = {'neighborhoodUName': widget.neighborhoodUName, 'groupByInterest': 1,
        'groupedSortKey': '-count', };
      _socketService.emit('GetInterestsByNeighborhood', data1);
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
        _layoutService.WrapWidth(interests),
      ],
    );
  }
}