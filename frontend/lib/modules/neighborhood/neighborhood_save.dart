import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_scaffold.dart';
import '../../common/form_input/form_save.dart';
import './neighborhood_class.dart';
import './neighborhood_state.dart';
import '../user_auth/current_user_state.dart';

class NeighborhoodSave extends StatefulWidget {
  String uName;
  double lng;
  double lat;
  bool withScaffold;
  Function(dynamic)? onSave;
  NeighborhoodSave({this.uName = '', this.lng = 0, this.lat = 0, this.withScaffold = true, this.onSave = null});

  @override
  _NeighborhoodSaveState createState() => _NeighborhoodSaveState();
}

class _NeighborhoodSaveState extends State<NeighborhoodSave> {
  Map<String, Map<String, dynamic>> _formFields = {
    'location': { 'type': 'location', 'nestedCoordinates': true, 'required': true, },
    'uName': { 'type': 'text', 'label': 'Short name', 'required': true, },
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
        data['neighborhood'] = NeighborhoodClass.fromJson(data['neighborhood']).toJson();
        String userId = Provider.of<CurrentUserState>(context, listen: false).isLoggedIn ?
          Provider.of<CurrentUserState>(context, listen: false).currentUser.id : '';
        if (userId.length > 0) {
          data['userId'] = userId;
        }
        return data;
      },
      onSave: (dynamic data) {
        String userId = Provider.of<CurrentUserState>(context, listen: false).isLoggedIn ?
          Provider.of<CurrentUserState>(context, listen: false).currentUser.id : '';
        if (userId.length > 0) {
          var neighborhoodState = Provider.of<NeighborhoodState>(context, listen: false);
          neighborhoodState.CheckAndGet(userId);
        }
        String uName = data['neighborhood']['uName'];
        if (widget.onSave != null) {
          widget.onSave!(data['neighborhood']);
        } else {
          context.go('/n/${uName}');
        }
      }
    );

    if (!widget.withScaffold) {
      return content;
    }
    return AppScaffoldComponent(
      listWrapper: true,
      body: content,
    );
  }
}
