import 'dart:convert';
import 'package:flutter/material.dart';

import './form_input/image_save.dart';
import './form_input/input_fields.dart';
import './form_input/input_location.dart';
import './layout_service.dart';
import './socket_service.dart';

class Paging extends StatefulWidget {
  Widget body;
  String dataName;
  String routeGet;
  Function(dynamic)? onGet;
  int itemsPerPage;
  String sortKeys;
  Map<String, dynamic> dataDefault;
  List<Map<String, dynamic>> sortOpts;
  Map<String, Map<String, dynamic>>? filterFields;
  double filterWidth;

  Paging({Key? key, required this.body, this.dataName= '', this.routeGet = '', this.onGet = null,
    this.itemsPerPage = 10, this.sortKeys = '-createdAt', this.dataDefault = const {},
    this.sortOpts = const [], this.filterFields = const {}, this.filterWidth = 300, }) : super(key: key);

  @override
  _PagingState createState() => _PagingState();
}

class _PagingState extends State<Paging> {
  List<String> _routeIds = [];
  InputFields _inputFields = InputFields();
  LayoutService _layoutService = LayoutService();
  SocketService _socketService = SocketService();

  bool _loading = true;
  String _message = '';
  bool _canLoadMore = false;
  int _lastPageNumber = 1;
  List<dynamic> _items = [];
  Map<String, dynamic> _filters = {};

  @override
  void initState() {
    super.initState();

    if (widget.sortOpts.length > 0) {
      for (int i = 0; i < widget.sortOpts.length; i++) {
        if (widget.sortOpts[i]['value'] == widget.sortKeys) {
          _filters['sortKeys'] = widget.sortOpts[i]['value'];
          break;
        }
      }
    }

    _routeIds.add(_socketService.onRoute(widget.routeGet, callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      print ('data ${data}');
      if (data['valid'] == 1) {
        if (data[widget.dataName].length < widget.itemsPerPage) {
          _canLoadMore = false;
        } else {
          _canLoadMore = true;
        }
        if (widget.onGet != null) {
          if (_lastPageNumber == 1) {
            _items = [];
          }
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
  void dispose() {
    _socketService.offRouteIds(_routeIds);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> colsFooter = [];
    if (_loading) {
      colsFooter = [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: LinearProgressIndicator(),
        )
      ];
    }
    else if (_canLoadMore) {
      colsFooter = [
        ElevatedButton(
          onPressed: () {
            _message = '';
            _loading = true;
            _lastPageNumber += 1;
            setState(() { _message = _message; _loading = _loading; _lastPageNumber = _lastPageNumber; });
            GetItems(pageNumber: _lastPageNumber);
          },
          child: Text('Load More'),
        )
      ];
    }
    List<Widget> colsFilters = [];
    if (widget.filterFields!.entries.length > 0) {
      for (var keyVal in widget.filterFields!.entries) {
        colsFilters.add(FormField(keyVal.key, keyVal.value));
      }
    }
    if (widget.sortOpts.length > 0) {
      colsFilters.add(_inputFields.inputSelect(widget.sortOpts, _filters, 'sortKeys', label: 'Sort', onChanged: (String newVal) {
        widget.sortKeys = newVal;
        GetItems(pageNumber: 1);
      }));
    }
    if (colsFilters.length > 0) {
      colsFilters = [
        _layoutService.WrapWidth(colsFilters, width: widget.filterWidth,),
        SizedBox(height: 20),
      ];
    }
    List<Widget> colsNoResults = [];
    if (_items.length < 1 && !_loading) {
      colsNoResults = [
        Text('No results found'),
        SizedBox(height: 10),
      ];
    }
    return (
      Column(
        children: [
          ...colsFilters,
          widget.body,
          SizedBox(height: 10),
          ...colsNoResults,
          ...colsFooter,
        ]
      )
    );
  }

  void _init() async {
    GetItems();
  }

  void GetItems({int pageNumber = -1}) {
    if (_lastPageNumber == 0) {
      _lastPageNumber = 1;
    }
    if (pageNumber > 0) {
      _lastPageNumber = pageNumber;
    }
    setState(() {
      _loading = true;
      _message = '';
      _canLoadMore = false;
      _lastPageNumber = _lastPageNumber;
    });
    var data = {
      'skip': (_lastPageNumber - 1) * widget.itemsPerPage,
      'limit': widget.itemsPerPage,
      'sortKeys': widget.sortKeys,
    };
    for (var key in widget.dataDefault.keys) {
      data[key] = widget.dataDefault[key];
    }
    for (var keyVal in widget.filterFields!.entries) {
      if (_filters.containsKey(keyVal.key)) {
        data[keyVal.key] = _filters[keyVal.key];
      }
    }
    _socketService.emit(widget.routeGet, data);
  }

  // Copied / adapted from form_save - abstract this (pull out _filters?)
  Widget FormField(key, value) {
    Widget input = SizedBox.shrink();
    String label = '';
    String helpText = value.containsKey('helpText') ? value['helpText'] : '';
    if (value.containsKey('label')) {
      label = value['label'];
    } else {
      label = key.replaceAllMapped(RegExp(r'([A-Z])'), (Match match) => ' ${match[0]}');
      label = label[0].toUpperCase() + label.substring(1);
    }
    bool required = value.containsKey('required') ? value['required'] : true;
    if (value['type'] == 'select') {
      input = _inputFields.inputSelect(value['options'], _filters, key, label: label, helpText: helpText,
        onChanged: (String newVal) { OnChanged(); }, );
    // } else if (value['type'] == 'selectButtons') {
    //   input = _inputFields.inputSelectButtons(value['options'], _filters, key, label: label, helpText: helpText,);
    // } else if (value['type'] == 'multiSelectButtons') {
    //   input = _inputFields.inputMultiSelectButtons(value['options'], _filters, key, label: label, helpText: helpText,);
    // } else if (value['type'] == 'time') {
    //   input = _inputFields.inputTime(_filters, key, label: label, required: required, helpText: helpText,);
    // } else if (value['type'] == 'number') {
    //   double? min = value.containsKey('min') ? value['min'] : null;
    //   double? max = value.containsKey('max') ? value['max'] : null;
    //   input = _inputFields.inputNumber(_filters, key, label: label, required: required, min: min, max: max,
    //     helpText: helpText,);
    // } else if (value['type'] == 'image') {
    //   bool multiple = value.containsKey('multiple') ? value['multiple'] : false;
    //   int maxImageSize = value.containsKey('maxImageSize') ? value['maxImageSize'] : 1200;
    //   input = ImageSaveComponent(formVals: _filters, formValsKey: key, multiple: multiple,
    //     label: label, imageUploadSimple: true, maxImageSize: maxImageSize,);
    } else {
      int minLines = value.containsKey('minLines') ? value['minLines'] : 1;
      input = _inputFields.inputText(_filters, key, label: label, required: required, minLines: minLines,
        helpText: helpText, onChange: (String newVal) { OnChanged(); },);
    }
    return input;
  }

  void OnChanged() {
    GetItems(pageNumber: 1);
  }
}
