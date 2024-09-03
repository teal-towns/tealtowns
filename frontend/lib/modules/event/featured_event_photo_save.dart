import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../app_scaffold.dart';
import '../../common/layout_wrap.dart';
import '../../common/socket_service.dart';
import '../../common/style.dart';
import '../user_auth/current_user_state.dart';
import './event_feedback_class.dart';
import './featured_event_photos.dart';

class FeaturedEventPhotoSave extends StatefulWidget {
  @override
  _FeaturedEventPhotoSaveState createState() => _FeaturedEventPhotoSaveState();
}

class _FeaturedEventPhotoSaveState extends State<FeaturedEventPhotoSave> {
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();
  Style _style = Style();

  List<EventFeedbackClass> _eventFeedbacks = [];
  // Toggle to force re-fresh once add a new featured event.
  bool _showFeaturedEventPhotos = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('GetRecentEventFeedbacks', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        _eventFeedbacks = [];
        for (var i = 0; i < data['eventFeedbacks'].length; i++) {
          _eventFeedbacks.add(EventFeedbackClass.fromJson(data['eventFeedbacks'][i]));
        }
        setState(() { _eventFeedbacks = _eventFeedbacks; _loading = false; });
      }
    }));

    _routeIds.add(_socketService.onRoute('CreateFeaturedEventPhoto', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        setState(() { _showFeaturedEventPhotos = true; });
      }
    }));

    var currentUserState = Provider.of<CurrentUserState>(context, listen: false);
    if (!currentUserState.isLoggedIn || !currentUserState.currentUser.roles.contains('tealtownsTeam')) {
      Timer(Duration(milliseconds: 500), () {
        context.go('/home');
      });
    } else {
      _socketService.emit('GetRecentEventFeedbacks', {});
    }
  }

  @override
  void dispose() {
    _socketService.offRouteIds(_routeIds);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return AppScaffoldComponent(body: Column( children: [ LinearProgressIndicator() ]));
    }
    List<Widget> cols = [];
    if (_showFeaturedEventPhotos) {
      cols += [
        FeaturedEventPhotos(asPage: false, mayRemove: true,),
        _style.SpacingH('xlarge'),
      ];
    }

    if (_eventFeedbacks.length == 0) {
      cols.add(Text('No recent events with photos found.'));
    } else {
      cols += [
        _style.Text1('Select a Photo to Add', size: 'large'),
        _style.SpacingH('medium'),
      ];
      for (var i = 0; i < _eventFeedbacks.length; i++) {
        List<Widget> items = [];
        for (var j = 0; j < _eventFeedbacks[i].imageUrls.length; j++) {
          items.add(InkWell(
            onTap: () {
              setState(() { _showFeaturedEventPhotos = false; });
              _socketService.emit('CreateFeaturedEventPhoto', { 'imageUrl': _eventFeedbacks[i].imageUrls[j],
                'eventId': _eventFeedbacks[i].eventId });
            },
            child: Container(
              child: Column(
                children: [
                  Image.network(_eventFeedbacks[i].imageUrls[j], height: 100, width: double.infinity, fit: BoxFit.cover,),
                ]
              )
            ),
          ));
        }
        cols += [
          LayoutWrap(items: items, width: 100,),
          _style.SpacingH('medium'),
        ];
      }
    }
    return AppScaffoldComponent(
      listWrapper: true,
      body: Column(
        children: [
          ...cols,
        ]
      )
    );
  }
}