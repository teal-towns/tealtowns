import 'dart:convert';
import 'package:flutter/material.dart';

import '../../app_scaffold.dart';
import '../../common/layout_wrap.dart';
import '../../common/socket_service.dart';
import '../../common/style.dart';
import './featured_event_photo_class.dart';

class FeaturedEventPhotos extends StatefulWidget {
  bool asPage;
  bool mayRemove;
  FeaturedEventPhotos({ this.asPage = false, this.mayRemove = false,});

  @override
  _FeaturedEventPhotosState createState() => _FeaturedEventPhotosState();
}

class _FeaturedEventPhotosState extends State<FeaturedEventPhotos> {
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();
  Style _style = Style();

  List<FeaturedEventPhotoClass> _featuredEventPhotos = [];

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('SearchFeaturedEventPhotos', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        _featuredEventPhotos = [];
        for (var i = 0; i < data['featuredEventPhotos'].length; i++) {
          _featuredEventPhotos.add(FeaturedEventPhotoClass.fromJson(data['featuredEventPhotos'][i]));
        }
        setState(() { _featuredEventPhotos = _featuredEventPhotos; });
      }
    }));

    _routeIds.add(_socketService.onRoute('RemoveFeaturedEventPhoto', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        _socketService.emit('SearchFeaturedEventPhotos', {});
      }
    }));

    _socketService.emit('SearchFeaturedEventPhotos', {});
  }

  @override
  void dispose() {
    _socketService.offRouteIds(_routeIds);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> items = [];
    for (var i = 0; i < _featuredEventPhotos.length; i++) {
      List<Widget> cols1 = [
        Image.network(_featuredEventPhotos[i].imageUrl, height: 200, width: double.infinity, fit: BoxFit.cover),
        _style.SpacingH('medium'),
        Text(_featuredEventPhotos[i].title),
      ];
      if (widget.mayRemove) {
        cols1 += [
          _style.SpacingH('medium'),
          TextButton(child: Text('Remove'), onPressed: () {
            _socketService.emit('RemoveFeaturedEventPhoto', { 'id': _featuredEventPhotos[i].id });
          }),
        ];
      }
      items.add(Column(
        children: [
          ...cols1,
        ]
      ));
    }
    Widget content = SizedBox.shrink();
    if (items.length > 0) {
      content = Column(
        children: [
          _style.Text1('Recent Neighborhood Events', size: 'large'),
          _style.SpacingH('medium'),
          LayoutWrap(items: items,),
        ]
      );
    }
    if (widget.asPage) {
      return AppScaffoldComponent(
        listWrapper: true,
        body: content,
      );
    }
    return content;
  }
}