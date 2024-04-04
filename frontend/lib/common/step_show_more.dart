import 'package:flutter/material.dart';

class StepShowMore extends StatefulWidget {
  List<Widget> stepsContent;

  StepShowMore({Key? key, required this.stepsContent, }) : super(key: key);

  @override
  _StepShowMoreState createState() => _StepShowMoreState();
}

class _StepShowMoreState extends State<StepShowMore> {
  int _stepIndex = 0;

  @override
  Widget build(BuildContext context) {
    List<Widget> cols = [];
    for (int i = 0; i < widget.stepsContent.length; i++) {
      if (i <= _stepIndex) {
        cols.add(widget.stepsContent[i]);
      } else {
        break;
      }
    }

    if (_stepIndex < widget.stepsContent.length - 1) {
      cols.add(
        TextButton(
          onPressed: () {
            _stepIndex += 1;
            setState(() { _stepIndex = _stepIndex; });
          },
          child: Text('Show More'),
        )
      );
    }
    return (
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...cols,
        ]
      )
    );
  }

}
