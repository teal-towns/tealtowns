import 'dart:convert';
import 'package:flutter/material.dart';

import '../../common/form_input/input_fields.dart';
import '../../common/form_input/input_file.dart';
import '../../common/socket_service.dart';
import './polygon_upload.dart';

class PolygonSelect extends StatefulWidget {
  Function(Map<String, dynamic>)? onChanged;

  PolygonSelect({ @required this.onChanged = null, });

  @override
  _PolygonSelectState createState() => _PolygonSelectState();
}

class _PolygonSelectState extends State<PolygonSelect> {
  InputFields _inputFields = InputFields();
  SocketService _socketService = SocketService();

  List<String> _routeIds = [];
  var _formVals = {};
  var _optsPolygons = [];

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('searchPolygons', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        _optsPolygons = [];
        for (int ii = 0; ii < data['polygons'].length; ii++) {
          _optsPolygons.add({ 'value': data['polygons'][ii]['uName'],
            'label': data['polygons'][ii]['title'], });
        }
        setState(() { _optsPolygons = _optsPolygons; });
      }
    }));

    // Seed with all options to start.
    _socketService.emit('searchPolygons', { 'searchText': '' });
  }

  @override
  void dispose() {
    _socketService.offRouteIds(_routeIds);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 150,
          child: _inputFields.inputSelectSearch(_optsPolygons, context, _formVals, 'polygonUName', hint: 'Polygon search..', onChanged: (String newVal) {
              setState(() { _formVals = _formVals; });
              if (widget.onChanged != null) {
                widget.onChanged!({ 'uName': _formVals['polygonUName'] });
              }
            }, onKeyUp: (String val) {
              _socketService.emit('searchPolygons', { 'searchText': val });
            },
          ),
        ),
        Text('OR'),
        SizedBox(width: 10),
        PolygonUpload(onChanged: widget.onChanged, ),
      ]
    );
  }

}
