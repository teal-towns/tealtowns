import 'dart:convert';
import 'package:flutter/material.dart';

import '../../common/date_time_service.dart';
import '../../common/socket_service.dart';
import './event_class.dart';
import './event_feedback_class.dart';
import './user_feedback_class.dart';

class EventFeedback extends StatefulWidget {
  String weeklyEventId;
  String eventId;
  EventFeedback({ this.weeklyEventId = '', this.eventId = '',});

  @override
  _EventFeedbackState createState() => _EventFeedbackState();
}

class _EventFeedbackState extends State<EventFeedback> {
  DateTimeService _dateTime = DateTimeService();
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();

  EventFeedbackClass _eventFeedback = EventFeedbackClass.fromJson({});
  EventClass _event = EventClass.fromJson({});
  List<UserFeedbackClass> _userFeedbacks = [];
  List<String> _feedbackVoteStrings = [];
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

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('GetEventFeedbackByWeeklyEvent', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1 && data.containsKey('eventFeedback') && data.containsKey('event')) {
        SetData(data);
      }
    }));

    _routeIds.add(_socketService.onRoute('GetEventFeedbackByEvent', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1 && data.containsKey('eventFeedback') && data.containsKey('event')) {
        SetData(data);
      }
    }));

    if (widget.eventId.length > 0) {
      _socketService.emit('GetEventFeedbackByEvent',
        {'eventId': widget.eventId, 'withUserFeedback': 1, 'withEvent': 1});
    } else if (widget.weeklyEventId.length > 0) {
      _socketService.emit('GetEventFeedbackByWeeklyEvent',
        {'weeklyEventId': widget.weeklyEventId, 'withUserFeedback': 1});
    }
  }

  void SetData(var data) {
    _eventFeedback = EventFeedbackClass.fromJson(data['eventFeedback']);
    _event = EventClass.fromJson(data['event']);
    for (int i = 0; i < _eventFeedback.feedbackVotes.length; i++) {
      int count = _eventFeedback.feedbackVotes[i].userIds.length;
      _feedbackVoteStrings.add('(${count}) ${_eventFeedback.feedbackVotes[i].feedback}');
    }
    _feedbackVoteStrings.sort((b, a) => a.compareTo(b));
    _userFeedbacks = [];
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
      _userFeedbacks = _userFeedbacks;
      _willJoinNextWeekStats = _willJoinNextWeekStats;
      _willInviteStats = _willInviteStats;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Feedback From Past Event (${peopleCount}, ${eventStart})'),
        SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _feedbackVoteStrings.map((feedback) => Text(feedback)).toList(),
        ),
        SizedBox(height: 10),
        Text('Will Join Next Week: ${_willJoinNextWeekStats['yes']} yes, ${_willJoinNextWeekStats['no']} no, ${_willJoinNextWeekStats['futureWeek']} future week'),
        SizedBox(height: 10),
        Text('Will Invite: ${_willInviteStats['invites']} invites, ${_willInviteStats['willMeetNewNeighbor']} will meet new neighbor, ${_willInviteStats['no']} no'),
        SizedBox(height: 10),
      ],
    );
  }
}
