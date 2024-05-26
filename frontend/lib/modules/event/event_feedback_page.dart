import 'package:flutter/material.dart';

import '../../app_scaffold.dart';
import './event_feedback.dart';

class EventFeedbackPage extends StatefulWidget {
  String weeklyEventId;
  String eventId;
  EventFeedbackPage({ this.weeklyEventId = '', this.eventId = '',});

  @override
  _EventFeedbackPageState createState() => _EventFeedbackPageState();
}

class _EventFeedbackPageState extends State<EventFeedbackPage> {

  @override
  Widget build(BuildContext context) {
    return AppScaffoldComponent(
      listWrapper: true,
      body: EventFeedback(weeklyEventId: widget.weeklyEventId, eventId: widget.eventId,),
    );
  }
}
