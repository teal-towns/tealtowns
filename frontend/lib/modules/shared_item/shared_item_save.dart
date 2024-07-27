import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_scaffold.dart';
import '../../common/parse_service.dart';
import '../../common/form_input/form_save.dart';
import '../../common/style.dart';
import '../neighborhood/neighborhood_state.dart';
import './shared_item_class.dart';
import './shared_items_search.dart';
import '../user_auth/current_user_state.dart';

class SharedItemSave extends StatefulWidget {
  String id;
  SharedItemSave({this.id = '',});

  @override
  _SharedItemSaveState createState() => _SharedItemSaveState();
}

class _SharedItemSaveState extends State<SharedItemSave> {
  ParseService _parseService = ParseService();
  Style _style = Style();

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
    'title': {},
    'imageUrls': { 'type': 'image', 'multiple': true, 'label': 'Images', },
    'bought': { 'type': 'select', 'label': 'Do you already own this item?', },
    'location': { 'type': 'location', 'nestedCoordinates': true },
    'currentPrice': { 'type': 'number', 'min': 1, 'required': true, 'label': 'Price', },
    'minOwners': { 'type': 'number', 'min': 2, 'required': true },
    'maxOwners': { 'type': 'number', 'min': 2, 'required': true },
    'monthsToPayBack': { 'type': 'number', 'min': 0, 'required': true },
    // 'originalPrice': { 'type': 'number', 'min': 1, 'required': true },
    // 'maintenancePerYear': { 'type': 'number', 'min': 0, 'required': true },
    // 'maxMeters': { 'type': 'select', 'required': true },
    // 'status': { 'type': 'select', 'required': true },
    'description': { 'type': 'text', 'minLines': 4, 'required': false, 'label': 'Description (optional)' },
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
  // String _formMode = 'step';
  // List<String> _formStepKeys = ['imageUrls', 'title', 'location', 'bought', 'currentPrice', 'monthsToPayBack', 'minOwners', 'maxOwners'];
  String _formMode = '';
  List<String> _formStepKeys = [];
  List<String> _formSeeMoreKeys = ['monthsToPayBack', 'minOwners', 'maxOwners', 'description'];
  // List<String> _formSeeMoreKeys = [];

  // TODO - once get amazon api working, switch back to search.
  // String _mode = 'search';
  String _mode = 'save';

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
    List<Widget> cols = [];
    if (_mode == 'search') {
      cols = [
        SharedItemsSearch(onSelected: (data) {
          _formValsDefault['currentPrice'] = data['currentPrice'];
          _formValsDefault['title'] = data['title'];
          _formValsDefault['imageUrls'] = data['imageUrls'];
          setState(() {
            _formValsDefault = _formValsDefault;
            _mode = 'save';
          });
        }),
        _style.SpacingH('medium'),
        TextButton(child: Text('Or Add Manually'), onPressed: () {
          setState(() {
            _mode = 'save';
          });
        }),
      ];
    } else {
      cols = [
        FormSave(formVals: SharedItemClass.fromJson(_formValsDefault).toJson(), dataName: 'sharedItem',
          routeGet: 'getSharedItemById', routeSave: 'saveSharedItem', id: widget.id, fieldWidth: fieldWidth,
          formFields: _formFields, mode: _formMode, stepKeys: _formStepKeys, loggedOutRedirect: '/own',
          seeMoreKeys: _formSeeMoreKeys,
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
        ),
        // TODO - once get amazon api working, switch back to search.
        // _style.SpacingH('medium'),
        // TextButton(child: Text('Back to Search'), onPressed: () {
        //   setState(() {
        //     _mode = 'search';
        //   });
        // }),
      ];
    }
    return AppScaffoldComponent(
      listWrapper: true,
      width: fieldWidth * 2 + 50,
      body: Column(
        children: [
          ...cols,
        ]
      ),
    );
  }
}
