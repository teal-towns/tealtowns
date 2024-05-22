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

class AllNeighborhoods extends StatefulWidget {
  double lng;
  double lat;
  double maxMeters;
  AllNeighborhoods({this.lat = 0, this.lng = 0, this.maxMeters = 500,});

  @override
  _AllNeighborhoodsState createState() => _AllNeighborhoodsState();
}

class _AllNeighborhoodsState extends State<AllNeighborhoods> {
  Buttons _buttons = Buttons();
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();
  Style _style = Style();
  List<NeighborhoodClass> _neighborhoods = [];
  Map<String, dynamic> _dataDefault = {
    'stringKeyVals': { 'userId': '', },
  };
  String _message = '';
  bool _loading = true;

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
        setState(() { _neighborhoods = _neighborhoods; });
      } else {
        setState(() { _message = data['message'].length > 0 ? data['message'] : 'Error, please try again.'; });
      }
      setState(() { _loading = false; });
    }));

    // _routeIds.add(_socketService.onRoute('SaveUserNeighborhood', callback: (String resString) {
    //   var res = jsonDecode(resString);
    //   var data = res['data'];
    //   if (data['valid'] == 1) {
    //     DisplayNeighborhoods();
    //   }
    // }));

    // Provider.of<NeighborhoodState>(context, listen: false).ClearUserNeighborhoods(notify: false);

    DisplayNeighborhoods();
  }

  @override
  void dispose() {
    _socketService.offRouteIds(_routeIds);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Paging(dataName: 'neighborhoods', routeGet: 'DisplayNeighborhoods', itemsPerPage: 25, dataDefault: _dataDefault,
      onGet: (dynamic neighborhoods) {
        _neighborhoods = [];
        for (var item in neighborhoods) {
          _neighborhoods.add(NeighborhoodClass.fromJson(item));
        }
        setState(() { _neighborhoods = _neighborhoods; });
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _style.Text1('Neighborhoods', size: 'large'),
          SizedBox(height: 10,),
          Row(
            children: [
              Expanded(
              flex: 1, 
              child: Text(
                'ID', 
                  style: TextStyle(fontSize: 16)
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
           ..._neighborhoods.map((neighborhood) => BuildNeighborhoods(neighborhood, context) ).toList(),
        ]
      ), 
    );
  }


  void DisplayNeighborhoods() {
    String userId = Provider.of<CurrentUserState>(context, listen: false).isLoggedIn ?
      Provider.of<CurrentUserState>(context, listen: false).currentUser.id : '';
    // var data = {
    //   'location': {},
    //   'userId': userId,
    // };
    var data = {
      'location': { 'lngLat': [widget.lng, widget.lat], 'maxMeters': widget.maxMeters, },
      'userId': userId,
    };
    _socketService.emit('DisplayNeighborhoods', data);
  }

  Widget BuildNeighborhoods(NeighborhoodClass neighborhood, BuildContext context) {
      //Widget forLink = neighborhoods.forLink.length > 0 ?
       // _buttons.LinkInline(context, '{$neighborhood.id}', '{$neighborhood.uName}');
       // Widget forLink = Text('{$neighborhood.id}, {$neighborhood.uName}, {$neighborhood.title}');
      //String createdAt = _dateTime.Format(neighborhoods.createdAt, 'M/d/y');
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