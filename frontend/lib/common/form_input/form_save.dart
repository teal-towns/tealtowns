import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../layout_service.dart';
import '../link_service.dart';
import '../parse_service.dart';
import '../socket_service.dart';
import './input_fields.dart';
import './input_location.dart';
import '../../modules/user_auth/current_user_state.dart';

class FormSave extends StatefulWidget {
  Map<String, dynamic> formVals;
  String dataName;
  String routeGet;
  String routeSave;
  Function(dynamic)? onSave;
  Function(dynamic)? preSave;
  Function(dynamic)? parseData;
  String? id;
  Map<String, Map<String, dynamic>>? formFields;
  double fieldWidth;

  FormSave({required this.formVals, this.dataName= '', this.routeGet = '', this.routeSave = '', this.preSave = null,
    this.onSave = null, this.parseData = null, this.fieldWidth = 250, this.id = '', this.formFields = null});

  @override
  _FormSaveState createState() => _FormSaveState();
}

class _FormSaveState extends State<FormSave> {
  List<String> _routeIds = [];
  LayoutService _layoutService = LayoutService();
  LinkService _linkService = LinkService();
  ParseService _parseService = ParseService();
  SocketService _socketService = SocketService();
  InputFields _inputFields = InputFields();

  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> _formVals = {};
  bool _firstLoadDone = false;
  bool _loading = false;
  String _message = '';

  @override
  void initState() {
    super.initState();

    if (!Provider.of<CurrentUserState>(context, listen: false).isLoggedIn) {
      Timer(Duration(milliseconds: 500), () {
        context.go('/login');
      });
    }

    _formVals = widget.formVals;

    _routeIds.add(_socketService.onRoute(widget.routeGet, callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        if (widget.parseData != null) {
          data[widget.dataName] = widget.parseData!(data[widget.dataName]);
        }
        _formVals = data[widget.dataName];
        setState(() {
          _formVals = _formVals;
        });
      } else {
        setState(() { _message = data['message'].length > 0 ? data['message'] : 'Error, please try again.'; });
      }
      setState(() { _loading = false; });
    }));

    _routeIds.add(_socketService.onRoute(widget.routeSave, callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        if (widget.onSave != null) {
          widget.onSave!(data);
        }
      } else {
        setState(() { _message = data['message'].length > 0 ? data['message'] : 'Error, please try again.'; });
      }
      setState(() { _loading = false; });
    }));
  }

  @override
  void dispose() {
    _socketService.offRouteIds(_routeIds);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // var currentUserState = context.watch<CurrentUserState>();

    CheckFirstLoad();

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormFields(),
          _buildSubmit(context),
          _buildMessage(context),
          SizedBox(height: 50),
        ]
      )
    );
  }

  void CheckFirstLoad() {
    if (!_firstLoadDone) {
      _firstLoadDone = true;

      if (widget.id != null && widget.id!.length > 0) {
        var data = {
          'id': widget.id,
        };
        _socketService.emit(widget.routeGet, data);
      }
    }
  }

  Widget _buildSubmit(BuildContext context) {
    if (_loading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: LinearProgressIndicator(),
      );
    }
    return Padding(
      padding: EdgeInsets.only(top: 15, bottom: 5),
      child: ElevatedButton(
        onPressed: () {
          _message = '';
          _loading = false;
          if (formValid()) {
            _loading = true;
            _formKey.currentState?.save();
            save();
          } else {
            _message = 'Please fill out all fields and try again.';
          }
          setState(() { _message = _message; });
        },
        child: Text('Save'),
      ),
    );
  }

  Widget _buildMessage(BuildContext context) {
    if (_message.length > 0) {
      return Text(_message);
    }
    return SizedBox.shrink();
  }

  Widget FormFields() {
    List<Widget> inputs = [];
    widget.formFields!.forEach((key, value) {
      String label = '';
      if (value.containsKey('label')) {
        label = value['label'];
      } else {
        label = key.replaceAllMapped(RegExp(r'([A-Z])'), (Match match) => ' ${match[0]}');
        label = label[0].toUpperCase() + label.substring(1);
      }
      bool required = value.containsKey('required') ? value['required'] : true;
      if (value['type'] == 'location') {
        bool nestedCoordinates = value.containsKey('nestedCoordinates') ? value['nestedCoordinates'] : false;
        inputs.add(InputLocation(formVals: _formVals, formValsKey: key, label: label,
          nestedCoordinates: nestedCoordinates));
      } else if (value['type'] == 'select') {
        inputs.add(_inputFields.inputSelect(value['options'], _formVals, key, label: label, ));
      } else if (value['type'] == 'time') {
        inputs.add(_inputFields.inputTime(_formVals, key, label: label, required: required));
      } else {
        int minLines = value.containsKey('minLines') ? value['minLines'] : 1;
        inputs.add(_inputFields.inputText(_formVals, key, label: label, required: required, minLines: minLines));
      }
    });
    return _layoutService.WrapWidth(inputs, width: widget.fieldWidth);
  }

  bool formValid() {
    if (!_formKey.currentState!.validate()) {
      return false;
    }
    return true;
  }

  // formKey save is removing leading zero on time?
  void FixFormatting() {
    widget.formFields!.forEach((key, value) {
      if (value['type'] == 'time') {
        // Ensure leading zero for hour for sorting.
        int posColon = _formVals[key].indexOf(':');
        if (posColon == 1) {
          _formVals[key] = "0" + _formVals[key];
        }
      }
    });
  }

  void save() {
    FixFormatting();
    var data = {};
    data[widget.dataName] = _formVals;
    if (widget.preSave != null) {
      data[widget.dataName] = widget.preSave!(data[widget.dataName]);
    }
    saveData(data);
  }

  void saveData(var data) {
    _socketService.emit(widget.routeSave, data);
  }
}