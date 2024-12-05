import 'package:flutter/material.dart';

class StepShowMore extends StatefulWidget {
  List<Widget> stepsContent;
  bool showAll;
  Widget? header;
  double spacing;
  String align;

  StepShowMore({Key? key, required this.stepsContent, this.showAll = false, this.header = null, this.spacing = 10,
    this.align = 'start', }) : super(key: key);

  @override
  _StepShowMoreState createState() => _StepShowMoreState();
}

class _StepShowMoreState extends State<StepShowMore> {
  int _stepIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget header = widget.header != null ? widget.header! : SizedBox.shrink();
    List<Widget> cols = [ header, ];
    for (int i = 0; i < widget.stepsContent.length; i++) {
      if (i <= _stepIndex || widget.showAll) {
        cols.add(widget.stepsContent[i]);
        if (widget.spacing > 0) {
          cols.add(SizedBox(height: widget.spacing));
        }
      } else {
        break;
      }
    }

    if (_stepIndex < widget.stepsContent.length - 1 && !widget.showAll) {
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
    CrossAxisAlignment align = widget.align == 'center' ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    return (
      Column(
        crossAxisAlignment: align,
        children: [
          ...cols,
        ]
      )
    );
  }

}
