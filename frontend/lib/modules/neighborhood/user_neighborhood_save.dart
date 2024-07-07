import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_scaffold.dart';
import '../../common/form_input/form_save.dart';
import '../../common/style.dart';
import './user_neighborhood_class.dart';
import './neighborhood_state.dart';
import '../user_auth/current_user_state.dart';

class UserNeighborhoodSave extends StatefulWidget {
  String id;
  String neighborhoodUName;
  UserNeighborhoodSave({this.id = '', this.neighborhoodUName = '' });

  @override
  _UserNeighborhoodSaveState createState() => _UserNeighborhoodSaveState();
}

class _UserNeighborhoodSaveState extends State<UserNeighborhoodSave> {
  Style _style = Style();

  Map<String, Map<String, dynamic>> _formFields = {
    'motivations': { 'type': 'multiSelectButtons', 'required': true, 'label': 'What possibilities excite you most? Choose multiple.' },
    'vision': { 'required': true, 'minLines': 4, 'label': 'What is your vision for your neighborhood? Imagine you are living in your ideal neighborhood 6-12 months from now - describe it.' },
  };
  Map<String, dynamic> _formValsDefault = {
    'status': 'default',
  };
  List<Map<String, dynamic>> _optsMotivations = [
    {'value': 'socialLife', 'label': 'Have a great social life'},
    {'value': 'bestFriends', 'label': 'Having my best friends living next door'},
    {'value': 'support', 'label': 'Having a support system to fulfill my vision of community'},
    {'value': 'endLoneliness', 'label': 'Ending loneliness in the world'},
    {'value': 'accountability', 'label': 'Having accountability systems'},
    {'value': 'socialMuscles', 'label': 'Growing my social muscles'},
    {'value': 'clearSteps', 'label': 'Having clear easy steps to follow'},
    {'value': 'kids', 'label': 'My kids having a vibrant social life growing up'},
    {'value': 'sharedItems', 'label': 'Sharing daily tasks and assets (car, bike, etc) with people I know and trust'},
    {'value': 'sustainability', 'label': 'Living a Sustainable lifestyle'},
    {'value': 'green', 'label': 'Greening our neighborhood'},
  ];

  @override
  void initState() {
    super.initState();

    _formFields['motivations']!['options'] = _optsMotivations;

    String userId = Provider.of<CurrentUserState>(context, listen: false).isLoggedIn ?
      Provider.of<CurrentUserState>(context, listen: false).currentUser.id : '';
    if (widget.neighborhoodUName.length < 1 || userId.length < 1) {
      Timer(Duration(milliseconds: 200), () {
        context.go('/neighborhoods');
      });
    } else {
      _formValsDefault['neighborhoodUName'] = widget.neighborhoodUName;
      _formValsDefault['userId'] = userId;
    }
  }

  @override
  Widget build(BuildContext context) {
    double fieldWidth = 800;
    Widget content = Column(
      children: [
        _style.Text1('Become a Neighborhood Ambassador for ${widget.neighborhoodUName}', size: 'xlarge'),
        _style.SpacingH('medium'),
        _style.Text1('Ambassadors catalyze action in their neighborhood by gathering their neighbors on a regular basis. Ambassadors empower their neighbors to feel a deep sense of belonging and multiply their impact 100x by growing the neighborhood to 150 people connecting weekly.'),
        _style.SpacingH('medium'),
        _style.Text1('The 2 weekly responsibilities are, which should take about an 1 hour per week, are: 1. invite 10 neighbors to join an event, 2. attend 1 event (and fill out feedback).'),
        _style.SpacingH('medium'),
        _style.Text1('Anyone may become a ambassador, but you will be auto removed if you miss 2 consecutive weeks (do not invite neighbors or attend events).'),
        _style.SpacingH('medium'),
        _style.Text1('If you are sure you are ready and committed to grow your neighborhood, fill out your neighborhood vision and motivations below.'),
        _style.SpacingH('medium'),
        FormSave(formVals: UserNeighborhoodClass.fromJson(_formValsDefault).toJson(), dataName: 'userNeighborhood',
          routeGet: 'GetUserNeighborhoodById', routeSave: 'SaveUserNeighborhood', id: widget.id, fieldWidth: fieldWidth,
          formFields: _formFields,
          parseData: (dynamic data) => UserNeighborhoodClass.fromJson(data).toJson(),
          preSave: (dynamic data) {
            data['userNeighborhood'] = UserNeighborhoodClass.fromJson(data['userNeighborhood']).toJson();
            if (!data['userNeighborhood']['roles'].contains('ambassador')) {
              data['userNeighborhood']['roles'].add('ambassador');
            }
            return data;
          },
          onSave: (dynamic data) {
            String userId = Provider.of<CurrentUserState>(context, listen: false).isLoggedIn ?
              Provider.of<CurrentUserState>(context, listen: false).currentUser.id : '';
            if (userId.length > 0) {
              var neighborhoodState = Provider.of<NeighborhoodState>(context, listen: false);
              neighborhoodState.CheckAndGet(userId);
            }
            context.go('/n/${data['userNeighborhood']['neighborhoodUName']}');
          }
        ),
      ],
    );
    return AppScaffoldComponent(
      listWrapper: true,
      width: fieldWidth,
      body: content,
    );
  }
}
