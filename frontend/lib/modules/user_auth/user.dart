import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_scaffold.dart';
import '../../common/buttons.dart';
import '../../common/date_time_service.dart';
import '../../common/socket_service.dart';
import '../../common/style.dart';
import './user_class.dart';
import './user_phone.dart';
import './current_user_state.dart';

import '../neighborhood/user_neighborhood_class.dart';
import '../event/user_event_class.dart';
import '../event/weekly_event_class.dart';
import '../event/user_feedback_class.dart';

class User extends StatefulWidget {
  String username;

  User({this.username = ''});

  @override
  _UserState createState() => _UserState();
}

class _UserState extends State<User> {
  Buttons _buttons = Buttons();
  DateTimeService _dateTime = DateTimeService();
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();
  Style _style = Style();

  bool _loading = false;
  String _message = '';
  UserClass _user = UserClass.fromJson({});
  bool _userIsSelf = false;

  bool _loadingJoinCollections = true;
  List<WeeklyEventClass> _weeklyEventsAdmin = [];
  List<UserEventClass> _userEventsAttended = [];
  // List<UserFeedbackClass> _userFeedbacks = [];
  List<UserNeighborhoodClass> _userNeighborhoods = [];

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('getUserByUsername', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (int.tryParse(data['valid']) == 1 && data['user'] != null && data['user'].runtimeType != String) {
        _user = UserClass.fromJson(data['user']);
        setState(() { _user = _user; });
      } else {
        _message = 'No user found for username ${widget.username}';
        setState(() { _message = _message; });
      }
    }));

    _routeIds.add(_socketService.onRoute('GetUserJoinCollections', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        _weeklyEventsAdmin = [];
        _userEventsAttended = [];
        _userNeighborhoods = [];
        for (var weeklyEvent in data['weeklyEventsAdmin']) {
          _weeklyEventsAdmin.add(WeeklyEventClass.fromJson(weeklyEvent));
        }
        for (var userEvent in data['userEventsAttended']) {
          _userEventsAttended.add(UserEventClass.fromJson(userEvent));
        }
        // _userFeedbacks = [];
        // for (var userFeedback in data['userFeedbacks']) {
        //   _userFeedbacks.add(UserFeedbackClass.fromJson(userFeedback));
        // }
        for (var userNeighborhood in data['userNeighborhoods']) {
          _userNeighborhoods.add(UserNeighborhoodClass.fromJson(userNeighborhood));
        }
        setState(() {
          _weeklyEventsAdmin = _weeklyEventsAdmin;
          _userEventsAttended = _userEventsAttended;
          // _userFeedbacks = _userFeedbacks;
          _userNeighborhoods = _userNeighborhoods;
          _loadingJoinCollections = false;
        });
      }
    }));

    String username = widget.username;
    if (widget.username.length > 0) {
      _socketService.emit('getUserByUsername', {'username': widget.username});
      if (Provider.of<CurrentUserState>(context, listen: false).isLoggedIn && widget.username == Provider.of<CurrentUserState>(context, listen: false).currentUser.username) {
        _userIsSelf = true;
      }
    } else {
      if (!Provider.of<CurrentUserState>(context, listen: false).isLoggedIn) {
        Timer(Duration(milliseconds: 500), () {
          context.go('/login');
        });
      } else {
        _user = Provider.of<CurrentUserState>(context, listen: false).currentUser;
        username = _user.username;
        _userIsSelf = true;
      }
    }
    _socketService.emit('GetUserJoinCollections', {'username': username});
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> cols = [];
    if (_message.length > 0) {
      cols.add(Text('${_message}'));
    } else {
      Widget phone = _userIsSelf ? UserPhone() : SizedBox.shrink();
      cols += [
        _style.Text1('${_user.firstName} ${_user.lastName} (${_user.username})', size: 'large'),
        _style.SpacingH('medium'),
        phone,
        _style.SpacingH('xlarge'),
      ];

      if (_loadingJoinCollections) {
        cols += [
          _style.SpacingH('medium'),
          LinearProgressIndicator(),
        ];
      } else {
        String createdAt, eventEnd;
        var now = DateTime.now().toUtc();
        // String nowString = _dateTime.FormatObj(now, 'yyyy-MM-dd HH:mm:ss').replaceAll(' ', 'T');
        cols += [
          _style.Text1('Attended Events', size: 'large'),
          ..._userEventsAttended.map((userEvent) {
            // createdAt = _dateTime.Format(userEvent.createdAt, 'yyyy-MM-dd');
            var eventEndDT = DateTime.parse(userEvent.eventEnd);
            eventEnd = _dateTime.Format(userEvent.eventEnd, 'yyyy-MM-dd HH:mm');
            List<Widget> rowsFeedback = [];
            if (userEvent.userFeedback.containsKey('_id')) {
              UserFeedbackClass userFeedback = UserFeedbackClass.fromJson(userEvent.userFeedback);
              rowsFeedback += [
                _style.Text1('Feedback: Attended: ${userFeedback.attended}, ${userFeedback.stars} stars'),
              ];
            } else {
              if (eventEndDT.isAfter(now)) {
                rowsFeedback += [
                  _style.Text1('(Attending soon)'),
                ];
              } else {
                rowsFeedback += [
                  _buttons.LinkInline(context, 'Leave Feedback', '/event-feedback-save?eventId=${userEvent.eventId}'),
                ];
              }
            }

            Widget event = _style.Text1('${eventEnd}');
            if (userEvent.weeklyEventUName.length > 0) {
              event = _buttons.LinkInline(context, '${eventEnd}', '/we/${userEvent.weeklyEventUName}');
            }
            return Row(
              children: [
                event,
                _style.SpacingV('medium'),
                ...rowsFeedback,
              ],
            );
          }),
          _style.SpacingH('medium'),
          // _style.Text1('Feedback', size: 'large'),
          // ..._userFeedbacks.map((userFeedback) {
          //   createdAt = _dateTime.Format(userFeedback.createdAt, 'yyyy-MM-dd');
          //   return _style.Text1('Attended: ${userFeedback.attended}, ${userFeedback.stars} stars, ${createdAt}');
          // }),
          // _style.SpacingH('medium'),

          _style.SpacingH('medium'),
          _style.Text1('Neighborhoods', size: 'large'),
          ..._userNeighborhoods.map((userNeighborhood) {
            createdAt = _dateTime.Format(userNeighborhood.createdAt, 'yyyy-MM-dd');
            String rolesDefault = '';
            if (userNeighborhood.status == 'default') {
              rolesDefault += '(default) ';
            }
            rolesDefault += userNeighborhood.roles.join(', ');
            List<Widget> rowsAmbassadorUpdate = [ SizedBox.shrink() ];
            if (userNeighborhood.roles.contains('ambassador')) {
              rowsAmbassadorUpdate = [
                _style.SpacingV('medium'),
                _buttons.LinkInline(context, 'Ambassador Update', '/au/${userNeighborhood.neighborhoodUName}'),
              ];
            }
            return Row(
              children: [
                _buttons.LinkInline(context, '${userNeighborhood.neighborhoodUName}', '/n/${userNeighborhood.neighborhoodUName}'),
                _style.Text1(', ${createdAt} ${rolesDefault}'),
                ...rowsAmbassadorUpdate,
              ]
            );
          }),
          _style.SpacingH('medium'),

          _style.Text1('Weekly Events Admin', size: 'large'),
          ..._weeklyEventsAdmin.map((weeklyEvent) {
            createdAt = _dateTime.Format(weeklyEvent.createdAt, 'yyyy-MM-dd');
            return _buttons.LinkInline(context, '${weeklyEvent.title}, ${createdAt}', '/we/${weeklyEvent.uName}');
          }),
          _style.SpacingH('medium'),
        ];
      }
    }
    return AppScaffoldComponent(
      listWrapper: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...cols,
        ]
      )
    );
  }

  @override
  void dispose() {
    _socketService.offRouteIds(_routeIds);
    super.dispose();
  }
}
