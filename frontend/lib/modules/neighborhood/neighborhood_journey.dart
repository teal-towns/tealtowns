import 'package:flutter/material.dart';

import '../../common/timeline_progress.dart';
import './neighborhood_journey_service.dart';

class NeighborhoodJourney extends StatefulWidget {
  List<Map<String, dynamic>> steps;
  bool currentStepOnly;
  NeighborhoodJourney({this.steps = const [], this.currentStepOnly = false, });

  @override
  _NeighborhoodJourneyState createState() => _NeighborhoodJourneyState();
}

class _NeighborhoodJourneyState extends State<NeighborhoodJourney> {
  NeighborhoodJourneyService _neighborhoodJourneyService = NeighborhoodJourneyService();

  @override
  void initState() {
    super.initState();

    if (widget.steps.length < 1) {
      widget.steps = _neighborhoodJourneyService.Steps();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TimelineProgress(steps: widget.steps, stepHeight: 100, currentStepOnly: widget.currentStepOnly, );
  }
}
