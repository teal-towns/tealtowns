import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_scaffold.dart';
import '../../common/location_service.dart';
import './neighborhoods.dart';
import '../user_auth/current_user_state.dart';

class NeighborhoodsPage extends StatefulWidget {
  @override
  _NeighborhoodsPageState createState() => _NeighborhoodsPageState();
}

class _NeighborhoodsPageState extends State<NeighborhoodsPage> {
  LocationService _locationService = LocationService();

  List<double> _lngLat = [0, 0];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init();
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget content = LinearProgressIndicator();
    if (_locationService.LocationValid(_lngLat)) {
      content = Neighborhoods(lng: _lngLat[0], lat: _lngLat[1],);
    }
    return AppScaffoldComponent(
      listWrapper: true,
      body: content,
    );
  }

  void _init() async {
    List<double> lngLat = await _locationService.GetLocation(context);
    if(mounted) {
      setState(() {
        _lngLat = lngLat;
      });
    }
  }
}
