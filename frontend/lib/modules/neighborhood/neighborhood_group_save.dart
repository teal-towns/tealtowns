import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_scaffold.dart';
import '../../common/form_input/input_fields.dart';
import '../../common/socket_service.dart';
import '../../common/style.dart';
import '../user_auth/current_user_state.dart';
import './neighborhood_class.dart';
import './neighborhood_group_class.dart';

class NeighborhoodGroupSave extends StatefulWidget {
  String uName;
  NeighborhoodGroupSave({this.uName = '', });

  @override
  _NeighborhoodGroupSaveState createState() => _NeighborhoodGroupSaveState();
}

class _NeighborhoodGroupSaveState extends State<NeighborhoodGroupSave> {
  InputFields _inputFields = InputFields();
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();
  Style _style = Style();

  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> _formVals = {};
  bool _loading = false;
  NeighborhoodGroupClass _neighborhoodGroup = NeighborhoodGroupClass.fromJson({});

  Map<String, dynamic> _formValsNeighborhoodGroup = {};
  Map<String, dynamic> _filters = {};
  List<NeighborhoodClass> _neighborhoods = [];
  List<Map<String, dynamic>> _optsNeighborhoodUNames = [];
  List<String> _neighborhoodUNamesOriginal = [];

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('GetNeighborhoodGroupByUName', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        SetNeighborhoodGroup(data);
      }
    }));

    _routeIds.add(_socketService.onRoute('SearchNeighborhoods', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        _neighborhoods = [];
        for (var i = 0; i < data['neighborhoods'].length; i++) {
          if (!_neighborhoodGroup.neighborhoodUNames.contains(data['neighborhoods'][i]['uName'])) {
            _neighborhoods.add(NeighborhoodClass.fromJson(data['neighborhoods'][i]));
          }
        }
        setState(() { _neighborhoods = _neighborhoods; });
      }
    }));

    _routeIds.add(_socketService.onRoute('RemoveNeighborhoodsFromNeighborhoodGroup', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        SetNeighborhoodGroup(data);
      }
    }));

    _routeIds.add(_socketService.onRoute('AddNeighborhoodToNeighborhoodGroup', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        SetNeighborhoodGroup(data);
      }
    }));

    _routeIds.add(_socketService.onRoute('SaveNeighborhoodGroup', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        context.go('/neighborhood-group-save?uName=${data['neighborhoodGroup']['uName']}');
      }
    }));

    if (widget.uName.length > 0) {
      _socketService.emit('GetNeighborhoodGroupByUName', {'uName': widget.uName});
    }
  }

  void SetNeighborhoodGroup(var data) {
    _optsNeighborhoodUNames = [];
    _neighborhoodUNamesOriginal = [];
    for (int i = 0; i < data['neighborhoodGroup']['neighborhoodUNames'].length; i++) {
      _optsNeighborhoodUNames.add({'label': data['neighborhoodGroup']['neighborhoodUNames'][i],
        'value': data['neighborhoodGroup']['neighborhoodUNames'][i]});
      _neighborhoodUNamesOriginal.add(data['neighborhoodGroup']['neighborhoodUNames'][i]);
    }
    _neighborhoodGroup = NeighborhoodGroupClass.fromJson(data['neighborhoodGroup']);
    setState(() {
      _neighborhoodGroup = _neighborhoodGroup;
      _formValsNeighborhoodGroup = _neighborhoodGroup.toJson();
      _optsNeighborhoodUNames = _optsNeighborhoodUNames;
      _neighborhoodUNamesOriginal = _neighborhoodUNamesOriginal;
    });
  }

  @override
  void dispose() {
    _socketService.offRouteIds(_routeIds);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_neighborhoodGroup.uName.length > 0) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _style.Text1('Neighborhood Group: ${_neighborhoodGroup.uName}', size: 'xlarge'),
          _style.Spacing(height: 'medium'),
          _inputFields.inputText(_filters, 'title', label: 'Search Neighborhoods', onChange: (String val) {
            _socketService.emit('SearchNeighborhoods', _filters);
          }),
          _style.Spacing(height: 'medium'),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _neighborhoods.map((neighborhood) => TextButton(child: Text(neighborhood.uName), onPressed: () {
              var data = {'uName': _neighborhoodGroup.uName, 'neighborhoodUName': neighborhood.uName,};
              _socketService.emit('AddNeighborhoodToNeighborhoodGroup', data);
            })).toList(),
          ),
          _style.Spacing(height: 'medium'),
          _inputFields.inputMultiSelectButtons(_optsNeighborhoodUNames, _formValsNeighborhoodGroup, 'neighborhoodUNames',
            label: 'Neighborhood UNames'),
          _style.Spacing(height: 'medium'),
          ElevatedButton(child: Text('Save'),
            onPressed: () {
              UpdateUNames();
            },
          ),
        ],
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _style.Text1('Neighborhood Group Save', size: 'xlarge'),
          Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _inputFields.inputText(_formVals, 'uName', label: 'uName', minLen: 2,),
                SizedBox(height: 10),
                ElevatedButton(child: Text('Save'),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState?.save();
                      var data = {'neighborhoodGroup': _formVals};
                      _socketService.emit('SaveNeighborhoodGroup', data);
                    }
                  },
                ),
              ],
            ),
          )
        ]
      );
    }
    return AppScaffoldComponent(
      listWrapper: true,
      body: content,
    );
  }

  void UpdateUNames() {
    List<String> removedUNames = [];
    for (int j = 0; j < _neighborhoodUNamesOriginal.length; j++) {
      String uName = _neighborhoodUNamesOriginal[j];
      if (!_formValsNeighborhoodGroup['neighborhoodUNames'].contains(uName)) {
        removedUNames.add(uName);
      }
    }
    if (removedUNames.length > 0) {
      var data = { 'uName': widget.uName, 'neighborhoodUNames': removedUNames };
      _socketService.emit('RemoveNeighborhoodsFromNeighborhoodGroup', data);
    }
  }
}
