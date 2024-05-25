import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../neighborhood/neighborhoods.dart';
import '../neighborhood/neighborhood_class.dart';
import '../neighborhood/neighborhood_state.dart';
import '../user_auth/current_user_state.dart';
import '../../common/buttons.dart';
import '../../common/style.dart';
import '../../common/socket_service.dart';
import '../../common/paging.dart';

class DisplayNeighborhoods extends StatefulWidget {
  double lng;
  double lat;
  double maxMeters;
  DisplayNeighborhoods({this.lat = 0, this.lng = 0, this.maxMeters = 500,});

  @override
  _DisplayNeighborhoodsState createState() => _DisplayNeighborhoodsState();
}

class _DisplayNeighborhoodsState extends State<DisplayNeighborhoods> {
  Buttons _buttons = Buttons();
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();
  Style _style = Style();
  List<NeighborhoodClass> _neighborhoods = [];
  List<NeighborhoodClass> _filteredNeighborhoods = [];
  Map<String, dynamic> _dataDefault = {
    'stringKeyVals': { 'userId': '', },
  };
  String _message = '';
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('DisplayNeighborhoods', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        _neighborhoods = [];
        for (var i = 0; i < data['neighborhoods'].length; i++) {
          _neighborhoods.add(NeighborhoodClass.fromJson(data['neighborhoods'][i]));
        }
        setState(() { _filteredNeighborhoods = _neighborhoods; });
      } else {
        setState(() { _message = data['message'].length > 0 ? data['message'] : 'Error, please try again.'; });
      }
      setState(() { _loading = false; });
    }));


    DisplayNeighborhoods();
  }

  @override
  void dispose() {
    _socketService.offRouteIds(_routeIds);
    super.dispose();
  }

   void _filterNeighborhoods(String query) { 
    setState(() {
      _searchQuery = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    var neighborhoodsToDisplay = _searchQuery.isEmpty
        ? _neighborhoods
        : _neighborhoods.where((neighborhood) {
            return neighborhood.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                   neighborhood.uName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                   neighborhood.location.coordinates.toString().toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

    return Paging(dataName: 'neighborhoods', routeGet: 'DisplayNeighborhoods', itemsPerPage: 25, dataDefault: _dataDefault,
      onGet: (dynamic neighborhoods) {
        _neighborhoods = [];
        for (var item in neighborhoods) {
          _neighborhoods.add(NeighborhoodClass.fromJson(item));
        }
        setState(() { _filteredNeighborhoods = _neighborhoods; });
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(height: 10,),
        Container(
          padding: EdgeInsets.fromLTRB(10,10,20,10),
          width: 450,
          child: Material(
            child: TextField( // New search bar
                decoration: InputDecoration(
                  labelText: 'Search Neighborhoods',
                  border: OutlineInputBorder(
                    gapPadding: 10
                  ),
                   labelStyle: TextStyle(color: Colors.teal), 
                   filled: true, // Set filled to true
                  fillColor: Colors.grey[100], 
                  contentPadding: EdgeInsets.fromLTRB(10, 10, 20, 10), 
                ),
                onChanged: _filterNeighborhoods, // Call the filter method on change
              ),
          ),
        ),
        Center(child: _style.Text1('Neighborhoods', size: 'large')),
          SizedBox(height: 10,),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
              flex: 1, 
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'ID', 
                    style: TextStyle(fontSize: 16)
                    ),
              )
            ),
             Expanded(
              flex: 1, 
              child: Text(
                'User Name', 
                  style: TextStyle(fontSize: 16)
                  )
            ),
             Expanded(
              flex: 1, 
              child: Text(
                'Title', 
                  style: TextStyle(fontSize: 16)
                  )
            ),
             Expanded(
              flex: 1, 
              child: Text(
                'Location [Long, Lat]', 
                  style: TextStyle(fontSize: 16)
                  )
            ),
            ]
          ),
           SizedBox(height: 10,),
           ...neighborhoodsToDisplay.map((neighborhood) => BuildNeighborhoods(neighborhood, context) ).toList(),
        ]
      ), 
    );
  }


  void DisplayNeighborhoods() {
    String userId = Provider.of<CurrentUserState>(context, listen: false).isLoggedIn ?
      Provider.of<CurrentUserState>(context, listen: false).currentUser.id : '';

    var data = {
      'location': { 'lngLat': [widget.lng, widget.lat], 'maxMeters': widget.maxMeters, },
      'userId': userId,
    };
    _socketService.emit('DisplayNeighborhoods', data);
  }

  Widget BuildNeighborhoods(NeighborhoodClass neighborhood, BuildContext context) {
      return Container(
        child: Row(
          children: [
            Expanded(
              flex: 1, 
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '${neighborhood.id}', 
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600]
                      )
                    ),
              )
            ),
            Expanded(
              flex: 1, 
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '${neighborhood.uName}', 
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600]
                      )
                    ),
              )
            ),
            Expanded(
              flex: 1, 
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '${neighborhood.title}', 
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600]
                      )
                    ),
              )
            ),
            Expanded(
              flex: 1, 
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '${neighborhood.location.coordinates}', 
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600]
                      )
                    ),
              )
            ),
          ]
        )
      );
    }
}