import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_scaffold.dart';
import '../../common/buttons.dart';
import '../../common/date_time_service.dart';
import '../../common/layout_service.dart';
import '../../common/link_service.dart';
import '../../common/paging.dart';
import '../../common/style.dart';
import './weekly_event_class.dart';
import '../user_auth/current_user_state.dart';

class WeeklyEventsSearch extends StatefulWidget {
  @override
  _WeeklyEventsSearchState createState() => _WeeklyEventsSearchState();
}

class _WeeklyEventsSearchState extends State<WeeklyEventsSearch> {
  Buttons _buttons = Buttons();
  DateTimeService _dateTime = DateTimeService();
  LayoutService _layoutService = LayoutService();
  LinkService _linkService = LinkService();
  Style _style = Style();

  List<WeeklyEventClass> _weeklyEvents = [];
  Map<String, dynamic> _dataDefault = {
  };
  Map<String, Map<String, dynamic>> _filterFields = {
    'uName': {},
    'neighborhoodUName': {},
    'title': {},
  };

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var currentUserState = context.watch<CurrentUserState>();
    return AppScaffoldComponent(
      listWrapper: true,
      body: Column(
        children: [
          _style.Text1('Weekly Events Search', size: 'large'),
          SizedBox(height: 10,),
          Paging(dataName: 'weeklyEvents', routeGet: 'SearchWeeklyEvents',
            dataDefault: _dataDefault, filterFields: _filterFields, sortKeys: '-createdAt',
            onGet: (dynamic weeklyEvents) {
              _weeklyEvents = [];
              for (var item in weeklyEvents) {
                _weeklyEvents.add(WeeklyEventClass.fromJson(item));
              }
              setState(() { _weeklyEvents = _weeklyEvents; });
            },
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _layoutService.WrapWidth(_weeklyEvents.map((item) => OneItem(item, context)).toList(),),
              ]
            ),
          )
        ]
      ) 
    );
  }

  Widget OneItem(WeeklyEventClass weeklyEvent, BuildContext context) {
    String createdAt = _dateTime.Format(weeklyEvent.createdAt, 'yyyy-MM-dd');
    return Column(
      children: [
        _style.Text1('${weeklyEvent.title}'),
        _style.SpacingH('medium'),
        _style.Text1('${weeklyEvent.xDay} ${weeklyEvent.startTime} - ${weeklyEvent.endTime}'),
        _style.SpacingH('medium'),
        _buttons.LinkInline(context, '/we/${weeklyEvent.uName}', '/we/${weeklyEvent.uName}'),
        _style.SpacingH('medium'),
        _buttons.LinkInline(context, '/n/${weeklyEvent.neighborhoodUName}', '/n/${weeklyEvent.neighborhoodUName}'),
        _style.SpacingH('medium'),
        _style.Text1('\$${weeklyEvent.priceUSD}'),
        _style.SpacingH('medium'),
        _style.Text1('created: ${createdAt}'),
        _style.SpacingH('medium'),
      ]
    );
  }
}