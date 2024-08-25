import 'package:flutter/material.dart';

import './layout_service.dart';

class LayoutWrap extends StatefulWidget {
  List<Widget> items;
  double width;
  double spacing;
  String align;
  int pageSize;

  LayoutWrap({Key? key, required this.items, this.width = 250, this.spacing = 20, this.align = 'center',
    this.pageSize = 0,}) : super(key: key);

  @override
  _LayoutWrapState createState() => _LayoutWrapState();
}

class _LayoutWrapState extends State<LayoutWrap> {
  LayoutService _layoutService = LayoutService();

  int _page = 1;

  @override
  Widget build(BuildContext context) {
    List<Widget> items = [];
    bool hasNextPage = false;
    if (widget.pageSize > 0) {
      hasNextPage = true;
      int maxItems = _page * widget.pageSize;
      if (maxItems > widget.items.length) {
        maxItems = widget.items.length;
        hasNextPage = false;
      }
      items = widget.items.sublist(0, maxItems);
    }
    List<Widget> cols = [
      _layoutService.WrapWidth(items, width: widget.width, spacing: widget.spacing, align: widget.align),
    ];
    if (hasNextPage) {
      cols += [
        TextButton(child: Text('Load More'), onPressed: () {
          setState(() { _page += 1; });
        },),
      ];
    }
    return Column(
      children: [
        ...cols,
      ],
    );
  }
}