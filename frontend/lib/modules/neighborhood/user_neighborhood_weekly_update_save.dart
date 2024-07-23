import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_scaffold.dart';
import '../../common/form_input/form_save.dart';
import './user_neighborhood_weekly_update_class.dart';
import '../user_auth/current_user_state.dart';

class UserNeighborhoodWeeklyUpdateSave extends StatefulWidget {
  String id;
  String neighborhoodUName;
  UserNeighborhoodWeeklyUpdateSave({this.id = '', this.neighborhoodUName = '' });

  @override
  _UserNeighborhoodWeeklyUpdateSaveState createState() => _UserNeighborhoodWeeklyUpdateSaveState();
}

class _UserNeighborhoodWeeklyUpdateSaveState extends State<UserNeighborhoodWeeklyUpdateSave> {
  Map<String, Map<String, dynamic>> _formFields = {
    'inviteCount': { 'type': 'number', 'required': true, 'label': 'How many neighbors did you invite to events this week?' },
    'attendedCount': { 'type': 'number', 'required': false, 'label': 'How many unique neighbors attended events this week?' },
  };
  Map<String, dynamic> _formValsDefault = {};
  String _title = 'Create a Neighborhood Update';

  @override
  void initState() {
    super.initState();

    String userId = Provider.of<CurrentUserState>(context, listen: false).isLoggedIn ?
      Provider.of<CurrentUserState>(context, listen: false).currentUser.id : '';
    if (widget.neighborhoodUName.length < 1 || userId.length < 1) {
      Timer(Duration(milliseconds: 200), () {
        context.go('/neighborhoods');
      });
    } else {
      _formValsDefault['neighborhoodUName'] = widget.neighborhoodUName;
      _formValsDefault['userId'] = userId;
      _title = 'Create a Neighborhood Update for ${widget.neighborhoodUName}';
      if (widget.id.length > 0) {
        _title = 'Update Neighborhood (${widget.neighborhoodUName})';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double fieldWidth = 500;
    Widget content = FormSave(formVals: UserNeighborhoodWeeklyUpdateClass.fromJson(_formValsDefault).toJson(),
      dataName: 'userNeighborhoodWeeklyUpdate',
      routeGet: 'GetUserNeighborhoodWeeklyUpdateById', routeSave: 'SaveUserNeighborhoodWeeklyUpdate', id: widget.id, fieldWidth: fieldWidth,
      formFields: _formFields, title: _title,
      parseData: (dynamic data) => UserNeighborhoodWeeklyUpdateClass.fromJson(data).toJson(),
      preSave: (dynamic data) {
        data['userNeighborhoodWeeklyUpdate'] = UserNeighborhoodWeeklyUpdateClass.fromJson(data['userNeighborhoodWeeklyUpdate']).toJson();
        return data;
      },
      onSave: (dynamic data) {
        context.go('/au/${data['userNeighborhoodWeeklyUpdate']['neighborhoodUName']}');
      }
    );
    return AppScaffoldComponent(
      listWrapper: true,
      width: fieldWidth,
      body: content,
    );
  }
}
