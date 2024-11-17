import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app_scaffold.dart';
import '../common/buttons.dart';
import '../common/colors_service.dart';
import '../common/style.dart';
// import '../common/video.dart';
import '../modules/neighborhood/neighborhoods.dart';
import '../modules/neighborhood/neighborhood_state.dart';
// import '../modules/event/featured_event_photos.dart';
// import '../modules/event/weekly_events.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Buttons _buttons = Buttons();
  ColorsService _colors = ColorsService();
  Style _style = Style();

  @override
  void initState() {
    super.initState();

    var neighborhoodState = Provider.of<NeighborhoodState>(context, listen: false);
    if (neighborhoodState.defaultUserNeighborhood != null) {
      Timer(Duration(milliseconds: 100), () {
        context.go('/ne/${neighborhoodState.defaultUserNeighborhood!.neighborhood.uName}');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffoldComponent(
      listWrapper: true,
      body: Column(
        children: [
          _style.Text1('Neighbor Dinners', size: 'xlarge'),
          _style.SpacingH('medium'),
          Neighborhoods(showSeeAll: false, showLink: false, redirectTo: 'events',),
        ]
      )
    );
  }
}
