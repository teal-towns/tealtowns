import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_scaffold.dart';
import '../../common/buttons.dart';
import '../../common/card_placeholder.dart';
import '../../common/date_time_service.dart';
import '../../common/layout_service.dart';
import '../../common/socket_service.dart';
import '../../common/style.dart';
import './user_class.dart';
import './user_phone.dart';
import './current_user_state.dart';

import '../neighborhood/user_neighborhood_class.dart';
import '../neighborhood/user_neighborhood_card.dart';
import '../event/user_event_class.dart';
import '../event/weekly_event_class.dart';
import '../event/user_feedback_class.dart';
import '../event/weekly_event_card.dart';
import '../event/user_event_card.dart';

class User extends StatefulWidget {
  String username;
  String mode;

  User({this.username = '', this.mode = ''});

  @override
  _UserState createState() => _UserState();
}

class _UserState extends State<User> {
  Buttons _buttons = Buttons();
  DateTimeService _dateTime = DateTimeService();
  LayoutService _layoutService = LayoutService();
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
    _socketService.emit('GetUserJoinCollections', {'username': username, 'withWeeklyEvents': 1,});
  }

  @override
  Widget build(BuildContext context) {
    CurrentUserState currentUserState = context.watch<CurrentUserState>();
    List<Widget> cols = [];
    List<Widget> colsUserBasics = [];
    List<Widget> colsSharedItems = [];
    List<Widget> colsJoinCollections = [];
    if (_message.length > 0) {
      cols.add(Text('${_message}'));
    } else {
      if (widget.mode == '') {
        cols += [
          _style.Text1('Friendship at the Heart of Sustainable Living', size: 'xlarge'),
          _style.SpacingH('medium'),
        ];
      }

      if (widget.mode == '') {
        colsSharedItems += [
          _style.Text1('My Shared Items', size: 'large'),
          _buttons.Link(context, 'Owned', '/own?myType=owner', launchUrl: true),
          _buttons.Link(context, 'Purchased', '/own?myType=purchaser', launchUrl: true),
          _style.SpacingH('medium'),
        ];
      }

      if (_loadingJoinCollections) {
        colsJoinCollections += [
          _style.SpacingH('medium'),
          LinearProgressIndicator(),
        ];
      } else {
        List<Widget> colsWeeklyEvents = [];
        List<Widget> colsAttendedEvents = [];
        List<Widget> colsNeighborhoods = [];
        String createdAt, eventEnd;
        var now = DateTime.now().toUtc();
        // String nowString = _dateTime.FormatObj(now, 'yyyy-MM-dd HH:mm:ss').replaceAll(' ', 'T');
        if (widget.mode == '') {
          List<Widget> elementsTemp = [];
          for (UserEventClass userEvent in _userEventsAttended) {
            elementsTemp.add(UserEventCard(userEvent: userEvent, currentUserState: currentUserState, imageHeight: 155,));
          }
          // elementsTemp.add(CardPlaceholder(text: 'Create an event and lead more neighbors to sustainable life', onPressUrl: '/weekly-event-save',));

          colsAttendedEvents += [
            _style.Text1('My Events', size: 'large'),
            _layoutService.WrapWidth(elementsTemp),
            _style.SpacingH('medium'),

            // ..._userEventsAttended.map((userEvent) {
            //   // createdAt = _dateTime.Format(userEvent.createdAt, 'yyyy-MM-dd');
            //   var eventEndDT = DateTime.parse(userEvent.eventEnd);
            //   eventEnd = _dateTime.Format(userEvent.eventEnd, 'yyyy-MM-dd HH:mm');
            //   List<Widget> rowsFeedback = [];
            //   if (userEvent.userFeedback.containsKey('_id')) {
            //     UserFeedbackClass userFeedback = UserFeedbackClass.fromJson(userEvent.userFeedback);
            //     rowsFeedback += [
            //       _style.Text1('Feedback: Attended: ${userFeedback.attended}, ${userFeedback.stars} stars'),
            //     ];
            //   } else {
            //     if (eventEndDT.isAfter(now)) {
            //       rowsFeedback += [
            //         _style.Text1('(Attending soon)'),
            //       ];
            //     } else {
            //       rowsFeedback += [
            //         _buttons.LinkInline(context, 'Leave Feedback', '/event-feedback-save?eventId=${userEvent.eventId}'),
            //       ];
            //     }
            //   }

            //   Widget event = _style.Text1('${eventEnd}');
            //   if (userEvent.weeklyEventUName.length > 0) {
            //     event = _buttons.LinkInline(context, '${eventEnd}', '/we/${userEvent.weeklyEventUName}');
            //   }
            //   return Row(
            //     children: [
            //       event,
            //       _style.SpacingV('medium'),
            //       ...rowsFeedback,
            //     ],
            //   );
            // }),
            // _style.SpacingH('medium'),
          ];
        }

        if (widget.mode == '' || widget.mode == 'ambassadorUpdates') {
          List<Widget> elementsTemp = [];
          for (UserNeighborhoodClass userNeighborhood in _userNeighborhoods) {
            elementsTemp.add(UserNeighborhoodCard(userNeighborhood: userNeighborhood, currentUserState: currentUserState,));
          }
          elementsTemp.add(CardPlaceholder(text: 'Build your neighborhood', onPressUrl: '/neighborhoods', height: 95,));
          colsNeighborhoods += [
            _style.Text1('My Neighborhoods', size: 'large'),
            _style.SpacingH('medium'),
            _layoutService.WrapWidth(elementsTemp),
            _style.SpacingH('medium'),
          ];
        }

        if (widget.mode == '') {
          List<Widget> elementsTemp = [];
          for (WeeklyEventClass weeklyEvent in _weeklyEventsAdmin) {
            elementsTemp.add(WeeklyEventCard(weeklyEvent: weeklyEvent, currentUserState: currentUserState, imageHeight: 155,));
          }
          // elementsTemp += _weeklyEventsAdmin.map((weeklyEvent) {
          //   // createdAt = _dateTime.Format(weeklyEvent.createdAt, 'yyyy-MM-dd');
          //   // return _buttons.LinkInline(context, '${weeklyEvent.title}, ${createdAt}', '/we/${weeklyEvent.uName}');
          //   return WeeklyEventCard(weeklyEvent: weeklyEvent, currentUserState: currentUserState,);
          // }).toList();
          // Widget buttonTemp = _buttons.LinkIcon(context, Icons.add, '/weekly-event-save');
          elementsTemp.add(CardPlaceholder(text: 'Create an event and lead more neighbors to sustainable life', onPressUrl: '/weekly-event-save',));
          colsWeeklyEvents += [
            // _style.Text1('Weekly Events Admin', size: 'large'),
            _layoutService.WrapWidth(elementsTemp),
            _style.SpacingH('medium'),
          ];
        }
        colsJoinCollections += [
          ...colsAttendedEvents,
          _style.SpacingH('medium'),
          ...colsWeeklyEvents,
          _style.SpacingH('medium'),
          ...colsNeighborhoods,
          _style.SpacingH('medium'),
        ];
      }

      if (widget.mode == '') {
        Widget phone = _userIsSelf ? UserPhone() : SizedBox.shrink();
        colsUserBasics += [
          _style.Text1('Get Updates', size: 'large'),
          // _style.SpacingH('medium'),
          phone,
          _style.SpacingH('xlarge'),
        ];
        colsUserBasics += [
          _style.Text1('${_user.firstName} ${_user.lastName} (${_user.username})', size: 'large'),
          _style.SpacingH('medium'),
        ];
        if (_userIsSelf) {
          colsUserBasics += [
            _buttons.Link(context, 'Interests', '/user-interest-save'),
            _style.SpacingH('medium'),
            _buttons.Link(context, 'Availability', '/user-availability-save'),
            _style.SpacingH('medium'),
          ];
        }
      }
    }
    return AppScaffoldComponent(
      listWrapper: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...cols,
          ...colsJoinCollections,
          ...colsSharedItems,
          ...colsUserBasics,
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
