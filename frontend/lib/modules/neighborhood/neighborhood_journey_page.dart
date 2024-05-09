import 'package:flutter/material.dart';

import '../../app_scaffold.dart';
import './neighborhood_journey.dart';

class NeighborhoodJourneyPage extends StatefulWidget {
  @override
  _NeighborhoodJourneyPageState createState() => _NeighborhoodJourneyPageState();
}

class _NeighborhoodJourneyPageState extends State<NeighborhoodJourneyPage> {

  @override
  Widget build(BuildContext context) {
    return AppScaffoldComponent(
      listWrapper: true,
      body: NeighborhoodJourney(),
    );
  }
}
