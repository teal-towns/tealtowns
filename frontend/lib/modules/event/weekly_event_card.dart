import 'package:flutter/material.dart';

import '../../common/buttons.dart';
import '../../common/colors_service.dart';
// import '../../common/date_time_service.dart';
import '../../common/style.dart';
import '../event/weekly_event_class.dart';
import '../user_auth/current_user_state.dart';

class WeeklyEventCard extends StatefulWidget {
  WeeklyEventClass weeklyEvent;
  CurrentUserState? currentUserState;
  double imageHeight;
  WeeklyEventCard({ required this.weeklyEvent, this.currentUserState = null, this.imageHeight = 200, });

  @override
  _WeeklyEventCardState createState() => _WeeklyEventCardState();
}

class _WeeklyEventCardState extends State<WeeklyEventCard> {
  Buttons _buttons = Buttons();
  ColorsService _colors = ColorsService();
  // DateTimeService _dateTime = DateTimeService();
  Style _style = Style();

  @override
  Widget build(BuildContext context) {
    // createdAt = _dateTime.Format(widget.weeklyEvent.createdAt, 'yyyy-MM-dd');
    Widget action = SizedBox.shrink();
    String actionText = '';
    Color actionColor = _colors.colors['primary'];
    if (widget.currentUserState != null && widget.currentUserState!.isLoggedIn &&
      widget.weeklyEvent.adminUserIds.contains(widget.currentUserState!.currentUser!.id)) {
      actionText = 'Admin';
    }
    if (actionText.length > 0) {
      action = Positioned(top: 0, left: 0, child: Container(color: actionColor, padding: EdgeInsets.all(5),
        child: Text(actionText, style: TextStyle(color: Colors.white),),
      ),
      );
    }
    return Container(padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: _colors.colors['primary'], width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              widget.weeklyEvent.imageUrls.length <= 0 ?
                Image.asset('assets/images/shared-meal.jpg', height: widget.imageHeight, width: double.infinity, fit: BoxFit.cover,)
                  : Image.network(widget.weeklyEvent.imageUrls![0], height: widget.imageHeight, width: double.infinity, fit: BoxFit.cover),
              action,
            ]
          ),
          _style.SpacingH('medium'),
          _buttons.Link(context, '${widget.weeklyEvent.title}', '/we/${widget.weeklyEvent.uName}', launchUrl: true,),
          _style.SpacingH('medium'),
          _style.Text1('${widget.weeklyEvent.xDay}'),
        ]
      ),
    );
  }
}
