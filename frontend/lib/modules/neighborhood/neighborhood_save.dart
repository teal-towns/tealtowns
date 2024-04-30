import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_scaffold.dart';
import '../../common/form_input/form_save.dart';
import './neighborhood_class.dart';
import '../user_auth/current_user_state.dart';

class NeighborhoodSave extends StatefulWidget {
  String uName;
  double lng;
  double lat;
  NeighborhoodSave({this.uName = '', this.lng = 0, this.lat = 0, });

  @override
  _NeighborhoodSaveState createState() => _NeighborhoodSaveState();
}

class _NeighborhoodSaveState extends State<NeighborhoodSave> {
  Map<String, Map<String, dynamic>> _formFields = {
    'uName': { 'type': 'text', 'label': 'Short name', 'required': true, },
    'location': { 'type': 'location', 'nestedCoordinates': true, 'required': true, },
    'title': { 'required': true, },
  };
  Map<String, dynamic> _formValsDefault = {
  };
  String _formMode = '';
  List<String> _formStepKeys = [];
  String _title = 'Create a neighborhood';

  @override
  void initState() {
    super.initState();

    if (widget.lng != 0 && widget.lat != 0) {
      _formValsDefault['location'] = { 'type': 'Point', 'coordinates': {'lng': widget.lng, 'lat': widget.lat, } };
    }
  }

  @override
  Widget build(BuildContext context) {
    double fieldWidth = 300;
    Widget content = FormSave(formVals: NeighborhoodClass.fromJson(_formValsDefault).toJson(), dataName: 'neighborhood',
      routeGet: 'GetNeighborhoodByUName', routeSave: 'SaveNeighborhood', uName: widget.uName, fieldWidth: fieldWidth,
      formFields: _formFields, mode: _formMode, stepKeys: _formStepKeys, title: _title,
      parseData: (dynamic data) => NeighborhoodClass.fromJson(data).toJson(),
      preSave: (dynamic data) {
        data = NeighborhoodClass.fromJson(data).toJson();
        return data;
      },
      onSave: (dynamic data) {
        String uName = data['neighborhood']['uName'];
        context.go('/n/${uName}');
      }
    );
    return AppScaffoldComponent(
      listWrapper: true,
      body: content,
    );
  }
}
