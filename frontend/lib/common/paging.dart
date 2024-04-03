import 'dart:convert';
import 'package:flutter/material.dart';

import './form_input/input_fields.dart';
import './socket_service.dart';

class Paging extends StatefulWidget {
  Widget body;
  String dataName;
  String routeGet;
  Function(dynamic)? onGet;
  int itemsPerPage;
  String sortKeys;

  Paging({Key? key, required this.body, this.dataName= '', this.routeGet = '', this.onGet = null,
    this.itemsPerPage = 5, this.sortKeys = '-createdAt', }) : super(key: key);

  @override
  _PagingState createState() => _PagingState();
}

class _PagingState extends State<Paging> {
  List<String> _routeIds = [];
  InputFields _inputFields = InputFields();
  SocketService _socketService = SocketService();

  bool _loading = true;
  String _message = '';
  bool _canLoadMore = false;
  int _lastPageNumber = 1;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute(widget.routeGet, callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        if (data[widget.dataName].length < widget.itemsPerPage) {
          _canLoadMore = false;
        } else {
          _canLoadMore = true;
        }
        if (widget.onGet != null) {
          _items += data[widget.dataName];
          widget.onGet!(_items);
          setState(() { _items = _items; });
        }
      } else {
        setState(() { _message = data['message'].length > 0 ? data['message'] : 'Error, please try again.'; });
      }
      setState(() { _loading = false; _canLoadMore = _canLoadMore; _lastPageNumber = _lastPageNumber; });
    }));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init();
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> colsFooter = [];
    if (_canLoadMore) {
      colsFooter = [
        ElevatedButton(
          onPressed: () {
            _message = '';
            _loading = true;
            _lastPageNumber += 1;
            setState(() { _message = _message; _loading = _loading; _lastPageNumber = _lastPageNumber; });
            GetItems();
          },
          child: Text('Load More'),
        )
      ];
    }
    return (
      Column(
        children: [
          widget.body,
          SizedBox(height: 10),
          ...colsFooter,
        ]
      )
    );
  }

  void _init() async {
    GetItems();
  }

  void GetItems() {
    setState(() {
      _loading = true;
      _message = '';
      _canLoadMore = false;
    });
    if (_lastPageNumber == 0) {
      _lastPageNumber = 1;
    }
    var data = {
      'skip': (_lastPageNumber - 1) * widget.itemsPerPage,
      'limit': widget.itemsPerPage,
      'sortKeys': widget.sortKeys,
    };
    _socketService.emit(widget.routeGet, data);
  }
}
