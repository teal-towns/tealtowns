import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import './neighborhood_class.dart';
import './neighborhood_state.dart';
import '../user_auth/current_user_state.dart';
import '../user_auth/user_login_signup.dart';
import '../../common/buttons.dart';
import '../../common/config_service.dart';
import '../../common/form_input/input_location.dart';
import '../../common/layout_service.dart';
import '../../common/link_service.dart';
import '../../common/style.dart';
import '../../common/location_service.dart';
import '../../common/socket_service.dart';

class Neighborhoods extends StatefulWidget {
  double lng;
  double lat;
  double maxMeters;
  bool showSeeAll;
  bool showLink;
  String redirectTo;
  Neighborhoods({this.lat = 0, this.lng = 0, this.maxMeters = 500, this.showSeeAll = true, this.showLink = true,
    this.redirectTo = ''});

  @override
  _NeighborhoodsState createState() => _NeighborhoodsState();
}

class _NeighborhoodsState extends State<Neighborhoods> {
  Buttons _buttons = Buttons();
  ConfigService _config = ConfigService();
  LayoutService _layoutService = LayoutService();
  LinkService _linkService = LinkService();
  LocationService _locationService = LocationService();
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();
  Style _style = Style();

  List<NeighborhoodClass> _neighborhoods = [];
  String _message = '';
  bool _loading = false;
  Map<String, dynamic> _formVals = {
    'inputLocation': {},
  };
  bool _showLoginSignup = false;
  String _selectedNeighborhoodUName = '';

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

    _routeIds.add(_socketService.onRoute('SaveUserNeighborhood', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        SearchNeighborhoods();
        String userId = Provider.of<CurrentUserState>(context, listen: false).isLoggedIn ?
          Provider.of<CurrentUserState>(context, listen: false).currentUser.id : '';
        if (userId.length > 0) {
          var neighborhoodState = Provider.of<NeighborhoodState>(context, listen: false);
          neighborhoodState.CheckAndGet(userId);
        }
        String link = '/n/${data['userNeighborhood']['neighborhoodUName']}';
        if (widget.redirectTo == 'events') {
          link = '/ne/${data['userNeighborhood']['neighborhoodUName']}';
        }
        context.go(link);
      }
    }));

    _formVals['inputLocation']['lngLat'] = [widget.lng, widget.lat];

    // Provider.of<NeighborhoodState>(context, listen: false).ClearUserNeighborhoods(notify: false);

    List<double> lngLat = [widget.lng, widget.lat];
    if (_locationService.LocationValid(lngLat)) {
      SearchNeighborhoods();
    }
  }

  @override
  void dispose() {
    _socketService.offRouteIds(_routeIds);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> colsLoading = [ SizedBox.shrink() ];
    if (_loading) {
      colsLoading = [
        SizedBox(height: 10),
        LinearProgressIndicator(),
        SizedBox(height: 10),
      ];
    }

    Map<String, dynamic> config = _config.GetConfig();
    List<Widget> content = [];
    CurrentUserState currentUserState = Provider.of<CurrentUserState>(context, listen: false);
    if (!_locationService.LocationValid(_formVals['inputLocation']['lngLat'])) {
      content = [ Text('Enter your location to see neighborhoods near you.') ];
    } else if (_showLoginSignup) {
      content = [
        UserLoginSignup(withHeader: false, mode: 'signup', onSave: (Map<String, dynamic> data) {
          SaveUserNeighborhood(_selectedNeighborhoodUName);
        }),
      ];
    } else {
      if (_neighborhoods.length <= 0) {
        content = [ Text('No neighborhoods near this location yet, create one!') ];
      } else {
        List<Widget> elements = [];
        for (var i = 0; i < _neighborhoods.length; i++) {
          List<Widget> colsDefault = [ SizedBox.shrink() ];
          if (!widget.showLink || (currentUserState.isLoggedIn &&
            (!_neighborhoods[i].userNeighborhood.containsKey('status') ||
            _neighborhoods[i].userNeighborhood['status'] != 'default'))) {
            colsDefault = [
              ElevatedButton(
                onPressed: () {
                  if (!currentUserState.isLoggedIn) {
                    setState(() { _showLoginSignup = true; _selectedNeighborhoodUName = _neighborhoods[i].uName; });
                  } else {
                    SaveUserNeighborhood(_neighborhoods[i].uName);
                  }
                },
                child: Text('Join'),
              ),
              SizedBox(height: 10),
            ];
          }
          String linkPart = '/n/${_neighborhoods[i].uName}';
          List<Widget> colsLink = [];
          if (widget.showLink) {
            colsLink = [
              _buttons.LinkInline(context, '${config['SERVER_URL']}${linkPart}', linkPart),
            ];
          }
          elements.add(Column(
            children: [
              Text('${_neighborhoods[i].title} (${_neighborhoods[i].location_DistanceKm} km)'),
              SizedBox(height: 10),
              ...colsDefault,
              ...colsLink,
            ]
          ));
        }
        content = [ _layoutService.WrapWidth(elements, width: 300) ];
      }
    }

    List<Widget> colsSeeAll = [];
    if (widget.showSeeAll) {
      colsSeeAll = [
        _buttons.LinkInline(context, 'See All Neighborhoods', '/neighborhood-insights', checkLoggedIn: true),
        SizedBox(height: 50),
      ];
    }

    List<Widget> colsTop = [];
    if (!_showLoginSignup) {
      colsTop = [
        Align(
            alignment: Alignment.topRight,
            child: _buttons.LinkElevated(context, 'Create New Neighborhood', '/neighborhood-save', checkLoggedIn: true),
            // child: _buttons.LinkElevated(context, 'Create New Neighborhood', '/ambassador', checkLoggedIn: false),
          ),
          _style.SpacingH('medium'),
          _layoutService.WrapWidth([
            InputLocation(formVals: _formVals, formValsKey: 'inputLocation', nestedCoordinates: false,
              onChanged: (Map<String, dynamic> lngLat) {
                SearchNeighborhoods();
            })],
          width: 300),
          ...colsLoading,
          SizedBox(height: 10),
      ];
    }

    return Column(
      children: [
        _style.Text1('Join or create your neighborhood to get started', size: 'large', fontWeight: FontWeight.bold),
        _style.SpacingH('medium'),
        ...colsTop,
        ...content,
        SizedBox(height: 50),
        ...colsSeeAll,
      ]
    );
  }

  void SearchNeighborhoods() {
    setState(() { _loading = true; });
    String userId = Provider.of<CurrentUserState>(context, listen: false).isLoggedIn ?
      Provider.of<CurrentUserState>(context, listen: false).currentUser.id : '';
    var data = {
      'location': { 'lngLat': _formVals['inputLocation']['lngLat'], 'maxMeters': widget.maxMeters, },
      'withLocationDistance': 1,
      'userId': userId,
    };
    _socketService.emit('SearchNeighborhoods', data);
  }

  void SaveUserNeighborhood(String neighborhoodUName) {
    String userId = Provider.of<CurrentUserState>(context, listen: false).isLoggedIn ?
      Provider.of<CurrentUserState>(context, listen: false).currentUser.id : '';
    var data = {
      'userNeighborhood': {
        'neighborhoodUName': neighborhoodUName,
        'userId': userId,
        'status': 'default',
      },
    };
    _socketService.emit('SaveUserNeighborhood', data);
    Provider.of<NeighborhoodState>(context, listen: false).ClearUserNeighborhoods();
  }
}
