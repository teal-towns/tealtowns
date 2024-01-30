import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_scaffold.dart';
import '../../common/form_input/form_save.dart';
import './weekly_event_class.dart';
import '../user_auth/current_user_state.dart';

class WeeklyEventSave extends StatefulWidget {
  String id;
  WeeklyEventSave({this.id = ''});

  @override
  _WeeklyEventSaveState createState() => _WeeklyEventSaveState();
}

class _WeeklyEventSaveState extends State<WeeklyEventSave> {
  List<Map<String, dynamic>> _optsDayOfWeek = [
    {'value': 0, 'label': 'Monday'},
    {'value': 1, 'label': 'Tuesday'},
    {'value': 2, 'label': 'Wednesday'},
    {'value': 3, 'label': 'Thursday'},
    {'value': 4, 'label': 'Friday'},
    {'value': 5, 'label': 'Saturday'},
    {'value': 6, 'label': 'Sunday'},
  ];
  Map<String, Map<String, dynamic>> _formFields = {
    'title': {},
    'description': {'type': 'text', 'minLines': 4, 'required': false},
    'dayOfWeek': {'type': 'select'},
    'startTime': {'type': 'time'},
    'endTime': {'type': 'time'},
    'location': {'type': 'location', 'nestedCoordinates': true},
  };

  @override
  void initState() {
    super.initState();

    _formFields['dayOfWeek']!['options'] = _optsDayOfWeek;
  }

  @override
  Widget build(BuildContext context) {
    double fieldWidth = 300;
    return AppScaffoldComponent(
      listWrapper: true,
      innerWidth: fieldWidth,
      body: FormSave(formVals: WeeklyEventClass.fromJson({}).toJson(), dataName: 'weeklyEvent',
        routeGet: 'getWeeklyEventById', routeSave: 'saveWeeklyEvent', id: widget.id, fieldWidth: fieldWidth,
        formFields: _formFields, parseData: (dynamic data) => WeeklyEventClass.fromJson(data).toJson(),
        preSave: (dynamic data) {
          data = WeeklyEventClass.fromJson(data).toJson();
          if (data['hostUserIds'] == null) {
            data['hostUserIds'] = [];
          }
          if (data['hostUserIds'].length == 0) {
            var currentUser = Provider.of<CurrentUserState>(context, listen: false).currentUser;
            if (currentUser != null) {
              data['hostUserIds'].add(currentUser.id);
            }
          }
          return data;
        }, onSave: (dynamic data) {
          context.go('/weekly-events');
        }
      )
    );
  }
}
