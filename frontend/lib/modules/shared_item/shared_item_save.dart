import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_scaffold.dart';
import '../../common/parse_service.dart';
import '../../common/form_input/form_save.dart';
import '../neighborhood/neighborhood_state.dart';
import './shared_item_class.dart';
import '../user_auth/current_user_state.dart';

class SharedItemSave extends StatefulWidget {
  String id;
  SharedItemSave({this.id = '',});

  @override
  _SharedItemSaveState createState() => _SharedItemSaveState();
}

class _SharedItemSaveState extends State<SharedItemSave> {
  ParseService _parseService = ParseService();

  List<Map<String, String>> _optionsStatus = [
    {'value': 'available', 'label': 'Available'},
    {'value': 'owned', 'label': 'Owned'},
  ];
  List<Map<String, String>> _optionsBought = [
    {'value': '1', 'label': 'Already bought (I own this)'},
    {'value': '0', 'label': 'Need to buy'},
  ];
  List<Map<String, dynamic>> _optionsMaxMeters = [
    {'value': 500, 'label': '5 min walk'},
    {'value': 1500, 'label': '15 min walk'},
    {'value': 3500, 'label': '15 min bike'},
    {'value': 8000, 'label': '15 min car'},
  ];

  Map<String, Map<String, dynamic>> _formFields = {
    'imageUrls': { 'type': 'image', 'multiple': true, 'label': 'Images', },
    'title': {},
    'description': { 'type': 'text', 'minLines': 4, 'required': false, 'label': 'Description (optional)' },
    'location': { 'type': 'location', 'nestedCoordinates': true },
    'bought': { 'type': 'select', 'label': 'Do you already own this item?', },
    'minOwners': { 'type': 'number', 'min': 2, 'required': true },
    'maxOwners': { 'type': 'number', 'min': 2, 'required': true },
    'currentPrice': { 'type': 'number', 'min': 1, 'required': true },
    // 'originalPrice': { 'type': 'number', 'min': 1, 'required': true },
    'monthsToPayBack': { 'type': 'number', 'min': 0, 'required': true },
    // 'maintenancePerYear': { 'type': 'number', 'min': 0, 'required': true },
    // 'maxMeters': { 'type': 'select', 'required': true },
    // 'status': { 'type': 'select', 'required': true },
  };
  Map<String, dynamic> _formValsDefault = {
    'bought': 0,
    'currency': 'USD',
    'generation': 0,
    'monthsToPayBack': 12,
    'maintenancePerYear': 0,
    'minOwners': 2,
    'maxOwners': 10,
    'maxMeters': 1500,
    'status': 'available',
  };
  String _formMode = 'step';
  List<String> _formStepKeys = ['imageUrls', 'title', 'location', 'bought', 'currentPrice', 'monthsToPayBack', 'minOwners', 'maxOwners'];

  @override
  void initState() {
    super.initState();

    _formFields['bought']!['options'] = _optionsBought;
    // _formFields['status']!['options'] = _optionsStatus;
    // _formFields['maxMeters']!['options'] = _optionsMaxMeters;

    var neighborhoodState = Provider.of<NeighborhoodState>(context, listen: false);
    if (neighborhoodState.defaultUserNeighborhood != null) {
      _formValsDefault['neighborhoodUName'] = neighborhoodState.defaultUserNeighborhood!.neighborhood.uName;
    } else {
      Timer(Duration(milliseconds: 200), () {
        context.go('/neighborhoods');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double fieldWidth = 300;
    return AppScaffoldComponent(
      listWrapper: true,
      width: fieldWidth,
      body: FormSave(formVals: SharedItemClass.fromJson(_formValsDefault).toJson(), dataName: 'sharedItem',
        routeGet: 'getSharedItemById', routeSave: 'saveSharedItem', id: widget.id, fieldWidth: fieldWidth,
        formFields: _formFields, mode: _formMode, stepKeys: _formStepKeys, loggedOutRedirect: '/own',
        parseData: (dynamic data) => SharedItemClass.fromJson(data).toJson(),
        preSave: (dynamic data) {
          data['sharedItem'] = SharedItemClass.fromJson(data['sharedItem']).toJson();
          data['sharedItem']['currentOwnerUserId'] = Provider.of<CurrentUserState>(context, listen: false).currentUser.id;
          return data;
        }, onSave: (dynamic data) {
          String sharedItemId = data['sharedItem']['_id'];
          String sharedItemOwnerId = '';
          if (data.containsKey('sharedItemOwner') && data['sharedItemOwner'].containsKey('_id')) {
            sharedItemOwnerId = data['sharedItemOwner']['_id'];
          }
          // If new item that is already bought, user is already an owner and there is nothing to invest, so skip owner page.
          if (widget.id.length < 1 && _parseService.toIntNoNull(data['sharedItem']['bought']) > 0) {
            context.go('/own');
          } else {
            context.go('/shared-item-owner-save?sharedItemId=${sharedItemId}&id=${sharedItemOwnerId}');
          }
        }
      )
    );
  }
}
