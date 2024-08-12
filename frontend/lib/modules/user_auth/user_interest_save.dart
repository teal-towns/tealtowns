import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_scaffold.dart';
import '../../common/form_input/input_fields.dart';
import '../../common/parse_service.dart';
import '../../common/socket_service.dart';
import '../../common/style.dart';
import '../event/event_tags_service.dart';
import './current_user_state.dart';
import './user_interest_class.dart';

class UserInterestSave extends StatefulWidget {
  @override
  _UserInterestSaveState createState() => _UserInterestSaveState();
}

class _UserInterestSaveState extends State<UserInterestSave> {
  EventTagsService _eventTags = EventTagsService();
  InputFields _inputFields = InputFields();
  ParseService _parseService = ParseService();
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();
  Style _style = Style();

  Map<String, dynamic> _formVals = {};
  Map<String, bool> _categoriesVisible = {};
  Map<String, List<String>> _tags = {};
  UserInterestClass _userInterest = UserInterestClass.fromJson({});
  bool _loading = false;
  String _message = '';

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('SaveUserInterest', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1 && data.containsKey('userInterest')) {
        CurrentUserState currentUserState = Provider.of<CurrentUserState>(context, listen: false);
        currentUserState.SetUserInterest(UserInterestClass.fromJson(data['userInterest']));
        context.go('/user-availability-save');
      }
    }));

    CurrentUserState currentUserState = Provider.of<CurrentUserState>(context, listen: false);
    if (!currentUserState.isLoggedIn) {
      Timer(Duration(milliseconds: 200), () {
        context.go('/login');
      });
    } else {
      // _userInterest = currentUserState.userInterest;
      _tags = _eventTags.GetTags();
    }
  }

  @override
  void dispose() {
    _socketService.offRouteIds(_routeIds);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    CurrentUserState currentUserState = context.watch<CurrentUserState>();
    if (!currentUserState.isLoggedIn || _loading) {
      return AppScaffoldComponent(listWrapper: true, body: Column(children: [ LinearProgressIndicator() ]) );
    }
    if (currentUserState.userInterest.id != _userInterest.id) {
      _userInterest = currentUserState.userInterest;
      SetFormVals();
    }
    return AppScaffoldComponent(
      listWrapper: true,
      width: 900,
      body: Container(width: double.infinity, child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _style.Text1('What event types are you interested in?', size: 'xlarge'),
          // _style.SpacingH('medium'),
          ...BuildTagsSelects(),
          _style.SpacingH('xlarge'),
          ElevatedButton(child: Text('Save'), onPressed: () {
            Save();
          },),
          _style.SpacingH('medium'),
          _style.Text1(_message),
        ],
      ))
    );
  }

  List<Widget> BuildTagsSelects() {
    List<Widget> cols = [];
    List<String> subcategories = [];
    List<Map<String, dynamic>> opts = [];
    String subcategoryKey = '';
    for (String category in _tags.keys) {
      subcategoryKey = '${category}_subcategories';
      subcategories = _eventTags.GetSubcategories(category);
      if (!_categoriesVisible.containsKey(category)) {
        _categoriesVisible[category] = false;
      }
      opts = [{ 'value': category, 'label': category }];
      cols.add(_inputFields.inputMultiSelectButtons(opts, _formVals, category, onChanged: (List<String> values) {
        // Category selected; select all subcategories.
        String subcategoryKey1 = '${category}_subcategories';
        List<String> subcategories1 = _eventTags.GetSubcategories(category);
        _categoriesVisible[category] = true;
        if (values.length > 0) {
          _formVals[subcategoryKey1] = subcategories1;
        } else {
          _formVals[subcategoryKey1] = [];
        }
        setState(() { _formVals = _formVals; });
      }));
      if (_categoriesVisible[category]!) {
        opts = [];
        for (String subcategory in subcategories) {
          opts.add({ 'value': subcategory, 'label': subcategory });
        }
        cols.add(_inputFields.inputMultiSelectButtons(opts, _formVals, subcategoryKey,));
      }
    }
    return cols;
  }

  void SetFormVals() {
    List<String> subcategories = [];
    String subcategoryKey = '';
    for (String category in _tags.keys) {
      subcategoryKey = '${category}_subcategories';
      subcategories = _eventTags.GetSubcategories(category);
      if (_userInterest.interests.contains(category)) {
        _formVals[category] = _parseService.parseListString([category]);
        _categoriesVisible[category] = true;
      }
      _formVals[subcategoryKey] = [];
      for (String subcategory in subcategories) {
        if (_userInterest.interests.contains(subcategory)) {
          _formVals[subcategoryKey].add(subcategory);
          _categoriesVisible[category] = true;
        }
      }
      _formVals[subcategoryKey] = _parseService.parseListString(_formVals[subcategoryKey]);
    }
    setState(() { _formVals = _formVals; });
  }

  void Save() {
    // Combine form values into one list of tags.
    List<String> tags = [];
    for (String key in _formVals.keys) {
      if (_formVals.containsKey(key) && _formVals[key].length > 0) {
        tags += _formVals[key];
      }
    }
    if (tags.length < 3) {
      setState(() { _message = 'Please select at least 3 interests.'; });
    } else {
      CurrentUserState currentUserState = Provider.of<CurrentUserState>(context, listen: false);
      var data = {
        'userInterest': {
          'userId': currentUserState.currentUser.id,
          'username': currentUserState.currentUser.username,
          'interests': tags,
          'neighborhoodEventAvailabilityMatches': _userInterest.neighborhoodEventAvailabilityMatches,
        }
      };
      if (_userInterest.id.length > 0) {
        data['userInterest']!['_id'] = _userInterest.id;
      }
      _socketService.emit('SaveUserInterest', data);
      setState(() { _loading = true; });
    }
  }
}
