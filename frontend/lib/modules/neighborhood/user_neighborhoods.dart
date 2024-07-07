import 'package:flutter/material.dart';

import '../../common/layout_service.dart';
import '../../common/paging.dart';
import '../../common/style.dart';
import './user_neighborhood_class.dart';

class UserNeighborhoods extends StatefulWidget {
  String neighborhoodUName;
  String userId;
  UserNeighborhoods({this.neighborhoodUName = '', this.userId = '', });

  @override
  _UserNeighborhoodsState createState() => _UserNeighborhoodsState();
}

class _UserNeighborhoodsState extends State<UserNeighborhoods> {
  LayoutService _layoutService = LayoutService();
  Style _style = Style();

  List<UserNeighborhoodClass> _userNeighborhoods = [];
  Map<String, dynamic> _dataDefault = {};

  @override
  void initState() {
    super.initState();
    if (widget.neighborhoodUName != '') {
      _dataDefault['neighborhoodUName'] = widget.neighborhoodUName;
      _dataDefault['withUsers'] = 1;
    }
    if (widget.userId != '') {
      _dataDefault['userId'] = widget.userId;
      _dataDefault['withNeighborhoods'] = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
      //   _style.Text1('UserNeighborhoods', size: 'large'),
      //   SizedBox(height: 10,),
        Paging(dataName: 'userNeighborhoods', routeGet: 'SearchUserNeighborhoods',
          dataDefault: _dataDefault,
          onGet: (dynamic items) {
            _userNeighborhoods = [];
            for (var item in items) {
              _userNeighborhoods.add(UserNeighborhoodClass.fromJson(item));
            }
            setState(() { _userNeighborhoods = _userNeighborhoods; });
          },
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _layoutService.WrapWidth(_userNeighborhoods.map((item) => OneItem(item)).toList(),),
            ]
          ),
        )
      ]
    );
  }

  Widget OneItem(UserNeighborhoodClass userNeighborhood) {
    List<Widget> colsNeighborhood = [];
    if (widget.neighborhoodUName == '') {
      colsNeighborhood = [
        _style.Text1(userNeighborhood.neighborhood.uName),
        _style.SpacingH('medium'),
      ];
    }
    List<Widget> colsUser = [];
    if (widget.userId == '') {
      colsUser = [
        _style.Text1(userNeighborhood.user.username),
        _style.SpacingH('medium'),
      ];
    }
    return Column(
      children: [
        ...colsNeighborhood,
        ...colsUser,
      ]
    );
  }
}