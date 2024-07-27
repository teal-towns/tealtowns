import 'dart:convert';
import 'package:flutter/material.dart';

import '../../common/form_input/input_fields.dart';
import '../../common/layout_service.dart';
import '../../common/parse_service.dart';
import '../../common/socket_service.dart';
import '../../common/style.dart';

class SharedItemsSearch extends StatefulWidget {
  Function(dynamic)? onSelected;
  SharedItemsSearch({this.onSelected = null,});

  @override
  _SharedItemsSearchState createState() => _SharedItemsSearchState();
}

class _SharedItemsSearchState extends State<SharedItemsSearch> {
  InputFields _inputFields = InputFields();
  LayoutService _layoutService = LayoutService();
  ParseService _parseService = ParseService();
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();
  Style _style = Style();

  Map<String, dynamic> _formVals = {};
  bool _loading = false;
  List<Map<String, dynamic>> _items = [];
  String _message = '';

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('AmazonSearch', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      print ('data ${data}');
      if (data['valid'] == 1) {
        _items = [];
        for (var item in data['products']) {
          _items.add(_parseService.parseMapStringDynamic(item));
        }
        setState(() { _items = _items; });
      } else {
        _message = data['message'].length > 0 ? data['message'] : 'Error.';
      }
      setState(() {
        _loading = false;
      });
    }));
  }

  @override
  void dispose() {
    _socketService.offRouteIds(_routeIds);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> cols = [];
    if (_loading) {
      cols = [ LinearProgressIndicator() ];
    } else {
      cols = [
        _layoutService.WrapWidth(_items.map((item) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(item['image'], height: 300, width: double.infinity, fit: BoxFit.cover),
              _style.SpacingH('medium'),
              _style.Text1(item['title']),
              _style.SpacingH('medium'),
              _style.Text1(item['price']),
              _style.SpacingH('medium'),
              TextButton(child: Text('Select'), onPressed: () {
                if (widget.onSelected != null) {
                  Map<String, dynamic> data = {
                    'title': item['title'],
                    'imageUrls': [item['image']],
                    'currentPrice': item['price'],
                  };
                  widget.onSelected!(data);
                }
              }),
            ],
          );
        }).toList(),),
      ];
    }
    return Column(
      children: [
        _inputFields.inputText(_formVals, 'search', label: 'Search items', onChanged: (String val) {
          setState(() { _loading = true; });
          _socketService.emit('AmazonSearch', {'search': val});
        }),
        _style.SpacingH('medium'),
        ...cols,
        _style.SpacingH('medium'),
        _style.Text1(_message),
        _style.SpacingH('medium'),
      ],
    );
  }
}