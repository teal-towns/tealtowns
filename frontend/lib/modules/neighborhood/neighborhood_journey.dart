import 'package:flutter/material.dart';

import '../../common/timeline_progress.dart';
import './neighborhood_journey_service.dart';
import '../../common/style.dart';

class NeighborhoodJourney extends StatefulWidget {
  List<Map<String, dynamic>> belongingSteps;
  List<Map<String, dynamic>> sustainableSteps;
  bool currentStepOnly;
  bool showTitles;
  NeighborhoodJourney({this.belongingSteps = const [], this.sustainableSteps = const [],
    this.currentStepOnly = false, this.showTitles = false, });

  @override
  _NeighborhoodJourneyState createState() => _NeighborhoodJourneyState();
}

class _NeighborhoodJourneyState extends State<NeighborhoodJourney> {
  NeighborhoodJourneyService _neighborhoodJourneyService = NeighborhoodJourneyService();
  Style _style = Style();

  @override
  void initState() {
    super.initState();

    if (widget.belongingSteps.length < 1) {
      widget.belongingSteps = _neighborhoodJourneyService.BelongingSteps();
    }
    if (widget.sustainableSteps.length < 1) {
      widget.sustainableSteps = _neighborhoodJourneyService.SustainableSteps();
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> colsBelonging = [];
    if (widget.belongingSteps.length > 0) {
      if (widget.showTitles) {
        colsBelonging += [
          _style.Text1('Belonging Journey', size: 'large', fontWeight: FontWeight.bold),
          _style.SpacingH('medium'),
        ];
      }
      colsBelonging += [
        TimelineProgress(steps: widget.belongingSteps, stepHeight: 100, currentStepOnly: widget.currentStepOnly, ),
        _style.SpacingH('large'),
      ];
    }
    List<Widget> colsSustainable = [];
    // if (widget.sustainableSteps.length > 0) {
    //   if (widget.showTitles) {
    //     colsSustainable = [
    //       _style.Text1('Sustainable Journey', size: 'large', fontWeight: FontWeight.bold),
    //       _style.SpacingH('medium'),
    //     ];
    //   }
    //   colsSustainable += [
    //     TimelineProgress(steps: widget.sustainableSteps, stepHeight: 100, currentStepOnly: widget.currentStepOnly, ),
    //     _style.SpacingH('large'),
    //   ];
    // }

    // if (colsBelonging.length > 0 && colsSustainable.length > 0) {
    //   colsBelonging.add(_style.SpacingH('xlarge'));
    // }
    return Column(
      children: [
        ...colsBelonging,
        ...colsSustainable,
      ]
    );
  }
}
