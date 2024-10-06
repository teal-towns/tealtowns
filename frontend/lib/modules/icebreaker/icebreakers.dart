import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_scaffold.dart';
import '../../common/buttons.dart';
import '../../common/layout_service.dart';
import '../../common/link_service.dart';
import '../../common/paging.dart';
import '../../common/style.dart';
import './icebreaker_class.dart';
import '../user_auth/current_user_state.dart';

class Icebreakers extends StatefulWidget {
  bool withScaffold;
  bool showCreate;
  bool withHeader;
  Function(Map<String, dynamic>)? onSelect;
  Icebreakers({this.withScaffold = true, this.showCreate = true, this.withHeader = true, this.onSelect = null});

  @override
  _IcebreakersState createState() => _IcebreakersState();
}

class _IcebreakersState extends State<Icebreakers> {
  Buttons _buttons = Buttons();
  LayoutService _layoutService = LayoutService();
  LinkService _linkService = LinkService();
  Style _style = Style();

  List<IcebreakerClass> _icebreakers = [];
  Map<String, dynamic> _dataDefault = {};
  Map<String, Map<String, dynamic>> _filterFields = {
    'icebreaker': {},
  };

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var currentUserState = context.watch<CurrentUserState>();
    List<Widget> colsCreate = [];
    if (widget.showCreate) {
      colsCreate = [
        Align(
          alignment: Alignment.topRight,
          child: ElevatedButton(
            onPressed: () {
              String url = '/icebreaker-save';
              _linkService.Go(url, context, currentUserState: currentUserState);
            },
            child: Text('Create New Icebreaker'),
          ),
        ),
        SizedBox(height: 10),
      ];
    }
    List<Widget> colsHeader = [];
    if (widget.withHeader) {
      colsHeader = [
        _style.Text1('Icebreakers', size: 'large'),
        SizedBox(height: 10,),
      ];
    }
    Widget content = Column(
      children: [
        ...colsHeader,
        ...colsCreate,
        Paging(dataName: 'icebreakers', routeGet: 'SearchIcebreakers',
          dataDefault: _dataDefault, filterFields: _filterFields,
          onGet: (dynamic icebreakers) {
            _icebreakers = [];
            for (var item in icebreakers) {
              _icebreakers.add(IcebreakerClass.fromJson(item));
            }
            setState(() { _icebreakers = _icebreakers; });
          },
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _layoutService.WrapWidth(_icebreakers.map((icebreaker) => OneIcebreaker(icebreaker, context, currentUserState)).toList(),),
            ]
          ),
        )
      ]
    );
    if (!widget.withScaffold) {
      return content;
    }
    return AppScaffoldComponent(
      listWrapper: true,
      body: content,
    );
  }

  Widget OneIcebreaker(IcebreakerClass icebreaker, BuildContext context, var currentUserState) {
    List<Widget> colsEdit = [];
    if (widget.onSelect == null) {
      colsEdit = [
        ElevatedButton(
          onPressed: () {
            _linkService.Go('/icebreaker-save?id=${icebreaker.id}', context, currentUserState: currentUserState);
          },
          child: Text('Edit'),
        ),
        _style.SpacingH('medium'),
      ];
    } else {
      colsEdit = [
        ElevatedButton(
          onPressed: () {
            widget.onSelect!({ 'icebreaker': icebreaker.toJson() });
          },
          child: Text('Select'),
        ),
        _style.SpacingH('medium'),
      ];
    }
    return Column(
      children: [
        _style.Text1('${icebreaker.icebreaker}'),
        _style.SpacingH('medium'),
        _style.Text1('${icebreaker.details}'),
        _style.SpacingH('medium'),
        ...colsEdit,
      ]
    );
  }
}