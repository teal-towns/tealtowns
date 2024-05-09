import 'package:flutter/material.dart';

import './style.dart';

class TimelineProgress extends StatefulWidget {
  List<Map<String, dynamic>> steps;
  List<Color> colors;
  double stepHeight;
  bool currentStepOnly;

  TimelineProgress({Key? key, required this.steps, this.colors = const [], this.stepHeight = 50,
    this.currentStepOnly = false, }) : super(key: key);

  @override
  _TimelineProgressState createState() => _TimelineProgressState();
}

class _TimelineProgressState extends State<TimelineProgress> {
  Style _style = Style();

  // @override
  // void initState() {
  //   super.initState();
  // }

  @override
  Widget build(BuildContext context) {
    if (widget.steps.length < 1) {
      return SizedBox.shrink();
    }

    if (widget.colors.length < 1) {
      widget.colors = [
        Color.fromRGBO(254,205,171,1),
        Color.fromRGBO(216,167,229,1),
        Color.fromRGBO(169,210,212,1),
        Color.fromRGBO(239,230,171,1),
        Color.fromRGBO(243,179,221,1),
        Color.fromRGBO(255,183,176,1),
        Color.fromRGBO(205,189,247,1),
        Color.fromRGBO(195,223,177,1),
        Color.fromRGBO(182,227,232,1),
        Color.fromRGBO(253,220,174,1),
      ];
    }

    return Column(
      children: [
        ...widget.steps.map((step) => BuildStep(step, widget.steps.indexOf(step))).toList(),
      ]
    );
  }

  Widget BuildStep(Map<String, dynamic> step, int stepIndex) {
    if (widget.currentStepOnly && (!step.containsKey('current') || !step['current'])) {
      return SizedBox.shrink();
    }
    double height = widget.stepHeight;
    double opacity = step['opacity'] ?? 1;

    List<Widget> rowsTitle = [
      _style.Text1('${(stepIndex + 1)}.', size: 'large', fontWeight: FontWeight.bold,),
      // _style.Spacing(height: 'small'),
      _style.Text1(step['title'], size: 'large', fontWeight: FontWeight.bold,),
    ];
    Radius radius = Radius.circular(50);
    List<Widget> icon = [ Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(radius),
        color: Color.fromRGBO(255,255,255,0.5),
      ),
      child: Icon(step['icon'], size: (height - (5 * 3 * 2))),
    ) ];
    List<Widget> line = [ Container(
      color: Colors.black,
      height: height,
      width: 5,
      child: Container(),
    ) ];
    EdgeInsets padding = EdgeInsets.only(left: 10, right: 10);
    if (!step.containsKey('description') && step.containsKey('descriptionSteps')) {
      List<Widget> descriptions = [];
      for (var j = 0; j < step['descriptionSteps'].length; j++) {
        descriptions.add(Text('${step['descriptionSteps'][j]}'));
        if (j < step['descriptionSteps'].length - 1) {
          descriptions.add(SizedBox(height: 10));
        }
      }
      CrossAxisAlignment alignTemp = stepIndex % 2 == 0 ? CrossAxisAlignment.start : CrossAxisAlignment.end;
      step['description'] = Column(crossAxisAlignment: alignTemp,
        mainAxisAlignment: MainAxisAlignment.center, children: descriptions,);
    }

    if (stepIndex % 2 == 0) {
      // left: image, title, right: description
      return Opacity(opacity: opacity, child: Row(
        children: [
          // left
          Expanded(flex: 1, child: Container(
            height: height,
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(topLeft: radius, bottomLeft: radius),
              color: widget.colors[stepIndex],
            ),
            child: Row(
              children: [
                ...icon,
                Expanded(flex: 1, child: Container()),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...rowsTitle,
                  ]
                ),
              ]
            )
          )),
          // middle
          ...line,
          // right
          Expanded(flex: 1, child: Container(
            height: height,
            padding: padding,
            alignment: Alignment.centerLeft,
            child: step['description'],
          )),
        ]
      ));
    } else {
      // left: description, right: title, image
      return Opacity(opacity: opacity, child: Row(
        children: [
          // left
          Expanded(flex: 1, child: Container(
            height: height,
            padding: padding,
            alignment: Alignment.centerRight,
            child: step['description'],
          )),
          // middle
          ...line,
          // right
          Expanded(flex: 1, child: Container(
            alignment: Alignment.centerLeft,
            height: height,
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(topRight: radius, bottomRight: radius),
              color: widget.colors[stepIndex],
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...rowsTitle,
                  ]
                ),
                Expanded(flex: 1, child: Container()),
                ...icon,
              ]
            )
          )),
        ]
      ));
    }
  }
}