import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_scaffold.dart';
import '../../common/form_input/form_save.dart';
import '../../common/style.dart';
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
  Style _style = Style();

  List<Map<String, dynamic>> _actions = [
    {'value': 'printFlyers', 'label': 'Print (10-20) Neighborhood & Local Event flyers', },
    {'value': 'postNeighborhoodFlyers', 'label': 'Post Neighborhood Event flyers', 'details': 'In common spaces, on neighbor doors', },
    {'value': 'postLocalFlyers', 'label': 'Post Local Event flyers', 'details': 'On telephone poles, in cafes and businesses', },
    {'value': 'shareWithFriends', 'label': 'Share events with friends', 'details': 'Share (text, email) your Neighborhood Event with neighbors you already have contact info for, and your Local Event with friends who live within 15 minutes of you', },
    {'value': 'shareLocalSocialMedia', 'label': 'Share Local Event on social media', 'details': 'Nextdoor, BuyNothing & other local (Facebook) groups, etc.', },
    {'value': 'attendeeFollowUp', 'label': 'Attendee follow up', 'details': 'Text, social media message, email people who attended events this week to collect feedback and invite them to come next week', },
    {'value': 'ambassadorRecruitment', 'label': 'Ambassador recruitment', 'details': 'Talk to 1-3 possible co-ambassadors (friend, person who joined an event this week and seems aligned and passionate) about becoming an ambassador (either in your neighborhood or starting their own). Send them the tealtowns.org/ambassador link', },
  ];

  Map<String, Map<String, dynamic>> _formFields = {
    'inviteCount': { 'type': 'number', 'required': true, 'label': 'How many neighbors did you invite (flyer or knock on doors) to events this week?' },
    // 'attendedCount': { 'type': 'number', 'required': false, 'label': 'How many unique neighbors attended events this week?' },
    // 'actionHeader': { 'type': 'xText', 'text': 'Which weekly actions have you completed thus far this week?', 'size': 'large', },
    'actionsComplete': { 'type': 'multiSelectButtons', 'label': 'Which actions have you completed this week?'},
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
      _formFields['actionsComplete']!['options'] = _actions;
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

    List<Widget> colsActionDetails = [];
    for (int i = 0; i < _actions.length; i++) {
      if (_actions[i].containsKey('details')) {
        colsActionDetails += [
          _style.Text1(_actions[i]['label'],),
          _style.SpacingH('medium'),
          _style.Text1(_actions[i]['details'], size: 'small',),
          _style.SpacingH('medium'),
        ];
      }
    }
    return AppScaffoldComponent(
      listWrapper: true,
      width: fieldWidth,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          content,
          ...colsActionDetails,
        ],
      ),
    );
  }
}
