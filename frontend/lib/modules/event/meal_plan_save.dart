import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_scaffold.dart';
import '../../common/form_input/input_fields.dart';
import '../../common/layout_wrap.dart';
import '../../common/socket_service.dart';
import '../../common/style.dart';
import '../user_auth/current_user_state.dart';

class MealPlanSave extends StatefulWidget {
  String neighborhoodUName;
  String type;
  String title;
  List<int> daysOfWeek;
  List<String> startTimes;
  int hostGroupSizeDefault;
  double priceUSD;
  String headerTitle;
  int pageWrapper;
  List<Map<String, dynamic>> eventsByDayDefaults;

  MealPlanSave({this.pageWrapper = 1, this.neighborhoodUName = '', this.type = 'sharedMeal', this.title = 'Shared Meal',
    this.daysOfWeek = const [0,1,2,3,4,5,6], this.startTimes = const ['17:30', '19:30',], this.hostGroupSizeDefault = 10,
    this.priceUSD = 9.0, this.headerTitle = 'Neighborhood Meal Plan', this.eventsByDayDefaults = const [
      { 'startTime': '17:30' }, { 'startTime': '17:30' }, { 'startTime': '17:30' }, { 'startTime': '17:30' }, {}, {}, {},
    ]});

  @override
  _MealPlanSaveState createState() => _MealPlanSaveState();
}

class _MealPlanSaveState extends State<MealPlanSave> {
  InputFields _inputFields = InputFields();
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();
  Style _style = Style();

  bool _saving = false;
  List<Map<String, dynamic>> _selectOptsHost = [
    { 'value': 'pay', 'label': 'Pay' },
    { 'value': 'cook', 'label': 'Cook' },
    { 'value': 'either', 'label': 'Either' },
  ];
  List<Map<String, dynamic>> _selectOptsAttendees = [
    { 'value': 1, 'label': '1' },
    { 'value': 2, 'label': '2' },
    { 'value': 3, 'label': '3' },
    { 'value': 4, 'label': '4' },
    { 'value': 5, 'label': '5' },
  ];
  List<Map<String, dynamic>> _selectOptsDays = [
    { 'value': 0, 'label': 'Monday' },
    { 'value': 1, 'label': 'Tuesday' },
    { 'value': 2, 'label': 'Wednesday' },
    { 'value': 3, 'label': 'Thursday' },
    { 'value': 4, 'label': 'Friday' },
    { 'value': 5, 'label': 'Saturday' },
    { 'value': 6, 'label': 'Sunday' },
  ];
  // List<String> _dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  List<String> _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  Map<String, dynamic> _formVals = {
    'attendeeCountAsk': 1,
    'hostCook': [],
  };
  // Assumes one per day. Example for Tue at 17:30 and Wed at 19:30:
  // [
  //   {},
  //   { 'startTime': '17:30', },
  //   { 'startTime': '19:30', },
  //   {},
  // ]
  List<Map<String, dynamic>> _eventsByDay = [];

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('CheckAndSavePendingWeeklyEvents', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        context.go('/home');
      }
    }));

    SetDefaults();
  }

  @override
  void dispose() {
    _socketService.offRouteIds(_routeIds);
    super.dispose();
  }

  void SetDefaults() {
    List<String> copyKeys = ['startTime', 'host'];
    for (int i = 0; i < _dayNames.length; i++) {
      Map<String, dynamic> eventByDay = { 'startTime': '',  'host': '' };
      if (widget.eventsByDayDefaults.length > i) {
        for (String key in copyKeys) {
          if (widget.eventsByDayDefaults[i].containsKey(key)) {
            eventByDay[key] = widget.eventsByDayDefaults[i][key];
          }
        }
      }
      eventByDay['host'] = 'pay';
      _eventsByDay.add(eventByDay);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> selectOptsTimes = [];
    for (int i = 0; i < widget.startTimes.length; i++) {
      selectOptsTimes.add({'value': widget.startTimes[i], 'label': widget.startTimes[i]});
    }
    List<Widget> days = [];
    double rowHeight = 43;
    // Left column for labels (times and cooking).
    List<Widget> colsTimes = [];
    for (int j = 0; j < widget.startTimes.length; j++) {
      colsTimes += [
        Container(height: rowHeight, child: _style.Text1('${widget.startTimes[j]}')),
      ];
    }
    days += [
      Column(
        children: [
          Container(height: rowHeight, child: _style.Text1('')),
          ...colsTimes,
          _style.SpacingH('medium'),
          _style.Text1('Cook'),
        ],
      )
    ];
    for (int i = 0; i < _dayNames.length; i++) {
      if (widget.daysOfWeek.contains(i)) {
        List<Widget> colsTimes = [];
        for (int j = 0; j < widget.startTimes.length; j++) {
          colsTimes += [
            _inputFields.inputCheckbox(_eventsByDay[i], 'startTime', formValsValue: widget.startTimes[j], onChanged: (bool value) {
              if (value) {
                _eventsByDay[i]['startTime'] = widget.startTimes[j];
              } else {
                _eventsByDay[i]['startTime'] = '';
              }
              setState(() { _eventsByDay[i]['startTime'] = _eventsByDay[i]['startTime']; });
            }),
          ];
        }
        List<Widget> cols = [
          _style.Text1('${_dayNames[i]}'),
          _style.SpacingH('medium'),
          ...colsTimes,
          // _inputFields.inputSelectButtons(selectOptsTimes, _eventsByDay[i], 'startTime', onChanged: (String value) {
          //   setState(() {
          //     _eventsByDay[i]['startTime'] = value;
          //   });
          // }),
        ];
        // if (_eventsByDay[i]['startTime'].length > 0) {
          cols += [
            // _style.SpacingH('medium'),
            // _inputFields.inputSelectButtons(_selectOptsHost, _eventsByDay[i], 'host', label: 'Host'),
            _inputFields.inputCheckbox(_eventsByDay[i], 'host', formValsValue: 'cook', onChanged: (bool value) {
              if (value) {
                _eventsByDay[i]['host'] = 'cook';
              } else {
                _eventsByDay[i]['host'] = '';
              }
              setState(() { _eventsByDay[i]['host'] = _eventsByDay[i]['host']; });
            }),
          ];
        // }
        days += [
          Column(
            children: [
              ...cols,
            ],
          )
        ];
      }
    }

    List<Widget> colsSave = [];
    if (_saving) {
      colsSave = [
        LinearProgressIndicator(),
      ];
    } else {
      colsSave = [
        ElevatedButton(child: Text('Save'), onPressed: () {
          Save(context);
        }),
      ];
    }

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _style.Text1('${widget.headerTitle}', size: 'large'),
        _style.SpacingH('medium'),
        _style.Text1('Which days would you like to eat (and optionally cook)?'),
        _style.SpacingH('medium'),
        LayoutWrap(items: days, align: 'left', spacing: 5, width: 40,),
        _style.SpacingH('medium'),
        // _inputFields.inputMultiSelectButtons(_selectOptsDays, _formVals, 'hostCook', label: 'Would you like to cook any days?'),
        // _style.SpacingH('medium'),
        Container(
          width: 350,
          child: _inputFields.inputSelect(_selectOptsAttendees, _formVals, 'attendeeCountAsk', label: 'Family size (how many people are eating)?'),
        ),
        _style.SpacingH('medium'),
        ...colsSave,
        _style.SpacingH('medium'),
      ],
    );

    if (widget.pageWrapper == 1) {
      return AppScaffoldComponent(
        listWrapper: true,
        body: content,
      );
    }
    return content;
  }

  void Save(BuildContext context) {
    String userId = Provider.of<CurrentUserState>(context, listen: false).currentUser.id;
    Map<String, dynamic> defaultEvent = { 'neighborhoodUName': widget.neighborhoodUName, 'type': widget.type, 'title': widget.title,
      'hostGroupSizeDefault': widget.hostGroupSizeDefault, 'adminUserIds': [], 'priceUSD': widget.priceUSD,};
    List<Map<String, dynamic>> weeklyEvents = [];
    for (int i = 0; i < _eventsByDay.length; i++) {
      if (_eventsByDay[i]['startTime'].length > 0) {
        Map<String, dynamic> event = defaultEvent;
        event['dayOfWeek'] = i;
        event['startTime'] = _eventsByDay[i]['startTime'];
        Map<String, dynamic> pendingUser = { 'userId': userId, 'attendeeCountAsk': 0, 'hostGroupSizeMax': 0, 'selfHostCount': 0,};
        if (_eventsByDay[i]['host'] == 'cook') {
          pendingUser['selfHostCount'] = 1;
        } else {
          pendingUser['attendeeCountAsk'] = _formVals['attendeeCountAsk'];
        }
        event['pendingUsers'] = [pendingUser];
        weeklyEvents.add(event);
      }
    }
    if (weeklyEvents.length > 0) {
      var data = {
        'weeklyEvents': weeklyEvents,
        'userId': userId,
        'startTimes': widget.startTimes,
        'type': widget.type,
        'neighborhoodUName': widget.neighborhoodUName,
      };
      _socketService.emit('CheckAndSavePendingWeeklyEvents', data);
      setState(() { _saving = true; });
    } else {
      context.go('/home');
    }
  }
}