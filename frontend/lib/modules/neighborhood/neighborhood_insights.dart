import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app_scaffold.dart';
import '../../common/buttons.dart';
import '../../common/date_time_service.dart';
import '../../common/link_service.dart';
import '../../common/paging.dart';
import '../../common/style.dart';
import './neighborhood_stats_class.dart';
import '../user_auth/current_user_state.dart';

class NeighborhoodInsights extends StatefulWidget {
  @override
  _NeighborhoodInsightsState createState() => _NeighborhoodInsightsState();
}

class _NeighborhoodInsightsState extends State<NeighborhoodInsights> {
  Buttons _buttons = Buttons();
  DateTimeService _dateTime = DateTimeService();
  LinkService _linkService = LinkService();
  Style _style = Style();

  List<NeighborhoodStatsClass> _neighborhoodInsights = [];
  Map<String, dynamic> _dataDefault = {};
  List<Map<String, dynamic>> _sortOpts = [
    { 'value': '-usersCount', 'label': 'Users', },
    { 'value': '-uniqueEventUsersCount', 'label': 'Unique Event Users', },
    { 'value': '-totalEventUsersCount', 'label': 'Total Event Users', },
  ];

  @override
  void initState() {
    super.initState();

    CurrentUserState currentUserState = Provider.of<CurrentUserState>(context, listen: false);
    if (!currentUserState.isLoggedIn) {
      Timer(Duration(milliseconds: 500), () {
        _linkService.Go('', context, currentUserState: currentUserState);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffoldComponent(
      listWrapper: true,
      body: Paging(dataName: 'neighborhoodStatsMonthlyCaches', routeGet: 'SearchNeighborhoodInsights', itemsPerPage: 25,
        dataDefault: _dataDefault, sortOpts: _sortOpts, sortKeys: '-usersCount',
        onGet: (dynamic neighborhoodInsights) {
          _neighborhoodInsights = [];
          for (var item in neighborhoodInsights) {
            _neighborhoodInsights.add(NeighborhoodStatsClass.fromJson(item));
          }
          setState(() { _neighborhoodInsights = _neighborhoodInsights; });
        },
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _style.Text1('Neighborhoods', size: 'large'),
            SizedBox(height: 10,),
            Row(
              children: [
                Expanded(flex: 1, child: Text('Neighborhood')),
                Expanded(flex: 1, child: Text('Users')),
                Expanded(flex: 1, child: Text('Unique Event Users')),
                Expanded(flex: 1, child: Text('Total Event Users')),
                Expanded(flex: 1, child: Text('Stats')),
              ]
            ),
            ..._neighborhoodInsights.map((item) => BuildNeighborhoodInsight(item, context) ).toList(),
          ]
        ),
      ) 
    );
  }

  Widget BuildNeighborhoodInsight(NeighborhoodStatsClass neighborhoodInsight, BuildContext context) {
    return Container(
      child: Row(
        children: [
          Expanded(flex: 1, child: _buttons.LinkInline(context, '${neighborhoodInsight.neighborhoodUName}', '/n/${neighborhoodInsight.neighborhoodUName}')),
          Expanded(flex: 1, child: Text('${neighborhoodInsight.usersCount}')),
          Expanded(flex: 1, child: Text('${neighborhoodInsight.uniqueEventUsersCount}')),
          Expanded(flex: 1, child: Text('${neighborhoodInsight.totalEventUsersCount}')),
          Expanded(flex: 1, child: _buttons.LinkInline(context, 'Insights', '/neighborhood-stats/${neighborhoodInsight.neighborhoodUName}')),
        ]
      )
    );
  }
}