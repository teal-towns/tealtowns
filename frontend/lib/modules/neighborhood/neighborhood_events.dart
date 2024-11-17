import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app_scaffold.dart';
import '../../common/buttons.dart';
import '../../common/config_service.dart';
import '../../common/parse_service.dart';
import '../../common/socket_service.dart';
import '../../common/style.dart';
import '../event/weekly_events.dart';
import './neighborhood_class.dart';
import '../user_auth/current_user_state.dart';
import '../user_auth/user_availability_save.dart';
import '../user_auth/user_interests.dart';
import '../user_auth/user_interest_save.dart';

class NeighborhoodEvents extends StatefulWidget {
  String uName;
  bool withAppScaffold;
  int withWeeklyEventFilters;
  int withWeeklyEventsCreateButton;
  int inlineMode;
  NeighborhoodEvents({this.uName = '', this.withAppScaffold = true, this.withWeeklyEventFilters = 0,
    this.inlineMode = 0, this.withWeeklyEventsCreateButton = 0, });

  @override
  _NeighborhoodEventsState createState() => _NeighborhoodEventsState();
}

class _NeighborhoodEventsState extends State<NeighborhoodEvents> {
  Buttons _buttons = Buttons();
  ConfigService _configService = ConfigService();
  ParseService _parseService = ParseService();
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();
  Style _style = Style();

  NeighborhoodClass _neighborhood = NeighborhoodClass.fromJson({});
  Map<String, dynamic> _adminContactInfo = {};
  bool _loading = true;
  bool _showUserInterestSave = false;
  bool _showUserAvailabilitySave = false;

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('GetNeighborhoodByUName', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        _neighborhood = NeighborhoodClass.fromJson(data['neighborhood']);
        if (data.containsKey('amdinContactInfo')) {
          _adminContactInfo = _parseService.parseMapStringDynamic(data['amdinContactInfo']);
        }
        setState(() {
          _neighborhood = _neighborhood;
          _adminContactInfo = _adminContactInfo;
          _loading = false;
        });
      } else {
        context.go('/neighborhoods');
      }
    }));

    var data = { 'uName': widget.uName, 'withAdminContactInfo': 1, };
    _socketService.emit('GetNeighborhoodByUName', data);
  }

  @override
  void dispose() {
    _socketService.offRouteIds(_routeIds);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    CurrentUserState currentUserState = context.watch<CurrentUserState>();
    bool withHeader = currentUserState.isLoggedIn;
    bool withFooter = currentUserState.isLoggedIn;
    if (_loading) {
      Widget content = Column( children: [ LinearProgressIndicator(), ] );
      if (widget.withAppScaffold) {
        return AppScaffoldComponent(
          listWrapper: true,
          body: content,
          withHeader: withHeader,
          withFooter: withFooter,
        );
      }
      return content;
    }

    List<Widget> colsAdmin = [];
    if (_adminContactInfo.containsKey('emails') && _adminContactInfo['emails'].length > 0) {
      colsAdmin += [
        _style.Text1('Questions? Contact Neighborhood Admins:', size: 'large'),
        _style.SpacingH('medium'),
        _style.Text1('${_adminContactInfo['emails'].join(', ')}'),
        _style.SpacingH('medium'),
      ];
    }

    Map<String, dynamic> config = _configService.GetConfig();
    List<Widget> cols = [
      _style.SpacingH('large'),
      _style.Text1('Neighborhood Events', size: 'large',),
      _style.SpacingH('medium'),
      // _style.Text1('Weekly Calendar'),
      // _style.SpacingH('medium'),
      WeeklyEvents(lat: _neighborhood.location.coordinates[1], lng: _neighborhood.location.coordinates[0],
        pageWrapper: 0, updateLngLatOnInit: 0, showFilters: widget.withWeeklyEventFilters,
        showCreateButton: widget.withWeeklyEventsCreateButton, viewOnly: 1,),
      _style.SpacingH('medium'),
      // _style.Text1('Pending Events By Interest', size: 'large'),
      // _style.SpacingH('medium'),
    ];
    // if (widget.inlineMode == 0) {
    //   cols += [
    //     _buttons.LinkElevated(context, 'Add Your Interests to Start More Events!', '/interests',
    //       checkLoggedIn: true,),
    //   ];
    // } else {
    //   cols += [
    //     ElevatedButton(child: Text('Add Your Interests to Start More Events!'), onPressed: () {
    //       setState(() { _showUserInterestSave = true; });
    //     },),
    //   ];
    // }
    // if (_showUserInterestSave) {
    //   cols += [
    //     UserInterestSave(withAppScaffold: false, onSave: (Map<String, dynamic> data) {
    //       setState(() { _showUserInterestSave = false; _showUserAvailabilitySave = true; });
    //     }),
    //     _style.SpacingH('xLarge'),
    //   ];
    // }
    // if (_showUserAvailabilitySave) {
    //   cols += [
    //     UserAvailabilitySave(withAppScaffold: false, onSave: (Map<String, dynamic> data) {
    //       setState(() { _showUserAvailabilitySave = false; });
    //     }),
    //     _style.SpacingH('xLarge'),
    //   ];
    // }
    // cols += [
    //   _style.SpacingH('medium'),
    //   UserInterests(neighborhoodUName: _neighborhood.uName,),
    //   _style.SpacingH('medium'),
    // ];
    if (widget.withAppScaffold) {
      // cols += [
      //   _style.Text1('Share with your neighbors', size: 'large'),
      //   _style.SpacingH('medium'),
      //   QrImageView(
      //     data: '${config['SERVER_URL']}/ne/${_neighborhood.uName}',
      //     version: QrVersions.auto,
      //     size: 200.0,
      //   ),
      //   _style.SpacingH('medium'),
      //   Text('${config['SERVER_URL']}/ne/${_neighborhood.uName}'),
      //   _style.SpacingH('large'),
      //   // _buttons.Link(context, 'View Neighborhood', '/n/${_neighborhood.uName}', checkLoggedIn: true,),
      //   // _style.SpacingH('medium'),
      //   // _buttons.Link(context, 'Play Mixer Game', '/mixer-game', checkLoggedIn: true,),
      //   // _style.SpacingH('medium'),
      //   ...colsAdmin,
      // ];
    }
    Widget content = Column(
      children: [
        ...cols,
      ]
    );
    if (widget.withAppScaffold) {
      return AppScaffoldComponent(
        listWrapper: true,
        body: content,
        withHeader: withHeader,
        withFooter: withFooter,
      );
    }
    return content;
  }
}
