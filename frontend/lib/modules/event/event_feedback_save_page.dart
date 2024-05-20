import 'package:flutter/material.dart';

import './event_feedback_save.dart';
import '../../app_scaffold.dart';

class EventFeedbackSavePage extends StatefulWidget {
  String eventId;
  EventFeedbackSavePage({this.eventId = '',});

  @override
  _EventFeedbackSavePageState createState() => _EventFeedbackSavePageState();
}

class _EventFeedbackSavePageState extends State<EventFeedbackSavePage> {
  @override
  Widget build(BuildContext context) {
    return AppScaffoldComponent(
      listWrapper: true,
      body: EventFeedbackSave(eventId: widget.eventId,),
    );
  }
}
