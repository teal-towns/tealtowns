import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app_scaffold.dart';
import './land.dart';

class LandPage extends StatefulWidget {
  final double lat;
  final double lng;
  final String timeframe;
  final int year;
  final String underlay;
  final String tileSize;
  final String dataType;
  final String polygonUName;
  final GoRouterState goRouterState;

  LandPage({ this.lat = -999, this.lng = -999, this.timeframe = '',
    this.year = -999, this.underlay = '', this.tileSize = '', this.dataType = '',
    this.polygonUName = '', required this.goRouterState, });

  @override
  _LandPageState createState() => _LandPageState();
}

class _LandPageState extends State<LandPage> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffoldComponent(
      width: double.infinity,
      body: ListView(
        children: [
          Land(lat: widget.lat, lng: widget.lng, timeframe: widget.timeframe, year: widget.year,
            underlay: widget.underlay, tileSize: widget.tileSize, dataType: widget.dataType,
            polygonUName: widget.polygonUName, goRouterState: widget.goRouterState, ),
        ]
      )
    );
  }
}
