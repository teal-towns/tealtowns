import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/buttons.dart';
import '../../common/date_time_service.dart';
import '../../common/layout_service.dart';
import '../../common/socket_service.dart';
import './event_class.dart';
import './event_feedback_class.dart';
import './user_feedback_class.dart';
import '../user_auth/current_user_state.dart';

class EventFeedback extends StatefulWidget {
  String weeklyEventId;
  String eventId;
  int showDetails;
  EventFeedback({ this.weeklyEventId = '', this.eventId = '', this.showDetails = 1,});

  @override
  _EventFeedbackState createState() => _EventFeedbackState();
}

class _EventFeedbackState extends State<EventFeedback> {
  Buttons _buttons = Buttons();
  DateTimeService _dateTime = DateTimeService();
  LayoutService _layoutService = LayoutService();
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();

  EventFeedbackClass _eventFeedback = EventFeedbackClass.fromJson({});
  EventClass _event = EventClass.fromJson({});
  List<UserFeedbackClass> _userFeedbacks = [];
  List<String> _feedbackVoteStrings = [];
  List<String> _positiveVoteStrings = [];
  Map<String, dynamic> _attendedStats = {
    'yes': 0,
    'no': 0,
  };
  double _starsAverage = 0.0;
  Map<String, dynamic> _willJoinNextWeekStats = {
    'yes': 0,
    'no': 0,
    'futureWeek': 0,
  };
  Map<String, dynamic> _willInviteStats = {
    'no': 0,
    'willMeetNewNeighbor': 0,
    'invites': 0,
  };
  bool _show = true;
  bool _missingUserFeedback = false;

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('GetEventFeedbackByWeeklyEvent', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1 && data.containsKey('eventFeedback') && data.containsKey('event') &&
        data['event']['weeklyEventId'] == widget.weeklyEventId) {
        SetData(data);
      }
    }));

    _routeIds.add(_socketService.onRoute('GetEventFeedbackByEvent', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1 && data.containsKey('eventFeedback') && data.containsKey('event') &&
        data['event']['_id'] == widget.eventId) {
        SetData(data);
      }
    }));

    var currentUserState = Provider.of<CurrentUserState>(context, listen: false);
    String userId = currentUserState.isLoggedIn ? currentUserState.currentUser.id : '';
    if (widget.eventId.length > 0) {
      _socketService.emit('GetEventFeedbackByEvent',
        {'eventId': widget.eventId, 'withUserFeedback': 1, 'withEvent': 1, 'withCheckAskForFeedbackUserId': userId});
    } else if (widget.weeklyEventId.length > 0) {
      _socketService.emit('GetEventFeedbackByWeeklyEvent',
        {'weeklyEventId': widget.weeklyEventId, 'withUserFeedback': 1, 'withCheckAskForFeedbackUserId': userId});
    }

    if (widget.showDetails < 1) {
      _show = false;
    }
  }

  void SetData(var data) {
    _eventFeedback = EventFeedbackClass.fromJson(data['eventFeedback']);
    _event = EventClass.fromJson(data['event']);
    if (data.containsKey('missingFeedbackEventIds')) {
      for (int i = 0; i < data['missingFeedbackEventIds'].length; i++) {
        if (data['missingFeedbackEventIds'][i] == _eventFeedback.eventId) {
          _missingUserFeedback = true;
          break;
        }
      }
    }
    for (int i = 0; i < _eventFeedback.feedbackVotes.length; i++) {
      int count = _eventFeedback.feedbackVotes[i].userIds.length;
      _feedbackVoteStrings.add('(${count}) ${_eventFeedback.feedbackVotes[i].feedback}');
    }
    _feedbackVoteStrings.sort((b, a) => a.compareTo(b));
    for (int i = 0; i < _eventFeedback.positiveVotes.length; i++) {
      int count = _eventFeedback.positiveVotes[i].userIds.length;
      _positiveVoteStrings.add('(${count}) ${_eventFeedback.positiveVotes[i].feedback}');
    }
    _positiveVoteStrings.sort((b, a) => a.compareTo(b));
    _userFeedbacks = [];
    _attendedStats = {
      'yes': 0,
      'no': 0,
    };
    _starsAverage = 0.0;
    double starsSum = 0;
    _willJoinNextWeekStats = {
      'yes': 0,
      'no': 0,
      'futureWeek': 0,
    };
    _willInviteStats = {
      'no': 0,
      'willMeetNewNeighbor': 0,
      'invites': 0,
    };
    if (data.containsKey('userFeedbacks')) {
      for (var userFeedback in data['userFeedbacks']) {
        _userFeedbacks.add(UserFeedbackClass.fromJson(userFeedback));
        _attendedStats[userFeedback['attended']] += 1;
        starsSum += userFeedback['stars'];
        _willJoinNextWeekStats[userFeedback['willJoinNextWeek']] += 1;
        if (userFeedback['willInvite'].length > 0) {
          _willInviteStats[userFeedback['willInvite']] += 1;
        }
        _willInviteStats['invites'] += userFeedback['invites'].length;
      }
    }
    setState(() {
      _event = _event;
      _eventFeedback = _eventFeedback;
      _feedbackVoteStrings = _feedbackVoteStrings;
      _positiveVoteStrings = _positiveVoteStrings;
      _userFeedbacks = _userFeedbacks;
      _attendedStats = _attendedStats;
      _starsAverage = _attendedStats['yes'] > 0 ? starsSum / _attendedStats['yes'] : 0;
      _willJoinNextWeekStats = _willJoinNextWeekStats;
      _willInviteStats = _willInviteStats;
      _missingUserFeedback = _missingUserFeedback;
    });
  }

  @override
  void dispose() {
    _socketService.offRouteIds(_routeIds);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_eventFeedback.id.length < 1) {
      return SizedBox.shrink();
    }
    String peopleCount = _userFeedbacks.length == 1 ? '1 person' : '${_userFeedbacks.length} people';
    String eventStart = _dateTime.Format(_event.start, 'EEEE M/d/y');

    List<Widget> colsMissingUserFeedback = [];
    if (_missingUserFeedback) {
      colsMissingUserFeedback = [
        _buttons.LinkElevated(context, 'Add Your Feedback', '/event-feedback-save?eventId=${_eventFeedback.eventId}'),
        SizedBox(height: 10),
      ];
    }

    List<Widget> colsTitle = [
      Text('Feedback From Past Event (${peopleCount}, ${eventStart})'),
      SizedBox(height: 10),
      ...colsMissingUserFeedback,
    ];
    if (!_show && _userFeedbacks.length > 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton(child: Text('Feedback From Past Event (${peopleCount}, ${eventStart})'),
            onPressed: () {
              setState(() { _show = true; });
            }
          ),
          SizedBox(height: 10),
          ...colsMissingUserFeedback,
        ],
      );
    }

    List<Widget> colsImprove = [];
    if (_feedbackVoteStrings.length > 0) {
      colsImprove = [
        Text('Improvements:'),
        SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _feedbackVoteStrings.map((feedback) => Text(feedback)).toList(),
        ),
        SizedBox(height: 10),
      ];
    }
    List<Widget> colsEnjoyed = [];
    if (_positiveVoteStrings.length > 0) {
      colsEnjoyed = [
        Text('Enjoyed:'),
        SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _positiveVoteStrings.map((feedback) => Text(feedback)).toList(),
        ),
        SizedBox(height: 10),
      ];
    }
    List<Widget> colsStarsAttended = [];
    if (_attendedStats['yes'] > 0) {
      colsStarsAttended = [
        Text('${_starsAverage.toStringAsFixed(1)} stars, ${_attendedStats['yes']} attended'),
        SizedBox(height: 10),
      ];
    }
    List<Widget> colsWillJoin = [];
    if (_willJoinNextWeekStats['yes'] > 0 || _willJoinNextWeekStats['no'] > 0 || _willJoinNextWeekStats['futureWeek'] > 0) {
      colsWillJoin = [
        Text('Will Join Next Week: ${_willJoinNextWeekStats['yes']} yes, ${_willJoinNextWeekStats['no']} no, ${_willJoinNextWeekStats['futureWeek']} future week'),
        SizedBox(height: 10),
      ];
    }
    List<Widget> colsWillInvite = [];
    if (_willInviteStats['invites'] > 0 || _willInviteStats['willMeetNewNeighbor'] > 0 || _willInviteStats['no'] > 0) {
      colsWillInvite = [
        Text('Will Invite: ${_willInviteStats['invites']} invites, ${_willInviteStats['willMeetNewNeighbor']} will meet new neighbor, ${_willInviteStats['no']} no'),
        SizedBox(height: 10),
      ];
    }

    List<Widget> images = [];
    if (_eventFeedback.imageUrls.length > 0) {
      for (int i = 0; i < _eventFeedback.imageUrls.length; i++) {
        String url = _eventFeedback.imageUrls[i];
        images.add(
          Image.network(url, height: 100, width: 100, fit: BoxFit.cover),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...colsTitle,
        ...colsStarsAttended,
        ...colsImprove,
        ...colsEnjoyed,
        ...colsWillJoin,
        ...colsWillInvite,
        _layoutService.WrapWidth(images, width: 100,)
      ],
    );
  }
}
