import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_scaffold.dart';
import '../../common/buttons.dart';
import '../../common/layout_service.dart';
import '../../common/link_service.dart';
import '../../common/paging.dart';
import '../../common/parse_service.dart';
import '../../common/style.dart';
import '../user_auth/current_user_state.dart';

class MercuryPayOuts extends StatefulWidget {
  @override
  _MercuryPayOutsState createState() => _MercuryPayOutsState();
}

class _MercuryPayOutsState extends State<MercuryPayOuts> {
  Buttons _buttons = Buttons();
  LayoutService _layoutService = LayoutService();
  LinkService _linkService = LinkService();
  ParseService _parseService = ParseService();
  Style _style = Style();

  List<Map<String, dynamic>> _mercuryPayOuts = [];
  Map<String, dynamic> _dataDefault = {};
  Map<String, Map<String, dynamic>> _filterFields = {
    'paidOut': { 'type': 'number', },
  };

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var currentUserState = context.watch<CurrentUserState>();
    return AppScaffoldComponent(
      listWrapper: true,
      body: Column(
        children: [
          _style.Text1('MercuryPayOuts', size: 'large'),
          SizedBox(height: 10,),
          Paging(dataName: 'mercuryPayOuts', routeGet: 'SearchMercuryPayOuts',
            dataDefault: _dataDefault, filterFields: _filterFields,
            onGet: (dynamic mercuryPayOuts) {
              _mercuryPayOuts = [];
              for (var item in mercuryPayOuts) {
                _mercuryPayOuts.add(_parseService.parseMapStringDynamic(item));
              }
              setState(() { _mercuryPayOuts = _mercuryPayOuts; });
            },
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _layoutService.WrapWidth(_mercuryPayOuts.map((item) => OneItem(item, context, currentUserState)).toList(),),
              ]
            ),
          )
        ]
      ) 
    );
  }

  Widget OneItem(Map<String, dynamic> mercuryPayOut, BuildContext context, var currentUserState) {
    String paidOut = mercuryPayOut['paidOut'] == 1 ? 'Paid' : 'Pending';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _style.Text1('${mercuryPayOut['accountKey']} to ${mercuryPayOut['recipientKey']}'),
        _style.SpacingH('medium'),
        _style.Text1('\$${mercuryPayOut['amountUSD']} (${paidOut})'),
        _style.SpacingH('medium'),
        _style.Text1('${mercuryPayOut['forType']} ${mercuryPayOut['forId']}'),
        _style.SpacingH('medium'),
      ]
    );
  }
}