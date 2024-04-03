import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_scaffold.dart';
import '../../common/form_input/form_save.dart';
import './weekly_event_class.dart';
import '../user_auth/current_user_state.dart';

class WeeklyEventSave extends StatefulWidget {
  String id;
  String type;
  WeeklyEventSave({this.id = '', this.type = ''});

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
    'location': { 'type': 'location', 'nestedCoordinates': true },
    'title': {},
    'description': { 'type': 'text', 'minLines': 4, 'required': false, 'label': 'Description (optional)' },
    'dayOfWeek': { 'type': 'select' },
    'startTime': { 'type': 'time' },
    'endTime': { 'type': 'time' },
    'hostGroupSizeDefault': { 'type': 'number', 'min': 0, 'required': true },
    'priceUSD': { 'type': 'number', 'min': 5, 'required': true },
    'rsvpDeadlineHours': { 'type': 'number', 'min': 0, 'required': true },
  };
  Map<String, dynamic> _formValsDefault = {
    'hostGroupSizeDefault': 0,
    'priceUSD': 0,
    'rsvpDeadlineHours': 0,
    'type': '',
  };
  String _formMode = '';
  List<String> _formStepKeys = [];

  @override
  void initState() {
    super.initState();

    _formValsDefault['type'] = widget.type;
    if (widget.type == 'sharedMeal') {
      _formValsDefault['hostGroupSizeDefault'] = 10;
      _formValsDefault['priceUSD'] = 10;
      _formValsDefault['rsvpDeadlineHours'] = 72;
      _formValsDefault['title'] = 'Shared Meal';
      _formValsDefault['dayOfWeek'] = 6;
      _formValsDefault['startTime'] = '17:00';
      _formValsDefault['endTime'] = '18:30';

      _formMode = 'step';

      _formFields['location']!['helpText'] = 'Where will people meet to eat?';
      _formFields['description']!['helpText'] = 'Any special instructions for where people should meet?';
      _formFields['dayOfWeek']!['helpText'] = 'We suggest Sundays at 5pm, but if you would like to do a different day or time, set it here.';
      _formStepKeys = ['location', 'description', 'dayOfWeek', 'startTime'];
    }
    _formFields['dayOfWeek']!['options'] = _optsDayOfWeek;

    // Do not allow changing some fields.
    if (widget.id != null && widget.id!.length > 0) {
      _formFields.remove('hostGroupSizeDefault');
      _formFields.remove('priceUSD');
    }
  }

  @override
  Widget build(BuildContext context) {
    double fieldWidth = 300;
    return AppScaffoldComponent(
      listWrapper: true,
      innerWidth: fieldWidth,
      body: FormSave(formVals: WeeklyEventClass.fromJson(_formValsDefault).toJson(), dataName: 'weeklyEvent',
        routeGet: 'getWeeklyEventById', routeSave: 'saveWeeklyEvent', id: widget.id, fieldWidth: fieldWidth,
        formFields: _formFields, mode: _formMode, stepKeys: _formStepKeys, parseData: (dynamic data) => WeeklyEventClass.fromJson(data).toJson(),
        preSave: (dynamic data) {
          data = WeeklyEventClass.fromJson(data).toJson();
          if (data['adminUserIds'] == null) {
            data['adminUserIds'] = [];
          }
          if (data['adminUserIds'].length == 0) {
            var currentUser = Provider.of<CurrentUserState>(context, listen: false).currentUser;
            if (currentUser != null) {
              data['adminUserIds'].add(currentUser.id);
            }
          }
          return data;
        }, onSave: (dynamic data) {
          String uName = data['weeklyEvent']['uName'];
          context.go('/we/${uName}');
        }
      )
    );
  }
}
