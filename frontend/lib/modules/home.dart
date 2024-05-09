import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app_scaffold.dart';
import '../common/buttons.dart';
import '../common/location_service.dart';
import '../common/style.dart';
import '../common/timeline_progress.dart';
import '../modules/neighborhood/neighborhoods.dart';
import '../modules/neighborhood/neighborhood_state.dart';
import '../modules/user_auth/current_user_state.dart';

class HomeComponent extends StatefulWidget {
  @override
  _HomeComponentState createState() => _HomeComponentState();
}

class _HomeComponentState extends State<HomeComponent> {
  Buttons _buttons = Buttons();
  Style _style = Style();
  LocationService _locationService = LocationService();

  List<double> _lngLat = [0, 0];

  List<Map<String, dynamic>> _steps = [
    { 'title': 'Mission', 'icon': Icons.flag, 'descriptionSteps': [
      'To address the loneliness and climate change crises, our mission is to help neighbors green their town together',
    ], },
    { 'title': 'Neighborhoods', 'icon': Icons.house, 'descriptionSteps': [
      'We organize into 100 - 150 people neighborhoods, working to bring Belonging and Sustainability to them',
    ], },
    { 'title': 'Belonging', 'icon': Icons.volunteer_activism, 'descriptionSteps': [
      'People are the foundation, so the first step is to connect neighbors over a shared meal and other weekly events',
      'Regular meetings build trust and community and allow for conversations and small 1% greener actions, such as co-owning items',
    ], },
    { 'title': 'Sustainable', 'icon': Icons.compost, 'descriptionSteps': [
      'As the group grows to 100 - 150 people, larger green projects become possible',
      'Neighbors work together on green projects to reduce the carbon footprint of their neighborhood',
    ], },
    { 'title': 'Weekly Challenge', 'icon': Icons.add_task, 'descriptionSteps': [
      'Each step of the Neighborhood Journey toward Belonging and Sustainability is broken down into a single weekly action',
      'Neighbors work together to progress each week along the Journey',
    ], },
    { 'title': 'Superblocks', 'icon': Icons.home_work, 'descriptionSteps': [
      'Collections of adjacent neighborhoods form Superblocks: car free communities where roads are reclaimed for nature and people',
    ], },
    { 'title': 'Teal Towns', 'icon': Icons.real_estate_agent, 'descriptionSteps': [
      'Collections of adjacent Superblocks form Teal Towns: carbon neutral cities where humans and nature thrive',
    ], },
  ];

  @override
  void initState() {
    super.initState();
    // Timer(Duration(milliseconds: 500), () {
    //   context.go('/about');
    // });

    // var currentUserState = Provider.of<CurrentUserState>(context, listen: false);
    // var neighborhoodState = Provider.of<NeighborhoodState>(context, listen: false);
    // if(currentUserState.isLoggedIn) {
    //   String userId = currentUserState.currentUser.id;
    //   neighborhoodState.CheckAndGet(userId);
    // } else {
    //   neighborhoodState.ClearUserNeighborhoods(notify: false);
    // }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init();
    });
  }

  @override
  Widget build(BuildContext context) {
    // var neighborhoodState = context.watch<NeighborhoodState>();
    // if (neighborhoodState.defaultUserNeighborhood != null) {
    //   context.go('/n/${neighborhoodState.defaultUserNeighborhood!.neighborhood.uName}');
    // }

    Widget neighborhoods = LinearProgressIndicator();
    if (_locationService.LocationValid(_lngLat)) {
      neighborhoods = Neighborhoods(lng: _lngLat[0], lat: _lngLat[1],);
    }

    double imageSize = 150;
    return AppScaffoldComponent(
      listWrapper: true,
      width: 1200,
      body: Column(
        children: [
          // Text('Loading..'),
          _style.Text1('Welcome to TealTowns!', size: 'xlarge', fontWeight: FontWeight.bold),
          _style.SpacingH('medium'),
          TimelineProgress(steps: _steps, stepHeight: 125, ),
          // Row(
          //   children: [
          //     Expanded(flex: 1, child: _style.Text1('To address climate change and loneliness, our mission is to help neighbors green their town together.',
          //       size: 'large', fontWeight: FontWeight.bold)),
          //     _style.SpacingV('xlarge'),
          //     Image.asset('assets/images/green-city-1.jpg', height: imageSize * 1.5, width: imageSize * 1.5, fit: BoxFit.cover,),
          //   ]
          // ),
          // _style.SpacingH('medium'),
          // Row(
          //   children: [
          //     Image.asset('assets/images/shared-meal.jpg', height: imageSize, width: imageSize, fit: BoxFit.cover,),
          //     _style.SpacingV('xlarge'),
          //     Expanded(flex: 1, child: _style.Text1('Connect with your neighbors over a shared meal and other weekly events.', fontWeight: FontWeight.bold)),
          //   ]
          // ),
          // _style.SpacingH('medium'),
          // Row(
          //   children: [
          //     Image.asset('assets/images/event.jpg', height: imageSize, width: imageSize, fit: BoxFit.cover,),
          //     _style.SpacingV('xlarge'),
          //     Expanded(flex: 1, child: Column(
          //       crossAxisAlignment: CrossAxisAlignment.start,
          //       children: [
          //         _style.Text1('Regular meetings build trust and community and allow for conversations and small 1% greener actions.', fontWeight: FontWeight.bold),
          //         _style.SpacingH('medium'),
          //         _style.Text1('Such as co-owning items to reduce carbon footprint of your neighborhood.'),
          //         _style.SpacingH('medium'),
          //         _style.Text1('As the group grows to 100 - 150 people, larger green projects become possible.'),
          //       ]
          //     )),
          //   ]
          // ),
          _style.SpacingH('xlarge'),
          _style.Text1('Join your neighborhood to get started', size: 'large', fontWeight: FontWeight.bold),
          _style.SpacingH('medium'),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.center,
          //   children: [
          //     // _buttons.LinkElevated(context, 'Create event', '/weekly-event-save'),
          //     _buttons.LinkElevated(context, 'Join your neighborhood', '/neighborhoods'),
          //     // _style.SpacingV('xlarge'),
          //     // _buttons.LinkElevated(context, 'Join or create an event', '/weekly-events'),
          //   ]
          // ),
          neighborhoods,
          _style.SpacingH('xlarge'),
        ]
      )
    );
  }

  void _init() async {
    List<double> lngLat = await _locationService.GetLocation(context);
    if(mounted) {
      setState(() {
        _lngLat = lngLat;
      });
    }
  }
}
