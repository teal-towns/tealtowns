import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_scaffold.dart';
import '../../common/colors_service.dart';
import '../../common/date_time_service.dart';
import '../../common/form_input/input_fields.dart';
import '../../common/layout_service.dart';
import '../../common/lodash_service.dart';
import '../../common/socket_service.dart';
import '../../common/style.dart';
import './current_user_state.dart';
import './user_availability_class.dart';

class UserAvailabilitySave extends StatefulWidget {
  double dayHeight;
  double dayWidth;
  UserAvailabilitySave({ this.dayHeight = 250, this.dayWidth = 250,});

  @override
  _UserAvailabilitySaveState createState() => _UserAvailabilitySaveState();
}

class _UserAvailabilitySaveState extends State<UserAvailabilitySave> {
  ColorsService _colors = ColorsService();
  DateTimeService _dateTime = DateTimeService();
  InputFields _inputFields = InputFields();
  LayoutService _layoutService = LayoutService();
  LodashService _lodash = LodashService();
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();
  Style _style = Style();

  UserAvailabilityClass _userAvailability = UserAvailabilityClass.fromJson({});
  List<Map<String, dynamic>> _availabilityDefaults = [
    { 'dayOfWeek': 0, 'times': [ { 'start': '07:00', 'end': '09:00' }, { 'start': '17:00', 'end': '20:30' } ] },
    { 'dayOfWeek': 1, 'times': [ { 'start': '07:00', 'end': '09:00' }, { 'start': '17:00', 'end': '20:30' } ] },
    { 'dayOfWeek': 2, 'times': [ { 'start': '07:00', 'end': '09:00' }, { 'start': '17:00', 'end': '20:30' } ] },
    { 'dayOfWeek': 3, 'times': [ { 'start': '07:00', 'end': '09:00' }, { 'start': '17:00', 'end': '20:30' } ] },
    { 'dayOfWeek': 4, 'times': [ { 'start': '07:00', 'end': '09:00' }, { 'start': '17:00', 'end': '20:30' } ] },
    { 'dayOfWeek': 5, 'times': [ { 'start': '08:00', 'end': '21:00' } ] },
    { 'dayOfWeek': 6, 'times': [ { 'start': '08:00', 'end': '20:30' } ] },
  ];
  Map<String, dynamic> _formVals = {};
  String _message = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('SaveUserAvailability', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1 && data.containsKey('userAvailability')) {
        CurrentUserState currentUserState = Provider.of<CurrentUserState>(context, listen: false);
        currentUserState.SetUserAvailability(UserAvailabilityClass.fromJson(data['userAvailability']));
        context.go('/user');
      }
    }));

    CurrentUserState currentUserState = Provider.of<CurrentUserState>(context, listen: false);
    if (!currentUserState.isLoggedIn) {
      Timer(Duration(milliseconds: 200), () {
        context.go('/login');
      });
    } else {
      _userAvailability = currentUserState.userAvailability;
      if (_userAvailability.availableTimesByDay.length == 0) {
        _userAvailability.availableTimesByDay = _availabilityDefaults;
      }
    }
  }

  @override
  void dispose() {
    _socketService.offRouteIds(_routeIds);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    CurrentUserState currentUserState = context.watch<CurrentUserState>();
    if (!currentUserState.isLoggedIn || _loading) {
      return AppScaffoldComponent(listWrapper: true, body: Column(children: [ LinearProgressIndicator() ]) );
    }

    if (currentUserState.userAvailability.id != _userAvailability.id) {
      _userAvailability = currentUserState.userAvailability;
    }
    List<Widget> days = [];
    List<int> daysOfWeek = [0, 1, 2, 3, 4, 5, 6];
    List<String> dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    for (int dayOfWeek in daysOfWeek) {
      List<Widget> timeBlocks = [];
      for (int i = 0; i < _userAvailability.availableTimesByDay.length; i++) {
        if (_userAvailability.availableTimesByDay[i]['dayOfWeek'] == dayOfWeek) {
          for (int j = 0; j < _userAvailability.availableTimesByDay[i]['times'].length; j++) {
            String startTime = _userAvailability.availableTimesByDay[i]['times'][j]['start'];
            String endTime = _userAvailability.availableTimesByDay[i]['times'][j]['end'];
            // int minutesDiff = _dateTime.timeDiffMinutes(startTime, endTime);
            // int minutesPerDay = 24 * 60;
            // double pixels = minutesDiff / minutesPerDay * widget.dayHeight;
            String key = '${i}_${j}';
            String keyStart = '${key}_start';
            String keyEnd = '${key}_end';
            _formVals[keyStart] = startTime;
            _formVals[keyEnd] = endTime;
            timeBlocks += [
              Row(
                children: [
                  Expanded(flex: 1,
                    child: _inputFields.inputTime(_formVals, keyStart, label: 'Start', required: true, onChanged: (String val) {
                      _userAvailability.availableTimesByDay[i]['times'][j]['start'] = val;
                      // ValidateAndUpdateTimes(i);
                      setState(() {
                        _userAvailability.availableTimesByDay = _userAvailability.availableTimesByDay;
                      });
                    }),
                  ),
                  SizedBox(width: 10),
                  Expanded(flex: 1,
                    child: _inputFields.inputTime(_formVals, keyEnd, label: 'End', required: true, onChanged: (String val) {
                      _userAvailability.availableTimesByDay[i]['times'][j]['end'] = val;
                      // ValidateAndUpdateTimes(i);
                      setState(() {
                        _userAvailability.availableTimesByDay = _userAvailability.availableTimesByDay;
                      });
                    }),
                  ),
                  SizedBox(width: 10),
                  IconButton(
                    iconSize: 25,
                    icon: Icon(Icons.delete_forever, color: _colors.colors['greyLight']),
                    onPressed: () {
                      _userAvailability.availableTimesByDay[i]['times'].removeAt(j);
                      setState(() {
                        _userAvailability.availableTimesByDay = _userAvailability.availableTimesByDay;
                      });
                    },
                  ),
                ]
              ),
            ];
          }
        }
      }
      days.add(Column(
        children: [
          Text(dayNames[dayOfWeek]),
          ...timeBlocks,
          SizedBox(height: 10),
          TextButton(child: Text('Add Availability'), onPressed: () {
            bool found = false;
            int dayIndex = -1;
            Map<String, dynamic> newTime = { 'start': '', 'end': '' };
            for (int i = 0; i < _userAvailability.availableTimesByDay.length; i++) {
              if (_userAvailability.availableTimesByDay[i]['dayOfWeek'] == dayOfWeek) {
                dayIndex = i;
                _userAvailability.availableTimesByDay[i]['times'].add(newTime);
                found = true;
                break;
              }
            }
            if (!found) {
              List<Map<String, dynamic>> newTimes = [newTime];
              Map<String, dynamic> newDay = { 'dayOfWeek': dayOfWeek, 'times': newTimes };
              _userAvailability.availableTimesByDay.add(newDay);
              dayIndex = _userAvailability.availableTimesByDay.length - 1;
            }
            ValidateAndUpdateTimes(dayIndex);
          }),
        ],
      ));
    }

    return AppScaffoldComponent(
      listWrapper: true,
      body: Column(
        children: [
          _style.Text1('When are all the times you are generally available for in person neighborhood events?', size: 'large'),
          _style.SpacingH('medium'),
          _layoutService.WrapWidth(days, width: widget.dayWidth),
          _style.SpacingH('xlarge'),
          ElevatedButton(child: Text('Save'), onPressed: () {
            ValidateAndUpdateAllTimes();
            int timesCount = 0;
            for (var day in _userAvailability.availableTimesByDay) {
              timesCount += day['times'].length as int;
            }
            if (timesCount >= 3) {
              var data = {
                'userAvailability': _userAvailability.toJson(),
              };
              CurrentUserState currentUserState = Provider.of<CurrentUserState>(context, listen: false);
              data['userAvailability']!['userId'] = currentUserState.currentUser.id;
              data['userAvailability']!['username'] = currentUserState.currentUser.username;
              _socketService.emit('SaveUserAvailability', data);
              setState(() { _loading = true; });
            } else {
              setState(() { _message = 'Please add at least 3 availability times.'; });
            }
          },),
          _style.SpacingH('medium'),
          _style.Text1(_message),
        ],
      ),
    );
  }

  void ValidateAndUpdateAllTimes() {
    for (int i = 0; i < _userAvailability.availableTimesByDay.length; i++) {
      ValidateAndUpdateTimes(i, updateState: false, removeEmpty: true,);
    }
    setState(() {
      _userAvailability.availableTimesByDay = _userAvailability.availableTimesByDay;
    });
  }

  void ValidateAndUpdateTimes(int dayIndex, { bool updateState = true, bool removeEmpty = false, }) {
    // TODO - was working but now type errors.. with add new availability..
    // _userAvailability.availableTimesByDay[dayIndex]['times'] =
    //   _lodash.Sort2D(_userAvailability.availableTimesByDay[dayIndex]['times'], 'start');
    // Merge any overlapping times.
    for (int i = _userAvailability.availableTimesByDay[dayIndex]['times'].length - 1; i > 0; i--) {
      Map<String, dynamic> past = _userAvailability.availableTimesByDay[dayIndex]['times'][i - 1];
      Map<String, dynamic> current = _userAvailability.availableTimesByDay[dayIndex]['times'][i];
      if (current['start'] != '' && current['end'] != '' && past['start'] != '' && past['end'] != '') {
        int currentStart = int.parse(current['start'].replaceAll(RegExp('[^0-9]'), ''));
        int currentEnd = int.parse(current['end'].replaceAll(RegExp('[^0-9]'), ''));
        // int pastStart = int.parse(past['start'].replaceAll(RegExp('[^0-9]'), ''));
        int pastEnd = int.parse(past['end'].replaceAll(RegExp('[^0-9]'), ''));
        if (pastEnd >= currentStart) {
          // Set to the latest end.
          String newEnd = currentEnd >= pastEnd ? current['end'] : past['end'];
          _userAvailability.availableTimesByDay[dayIndex]['times'][i - 1]['end'] = newEnd;
          _userAvailability.availableTimesByDay[dayIndex]['times'].removeAt(i);
        }
      } else if (removeEmpty) {
        _userAvailability.availableTimesByDay[dayIndex]['times'].removeAt(i);
      }
    }
    // Sort days of week too.
    _userAvailability.availableTimesByDay = _lodash.Sort2D(_userAvailability.availableTimesByDay, 'dayOfWeek');
    if (updateState) {
      setState(() {
        _userAvailability.availableTimesByDay = _userAvailability.availableTimesByDay;
      });
    }
  }
}
