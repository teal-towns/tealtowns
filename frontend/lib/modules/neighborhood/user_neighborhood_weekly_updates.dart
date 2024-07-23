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
import './user_neighborhood_weekly_update_class.dart';
import '../user_auth/current_user_state.dart';

class UserNeighborhoodWeeklyUpdates extends StatefulWidget {
  String neighborhoodUName;
  String mode;
  UserNeighborhoodWeeklyUpdates({ this.neighborhoodUName = '', this.mode = 'singleAmbassador', });

  @override
  _UserNeighborhoodWeeklyUpdatesState createState() => _UserNeighborhoodWeeklyUpdatesState();
}

class _UserNeighborhoodWeeklyUpdatesState extends State<UserNeighborhoodWeeklyUpdates> {
  Buttons _buttons = Buttons();
  DateTimeService _dateTime = DateTimeService();
  LayoutService _layoutService = LayoutService();
  LinkService _linkService = LinkService();
  Style _style = Style();

  List<UserNeighborhoodWeeklyUpdateClass> _userNeighborhoodWeeklyUpdates = [];
  Map<String, dynamic> _dataDefault = {
    'withEventsAttendedCount': 1,
  };
  Map<String, Map<String, dynamic>> _filterFields = {};

  @override
  void initState() {
    super.initState();

    if (widget.mode == 'singleAmbassador') {
      var currentUserState = Provider.of<CurrentUserState>(context, listen: false);
      if (widget.neighborhoodUName.length < 1 || !currentUserState.isLoggedIn) {
        Timer(Duration(milliseconds: 200), () {
          context.go('/neighborhoods');
        });
      } else {
        _dataDefault['neighborhoodUName'] = widget.neighborhoodUName;
        _dataDefault['userId'] = currentUserState.currentUser.id;
      }
    } else {
      _filterFields['username'] = {};
    }
  }

  @override
  Widget build(BuildContext context) {
    var currentUserState = context.watch<CurrentUserState>();
    String title = widget.mode == 'singleAmbassador' ? 'Neighborhood Weekly Updates (${widget.neighborhoodUName})' : 'Ambassadors Updates';
    List<Widget> colsSave = [];
    if (widget.mode == 'singleAmbassador') {
      colsSave = [
        Align(
          alignment: Alignment.topRight,
          child: ElevatedButton(
            onPressed: () {
              String url = '/user-neighborhood-weekly-update-save?neighborhoodUName=${widget.neighborhoodUName}';
              _linkService.Go(url, context, currentUserState: currentUserState);
            },
            child: Text('Create New Update'),
          ),
        ),
        SizedBox(height: 10),
      ];
    }
    return AppScaffoldComponent(
      listWrapper: true,
      body: Column(
        children: [
          _style.Text1(title, size: 'large'),
          SizedBox(height: 10,),
          ...colsSave,
          Paging(dataName: 'userNeighborhoodWeeklyUpdates', routeGet: 'SearchUserNeighborhoodWeeklyUpdates',
            dataDefault: _dataDefault, filterFields: _filterFields,
            onGet: (dynamic items) {
              _userNeighborhoodWeeklyUpdates = [];
              for (var item in items) {
                _userNeighborhoodWeeklyUpdates.add(UserNeighborhoodWeeklyUpdateClass.fromJson(item));
              }
              setState(() { _userNeighborhoodWeeklyUpdates = _userNeighborhoodWeeklyUpdates; });
            },
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _layoutService.WrapWidth(_userNeighborhoodWeeklyUpdates.map((item) => OneItem(item, context)).toList(),),
              ]
            ),
          )
        ]
      ) 
    );
  }

  Widget OneItem(UserNeighborhoodWeeklyUpdateClass userNeighborhoodWeeklyUpdate, BuildContext context) {
    String startDate = _dateTime.Format(userNeighborhoodWeeklyUpdate.start, 'M/d/y');
    String endDate = _dateTime.Format(userNeighborhoodWeeklyUpdate.end, 'M/d/y');
    List<Widget> colsEdit = [];
    if (widget.mode == 'singleAmbassador') {
      colsEdit = [
        ElevatedButton(
          onPressed: () {
            context.go('/user-neighborhood-weekly-update-save?id=${userNeighborhoodWeeklyUpdate.id}&neighborhoodUName=${widget.neighborhoodUName}');
          },
          child: Text('Edit'),
        ),
        _style.SpacingH('medium'),
      ];
    }
    List<Widget> colsUsername = [];
    if (widget.mode != 'singleAmbassador') {
      colsUsername = [
        _style.Text1(userNeighborhoodWeeklyUpdate.username),
        _style.SpacingH('medium'),
      ];
    }
    String attendedName = widget.mode == 'singleAmbassador' ? 'You' : 'Ambassador';
    return Column(
      children: [
        ...colsUsername,
        _style.Text1('${startDate} - ${endDate}'),
        _style.SpacingH('medium'),
        _style.Text1('${userNeighborhoodWeeklyUpdate.inviteCount} invites (${userNeighborhoodWeeklyUpdate.attendedCount} attended)'),
        _style.SpacingH('medium'),
        _style.Text1('${attendedName} attended ${userNeighborhoodWeeklyUpdate.eventsAttendedCount} events'),
        _style.SpacingH('medium'),
        ...colsEdit,
      ]
    );
  }
}