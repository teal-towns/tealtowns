import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app_scaffold.dart';
import '../common/buttons.dart';
import '../common/style.dart';
import '../common/timeline_progress.dart';
import '../modules/neighborhood/neighborhoods.dart';
import '../modules/neighborhood/neighborhood_state.dart';

class HomeComponent extends StatefulWidget {
  @override
  _HomeComponentState createState() => _HomeComponentState();
}

class _HomeComponentState extends State<HomeComponent> {
  Buttons _buttons = Buttons();
  Style _style = Style();

  List<Map<String, dynamic>> _steps = [
    { 'title': 'Mission', 'icon': Icons.flag, 'descriptionSteps': [
      'To address the loneliness and climate change crises, our mission is to help neighbors green their town together',
      'We work across 3 scales: 1. Neighborhood, 2. Superblock, 3. Town',
    ], },
    { 'title': 'Neighborhood', 'icon': Icons.house, 'descriptionSteps': [
      'We organize into 100 - 150 person neighborhoods, working together to bring Belonging and Sustainability to them',
      'The first step is Shared Meals with Neighbors',
    ], },
    { 'title': 'Superblock', 'icon': Icons.home_work, 'descriptionSteps': [
      'Collections of adjacent neighborhoods form Superblocks: car free communities where roads are reclaimed for nature and people',
    ], },
    { 'title': 'Town', 'icon': Icons.real_estate_agent, 'descriptionSteps': [
      'Collections of adjacent Superblocks form Teal Towns: carbon neutral cities where humans and nature thrive',
    ], },
    { 'title': 'Weekly Challenge', 'icon': Icons.add_task, 'descriptionSteps': [
      'Each step toward Belonging and Sustainability is broken down into a single weekly action',
      'Neighbors work together to progress each week along the journey',
    ], },
    { 'title': 'Belonging', 'icon': Icons.volunteer_activism, 'descriptionSteps': [
      'People are the foundation, so the first step is to connect with your neighbors over a shared meal and other weekly events',
      'Regular meetings build trust and facilitate conversations and small 1% greener actions, such as co-owning items',
    ], },
    // { 'title': 'Sustainable', 'icon': Icons.compost, 'descriptionSteps': [
    //   'As the group grows to 100 - 150 people, larger green projects become possible',
    //   'Neighbors work together on green projects to reduce the carbon footprint of their neighborhood',
    // ], },
  ];

  @override
  Widget build(BuildContext context) {
    return AppScaffoldComponent(
      listWrapper: true,
      width: 1200,
      body: Column(
        children: [
          _style.Text1('Welcome to TealTowns!', size: 'xlarge', fontWeight: FontWeight.bold),
          _style.SpacingH('medium'),
          _buttons.Link(context, 'Start building your Teal Town', '/neighborhoods'),
          _style.SpacingH('medium'),
          TimelineProgress(steps: _steps, stepHeight: 125, showNumbers: false,),
          _style.SpacingH('xlarge'),
          Neighborhoods(),
          _style.SpacingH('xlarge'),
        ]
      )
    );
  }
}
