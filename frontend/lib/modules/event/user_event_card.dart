import 'package:flutter/material.dart';

import '../../common/buttons.dart';
import '../../common/colors_service.dart';
import '../../common/date_time_service.dart';
import '../../common/style.dart';
import '../event/user_event_class.dart';
import '../event/user_feedback_class.dart';
import '../user_auth/current_user_state.dart';

class UserEventCard extends StatefulWidget {
  UserEventClass userEvent;
  CurrentUserState? currentUserState;
  double imageHeight;
  bool launchUrl;
  UserEventCard({ required this.userEvent, this.currentUserState = null, this.imageHeight = 200,
    this.launchUrl = false, });

  @override
  _UserEventCardState createState() => _UserEventCardState();
}

class _UserEventCardState extends State<UserEventCard> {
  Buttons _buttons = Buttons();
  ColorsService _colors = ColorsService();
  DateTimeService _dateTime = DateTimeService();
  Style _style = Style();

  @override
  Widget build(BuildContext context) {
    return Build1(context, widget.userEvent);
  }

  Widget Build1(BuildContext context, UserEventClass userEvent) {
    Widget action = SizedBox.shrink();
    String actionText = '';
    Color actionColor = _colors.colors['black'];

    String createdAt, eventEnd;
    var now = DateTime.now().toUtc();
    var eventEndDT = DateTime.parse(userEvent.eventEnd);
    eventEnd = _dateTime.Format(userEvent.eventEnd, 'yyyy-MM-dd HH:mm');
    List<Widget> rowsFeedback = [];
    if (userEvent.userFeedback.containsKey('_id')) {
      UserFeedbackClass userFeedback = UserFeedbackClass.fromJson(userEvent.userFeedback);
      actionText = 'Attended';
      rowsFeedback += [
        _style.Text1('Feedback: Attended: ${userFeedback.attended}, ${userFeedback.stars} stars'),
      ];
    } else {
      if (eventEndDT.isAfter(now)) {
        actionText = 'Attending';
      } else {
        actionText = 'Feedback Pending';
        rowsFeedback += [
          _buttons.LinkInline(context, 'Leave Feedback', '/event-feedback-save?eventId=${userEvent.eventId}', launchUrl: widget.launchUrl,),
        ];
      }
    }

    if (actionText.length > 0) {
      action = Positioned(top: 0, left: 0, child: Container(color: actionColor, padding: EdgeInsets.all(5),
        child: Text(actionText, style: TextStyle(color: Colors.white),),
      ),
      );
    }

    List<Widget> cols = [];
    if (userEvent.weeklyEvent.id.length > 0) {
      cols += [
        Stack(
          children: [
            userEvent.weeklyEvent.imageUrls.length <= 0 ?
              Image.asset('assets/images/shared-meal.jpg', height: widget.imageHeight, width: double.infinity, fit: BoxFit.cover,)
                : Image.network(userEvent.weeklyEvent.imageUrls![0], height: widget.imageHeight, width: double.infinity, fit: BoxFit.cover),
            action,
          ]
        ),
        _style.SpacingH('medium'),
        _buttons.Link(context, '${userEvent.weeklyEvent.title}', '/we/${userEvent.weeklyEvent.uName}', launchUrl: widget.launchUrl,),
        _style.SpacingH('medium'),
        _style.Text1('${userEvent.weeklyEvent.xDay}, end: ${eventEnd}'),
      ];
    } else {
      Widget event = _style.Text1('${eventEnd}');
      if (userEvent.weeklyEventUName.length > 0) {
        event = _buttons.LinkInline(context, '${eventEnd}', '/we/${userEvent.weeklyEventUName}', launchUrl: widget.launchUrl,);
      }
      cols += [
        event,
      ];
    }

    cols += [
      ...rowsFeedback,
    ];

    return Container(padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: _colors.colors['primary'], width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...cols,
        ]
      ),
    );
  }
}
