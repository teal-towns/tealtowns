import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app_scaffold.dart';
import '../../common/colors_service.dart';
import '../../common/config_service.dart';
import '../../common/form_input/input_fields.dart';
import '../../common/layout_service.dart';
import '../../common/link_service.dart';
import '../../common/parse_service.dart';
import '../../common/socket_service.dart';
import '../../common/style.dart';
import '../event/event_tags_service.dart';
import './current_user_state.dart';
import './user_interest_class.dart';

class UserInterestSave extends StatefulWidget {
  bool withAppScaffold;
  Function(Map<String, dynamic>)? onSave;
  UserInterestSave({this.withAppScaffold = true, this.onSave = null});

  @override
  _UserInterestSaveState createState() => _UserInterestSaveState();
}

class _UserInterestSaveState extends State<UserInterestSave> {
  ColorsService _colors = ColorsService();
  ConfigService _configService = ConfigService();
  EventTagsService _eventTags = EventTagsService();
  InputFields _inputFields = InputFields();
  LayoutService _layoutService = LayoutService();
  LinkService _linkService = LinkService();
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
  Map<String, Map<String, dynamic>> _eventInterests = {};
  List<String> _eventInterestsSelected = [];
  Map<String, dynamic> _eventInterestsHostCheck = {};
  List<String> _hostInterests = [];
  List<String> _hostInterestsPending = [];

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('SaveUserInterest', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1 && data.containsKey('userInterest')) {
        CurrentUserState currentUserState = Provider.of<CurrentUserState>(context, listen: false);
        currentUserState.SetUserInterest(UserInterestClass.fromJson(data['userInterest']));
        if (widget.onSave != null) {
          widget.onSave!({ 'userInterest': data['userInterest'] });
        } else {
          context.go('/user-availability-save');
        }
      }
    }));

    _routeIds.add(_socketService.onRoute('GetEventInterests', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1 && data.containsKey('eventInterests')) {
        _eventInterests = {};
        for (var key in data['eventInterests'].keys) {
          _eventInterests[key] = _parseService.parseMapStringDynamic(data['eventInterests'][key]);
        }
        setState(() { _eventInterests = _eventInterests; });
      }
    }));

    CurrentUserState currentUserState = Provider.of<CurrentUserState>(context, listen: false);
    if (!currentUserState.isLoggedIn) {
      Timer(Duration(milliseconds: 200), () {
        _linkService.Go('', context, currentUserState: currentUserState);
      });
    } else {
      // _userInterest = currentUserState.userInterest;
      _tags = _eventTags.GetTags();
      _socketService.emit('GetEventInterests', {});
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
      Widget content = Column( children: [ LinearProgressIndicator(), ] );
      if (widget.withAppScaffold) {
        return AppScaffoldComponent(listWrapper: true, body: content);
      }
      return content;
    }
    if (currentUserState.userInterest.id != _userInterest.id) {
      _userInterest = currentUserState.userInterest;
      SetFormVals();
    }
    Map<String, dynamic> config = _configService.GetConfig();

    List<Widget> cols = [];
    if (_eventInterestsHostCheck.keys.length > 0) {
      cols += [
        BuildHostsCheck(),
      ];
    } else {
      cols += [
        _style.Text1('What event types are you interested in?', size: 'xlarge'),
        // _style.SpacingH('medium'),
        ...BuildTagsSelects(),
        _style.SpacingH('large'),
        _style.Text1('What events are you interested in?', size: 'xlarge'),
        _style.SpacingH('medium'),
        ...BuildEventInterestsSelects(),
        _style.SpacingH('xlarge'),
      ];
      if (widget.withAppScaffold) {
        cols += [
          _style.Text1('Share with your neighbors and friends to get your local events started!', size: 'xlarge'),
          _style.SpacingH('medium'),
          _style.Text1('Text or email this link to friends, share the QR code with your neighbors, post on social media, and more!'),
          _style.SpacingH('medium'),
          _style.Text1('${config['SERVER_URL']}/interests'),
          _style.SpacingH('medium'),
          QrImageView(
            data: '${config['SERVER_URL']}/interests',
            version: QrVersions.auto,
            size: 200.0,
          ),
          _style.SpacingH('xlarge'),
        ];
      }
      cols += [
        ElevatedButton(child: Text('Save'), onPressed: () {
          CheckHostThenSave();
        },),
        _style.SpacingH('medium'),
        _style.Text1(_message),
        _style.SpacingH('medium'),
      ];
    }
    Widget content = Container(width: double.infinity, child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...cols,
      ],
    ));
    if (widget.withAppScaffold) {
      return AppScaffoldComponent(
        listWrapper: true,
        width: 900,
        body: content,
      );
    }
    return content;
  }

  Widget BuildHostsCheck() {
    List<Widget> cols = [];
    for (String key in _eventInterestsHostCheck.keys) {
      String keyTitle = key.replaceAll('event_', '');
      bool selected = false;
      cols += [
        _style.Text1('Would you like to be a host for ${keyTitle}?', size: 'large'),
        _style.SpacingH('medium'),
      ];
      Map<String, dynamic> info = _eventInterestsHostCheck[key];
      if (info.containsKey('hostRequirements')) {
        if (_hostInterestsPending.contains(key)) {
          selected = true;
        }
        for (int i = 0; i < info['hostRequirements'].length; i++) {
          cols += [
            _style.Text1('${info['hostRequirements'][i]}'),
            _style.SpacingH('medium'),
          ];
        }
      }
      if (info.containsKey('hostDetails')) {
        if (_hostInterests.contains(key)) {
          selected = true;
        }
        for (int i = 0; i < info['hostDetails'].length; i++) {
          cols += [
            _style.Text1('${info['hostDetails'][i]}'),
            _style.SpacingH('medium'),
          ];
        }
      }
      cols += [
        FilledButton(
          child: Text('Yes I\'ll host for ${keyTitle}'),
          onPressed: () {
            if (selected) {
              if (_hostInterestsPending.contains(key)) {
                _hostInterestsPending.remove(key);
              } else {
                _hostInterests.remove(key);
              }
            } else {
              if (info.containsKey('hostRequirements')) {
                _hostInterestsPending.add(key);
              } else {
                _hostInterests.add(key);
              }
            }
            setState(() { _hostInterests = _hostInterests; _hostInterestsPending = _hostInterestsPending; });
          },
          style: FilledButton.styleFrom(
            backgroundColor: selected ? _colors.colors['secondary'] : _colors.colors['greyLight'],
            foregroundColor: _colors.colors['brown'],
          ),
        ),
        _style.SpacingH('large'),
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...cols,
        _style.SpacingH('large'),
        ElevatedButton(child: Text('Save'), onPressed: () {
          Save();
        },),
      ]
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

  List<Widget> BuildEventInterestsSelects() {
    double imageHeight = 150;
    List<Widget> items = [];
    for (String interest in _eventInterests.keys) {
      bool selected = _eventInterestsSelected.contains(interest);
      String title = _eventInterests[interest]!['title'];
      if (_eventInterests[interest]!['priceUSD'] > 0) {
        title += ', \$${_eventInterests[interest]!['priceUSD']}';
      }
      items.add(
        InkWell(
          onTap: () {
            if (selected) {
              _eventInterestsSelected.remove(interest);
            } else if (!_eventInterestsSelected.contains(interest)) {
              _eventInterestsSelected.add(interest);
            }
            setState(() { _eventInterestsSelected = _eventInterestsSelected; });
          },
          child: Container(
            color: selected ? _colors.colors['secondary'] : null,
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _eventInterests[interest]!['imageUrls'].length <= 0 ?
                  Image.asset('assets/images/shared-meal.jpg', height: imageHeight, width: double.infinity, fit: BoxFit.cover,)
                    : Image.network(_eventInterests[interest]!['imageUrls']![0], height: imageHeight, width: double.infinity, fit: BoxFit.cover),
                _style.SpacingH('medium'),
                _style.Text1('${title}'),
                _style.SpacingH('medium'),
                _style.Text1('${_eventInterests[interest]!['description']}'),
                _style.SpacingH('medium'),
              ]
            ),
          ),
        ),
      );
    }
    List<Widget> cols = [
      _layoutService.WrapWidth(items,),
    ];
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
        if (_userInterest.interests.contains(subcategory) && !_formVals[subcategoryKey].contains(subcategory)) {
          _formVals[subcategoryKey].add(subcategory);
          _categoriesVisible[category] = true;
        }
      }
      _formVals[subcategoryKey] = _parseService.parseListString(_formVals[subcategoryKey]);
      // event interests too
      for (String interest in _userInterest.interests) {
        if (interest.contains("event_") && !_eventInterestsSelected.contains(interest)) {
          _eventInterestsSelected.add(interest);
        }
      }
      _hostInterests = _userInterest.hostInterests;
      _hostInterestsPending = _userInterest.hostInterestsPending;
    }
    setState(() { _formVals = _formVals; _eventInterestsSelected = _eventInterestsSelected;
      _hostInterests = _hostInterests; _hostInterestsPending = _hostInterestsPending;
    });
  }

  void CheckHostThenSave() {
    // Combine form values into one list of tags.
    List<String> tags = [];
    for (String key in _formVals.keys) {
      if (_formVals.containsKey(key) && _formVals[key].length > 0) {
        tags += _formVals[key];
      }
    }
    if (tags.length < 3) {
      setState(() { _message = 'Please select at least 3 interests.'; });
    } else if (_eventInterestsSelected.length < 1) {
      setState(() { _message = 'Please select at least 1 event interest.'; });
    } else {
      _eventInterestsHostCheck = {};
      for (int i = 0; i < _eventInterestsSelected.length; i++) {
        String interest = _eventInterestsSelected[i];
        if (_eventInterests.containsKey(interest) && _eventInterests[interest] != null &&
          (_eventInterests[interest]!.containsKey('hostDetails') ||
          _eventInterests[interest]!.containsKey('hostRequirements'))) {
          _eventInterestsHostCheck[interest] = _eventInterests[interest];
        }
      }
      if (_eventInterestsHostCheck.keys.length > 0) {
        setState(() { _eventInterestsHostCheck = _eventInterestsHostCheck; });
      } else {
        Save();
      }
    }
  }

  void Save() {
    // Combine form values into one list of tags.
    List<String> tags = [];
    for (String key in _formVals.keys) {
      if (_formVals.containsKey(key) && _formVals[key].length > 0) {
        tags += _formVals[key];
      }
    }
    // Add in event interests.
    if (_eventInterestsSelected.length > 0) {
      tags += _eventInterestsSelected;
    }
    // Remove any host interests if not in interests.
    for (int i = _hostInterests.length - 1; i >= 0; i--) {
      if (!tags.contains(_hostInterests[i])) {
        _hostInterests.removeAt(i);
      }
    }
    for (int i = _hostInterestsPending.length - 1; i >= 0; i--) {
      if (!tags.contains(_hostInterestsPending[i])) {
        _hostInterestsPending.removeAt(i);
      }
    }
    CurrentUserState currentUserState = Provider.of<CurrentUserState>(context, listen: false);
    var data = {
      'userInterest': {
        'userId': currentUserState.currentUser.id,
        'username': currentUserState.currentUser.username,
        'interests': tags,
        'hostInterests': _hostInterests,
        'hostInterestsPending': _hostInterestsPending,
      }
    };
    if (_userInterest.id.length > 0) {
      data['userInterest']!['_id'] = _userInterest.id;
    }
    _socketService.emit('SaveUserInterest', data);
    setState(() { _loading = true; });
  }
}
