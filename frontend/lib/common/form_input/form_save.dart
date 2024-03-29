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
  String mode;
  List<String> stepKeys;

  FormSave({required this.formVals, this.dataName= '', this.routeGet = '', this.routeSave = '', this.preSave = null,
    this.onSave = null, this.parseData = null, this.fieldWidth = 250, this.id = '', this.formFields = null,
    this.mode = '', this.stepKeys = const [] });

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

  int _step = 0;

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
          BuildForm(context),
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

  int GetNextStep() {
    int step = 0;
    for (var keyVal in widget.formFields!.entries) {
      String key = keyVal.key;
      if (step > _step && (widget.stepKeys.length == 0 || widget.stepKeys.contains(key))) {
        return step;
      }
      step += 1;
    }
    return widget.formFields!.entries.length;
  }

  int GetPreviousStep() {
    int step = widget.formFields!.entries.length - 1;
    for (int step = widget.formFields!.entries.length - 1; step >= 0; step -= 1) {
      String key = widget.formFields!.entries.elementAt(step).key;
      if (step < _step && (widget.stepKeys.length == 0 || widget.stepKeys.contains(key))) {
        return step;
      }
    }
    return widget.formFields!.entries.length;
  }

  Widget BuildForm(BuildContext context) {
    if (widget.mode == 'step' && _step < widget.formFields!.length) {
      int step = 0;
      for (var keyVal in widget.formFields!.entries) {
        String key = keyVal.key;
        var value = keyVal.value;
        if (step == _step && (widget.stepKeys.length == 0 || widget.stepKeys.contains(key))) {
          Widget prev = SizedBox.shrink();
          Widget next = SizedBox.shrink();
          if (_step > 0) {
            prev = Padding(
              padding: EdgeInsets.only(top: 15, bottom: 5),
              child: ElevatedButton(
                onPressed: () {
                  _message = '';
                  _loading = false;
                  _step = GetPreviousStep();
                  setState(() { _message = _message; _loading = _loading; _step = _step; });
                },
                child: Text('Previous'),
              ),
            );
          }
          // if (_step < widget.formFields!.length - 1) {
          if (true) {
            next = Padding(
              padding: EdgeInsets.only(top: 15, bottom: 5),
              child: ElevatedButton(
                onPressed: () {
                  _message = '';
                  _loading = false;
                  _step = GetNextStep();
                  setState(() { _message = _message; _loading = _loading; _step = _step; });
                },
                child: Text('Next'),
              ),
            );
          } else {
            next = _buildSubmit(context);
          }
          return Column(
            children: [
              FormField(key, value),
              Row(
                children: [
                  prev,
                  SizedBox(width: 10),
                  next,
                ]
              )
            ]
          );
        }
        step += 1;
      }
    }

    return Column(
      children: [
        FormFields(),
        _buildSubmit(context),
      ]
    );
  }

  Widget FormFields() {
    List<Widget> inputs = [];
    widget.formFields!.forEach((key, value) {
      inputs.add(FormField(key, value));
    });
    return _layoutService.WrapWidth(inputs, width: widget.fieldWidth);
  }

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
    if (value['type'] == 'location') {
      bool nestedCoordinates = value.containsKey('nestedCoordinates') ? value['nestedCoordinates'] : false;
      input = InputLocation(formVals: _formVals, formValsKey: key, label: label, helpText: helpText,
        nestedCoordinates: nestedCoordinates);
    } else if (value['type'] == 'select') {
      input = _inputFields.inputSelect(value['options'], _formVals, key, label: label, helpText: helpText,);
    } else if (value['type'] == 'time') {
      input = _inputFields.inputTime(_formVals, key, label: label, required: required, helpText: helpText,);
    } else if (value['type'] == 'number') {
      double? min = value.containsKey('min') ? value['min'] : null;
      double? max = value.containsKey('max') ? value['max'] : null;
      input = _inputFields.inputNumber(_formVals, key, label: label, required: required, min: min, max: max,
        helpText: helpText,);
    } else {
      int minLines = value.containsKey('minLines') ? value['minLines'] : 1;
      input = _inputFields.inputText(_formVals, key, label: label, required: required, minLines: minLines,
        helpText: helpText,);
    }
    return input;
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