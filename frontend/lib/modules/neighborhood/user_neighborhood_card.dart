import 'package:flutter/material.dart';

import '../../common/buttons.dart';
import '../../common/colors_service.dart';
import '../../common/date_time_service.dart';
import '../../common/style.dart';
import './user_neighborhood_class.dart';
import '../user_auth/current_user_state.dart';

class UserNeighborhoodCard extends StatefulWidget {
  UserNeighborhoodClass userNeighborhood;
  CurrentUserState? currentUserState;
  bool launchUrl;
  UserNeighborhoodCard({ required this.userNeighborhood, this.currentUserState = null,
    this.launchUrl = false, });

  @override
  _UserNeighborhoodCardState createState() => _UserNeighborhoodCardState();
}

class _UserNeighborhoodCardState extends State<UserNeighborhoodCard> {
  Buttons _buttons = Buttons();
  ColorsService _colors = ColorsService();
  DateTimeService _dateTime = DateTimeService();
  Style _style = Style();

  @override
  Widget build(BuildContext context) {
    return Build1(context, widget.userNeighborhood);
  }

  Widget Build1(BuildContext context, UserNeighborhoodClass userNeighborhood) {
    String createdAt = _dateTime.Format(userNeighborhood.createdAt, 'yyyy-MM-dd');
    String rolesDefault = '';
    if (userNeighborhood.status == 'default') {
      rolesDefault += '(default) ';
    }
    rolesDefault += userNeighborhood.roles.join(', ');
    List<Widget> colsAmbassadorUpdate = [];
    if (userNeighborhood.roles.contains('ambassador')) {
      colsAmbassadorUpdate = [
        _style.SpacingH('medium'),
        _buttons.LinkInline(context, 'Ambassador Update', '/au/${userNeighborhood.neighborhoodUName}',
          launchUrl: widget.launchUrl,),
      ];
    }
    return Container(padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: _colors.colors['primary'], width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buttons.LinkInline(context, '${userNeighborhood.neighborhoodUName}', '/n/${userNeighborhood.neighborhoodUName}',
            launchUrl: widget.launchUrl,),
          _style.Text1(', ${createdAt} ${rolesDefault}'),
          ...colsAmbassadorUpdate,
        ]
      ),
    );
  }
}
