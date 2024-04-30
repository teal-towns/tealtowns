import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import './neighborhood_class.dart';
import '../../common/buttons.dart';
import '../../common/config_service.dart';
import '../../common/layout_service.dart';
import '../../common/socket_service.dart';

class Neighborhoods extends StatefulWidget {
  double lng;
  double lat;
  double maxMeters;
  Neighborhoods({this.lat = 0, this.lng = 0, this.maxMeters = 500,});

  @override
  _NeighborhoodsState createState() => _NeighborhoodsState();
}

class _NeighborhoodsState extends State<Neighborhoods> {
  Buttons _buttons = Buttons();
  ConfigService _config = ConfigService();
  LayoutService _layoutService = LayoutService();
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();

  List<NeighborhoodClass> _neighborhoods = [];
  String _message = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('SearchNeighborhoods', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        _neighborhoods = [];
        for (var i = 0; i < data['neighborhoods'].length; i++) {
          _neighborhoods.add(NeighborhoodClass.fromJson(data['neighborhoods'][i]));
        }
        setState(() { _neighborhoods = _neighborhoods; });
      } else {
        setState(() { _message = data['message'].length > 0 ? data['message'] : 'Error, please try again.'; });
      }
      setState(() { _loading = false; });
    }));

    var data = {
      'location': { 'lngLat': [widget.lng, widget.lat], 'maxMeters': widget.maxMeters, },
      'withLocationDistance': 1,
    };
    _socketService.emit('SearchNeighborhoods', data);
  }

  @override
  void dispose() {
    _socketService.offRouteIds(_routeIds);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return LinearProgressIndicator();
    }
    Map<String, dynamic> config = _config.GetConfig();
    Widget content;
    if (_neighborhoods.length <= 0) {
      content = Text('No neighborhoods near this location yet, create one!');
    } else {
      List<Widget> elements = [];
      for (var i = 0; i < _neighborhoods.length; i++) {
        elements.add(Column(
          children: [
            Text('${_neighborhoods[i].title} (${_neighborhoods[i].location_DistanceKm} km)'),
            SizedBox(height: 10),
            _buttons.LinkInline(context, '${config['SERVER_URL']}/n/${_neighborhoods[i].uName}', '/n/${_neighborhoods[i].uName}'),
          ]
        ));
      }
      content = _layoutService.WrapWidth(elements, width: 300);
    }

    return Column(
      children: [
        content,
        SizedBox(height: 10),
        _buttons.LinkElevated(context, 'Create Neighborhood', '/neighborhood-save'),
      ]
    );
  }
}
