import 'package:flutter/material.dart';

import '../../common/colors_service.dart';
import '../../common/step_show_more.dart';

class WelcomeAbout extends StatefulWidget {
  @override
  _WelcomeAboutState createState() => _WelcomeAboutState();
}

class _WelcomeAboutState extends State<WelcomeAbout> {
  ColorsService _colorsService = ColorsService();

  List<Widget> _stepsContent = [
    Text("Welcome to TealTowns! To address climate change and loneliness, our mission is to help neighbors green their town together. The first step is simple: connect with your neighbors over a shared meal and other weekly events."),
    Text("Regular meetings build trust and community and allow for conversations and small 1% greener actions such as co-owning items to reduce carbon footprint of your neighborhood."),
    Text("As the group grows to 100 - 150 people, larger green projects become possible."),
    Text("Neighborhoods and blocks can combine to form Shared Ownership Superblocks and start to buy back their town, escape the rent trap, and free up resources to make bigger infrastructure changes. Our AI Urban Planner and Visualizer helps suggest and plan projects."),
    Text("Get started by joining (or creating) your first events with neighbors."),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _colorsService.colors['greyLight'],
      padding: EdgeInsets.all(20),
      child: StepShowMore(stepsContent: _stepsContent)
    );
  }
}
