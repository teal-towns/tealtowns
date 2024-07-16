import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_scaffold.dart';
import '../../common/form_input/form_save.dart';
import './icebreaker_class.dart';
import '../user_auth/current_user_state.dart';

class IcebreakerSave extends StatefulWidget {
  String id;
  IcebreakerSave({this.id = '' });

  @override
  _IcebreakerSaveState createState() => _IcebreakerSaveState();
}

class _IcebreakerSaveState extends State<IcebreakerSave> {
  Map<String, Map<String, dynamic>> _formFields = {
    'icebreaker': { 'required': true, },
    'details': { 'required': false, },
  };
  Map<String, dynamic> _formValsDefault = {};
  String _formMode = '';
  List<String> _formStepKeys = [];
  String _title = 'Create an icebreaker';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double fieldWidth = 500;
    Widget content = FormSave(formVals: IcebreakerClass.fromJson(_formValsDefault).toJson(), dataName: 'icebreaker',
      routeGet: 'GetIcebreakerById', routeSave: 'SaveIcebreaker', id: widget.id, fieldWidth: fieldWidth,
      formFields: _formFields, mode: _formMode, stepKeys: _formStepKeys, title: _title,
      parseData: (dynamic data) => IcebreakerClass.fromJson(data).toJson(),
      preSave: (dynamic data) {
        data['icebreaker'] = IcebreakerClass.fromJson(data['icebreaker']).toJson();
        return data;
      },
      onSave: (dynamic data) {
        context.go('/icebreakers');
      }
    );
    return AppScaffoldComponent(
      listWrapper: true,
      width: fieldWidth,
      body: content,
    );
  }
}
