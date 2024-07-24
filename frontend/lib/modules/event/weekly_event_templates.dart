import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_scaffold.dart';
import '../../common/colors_service.dart';
import '../../common/config_service.dart';
import '../../common/form_input/input_fields.dart';
import '../../common/form_input/input_location.dart';
import '../../common/layout_service.dart';
import '../../common/socket_service.dart';
import '../../common/style.dart';
import '../user_auth/current_user_state.dart';

import '../event/weekly_event_class.dart';

class WeeklyEventTemplates extends StatefulWidget {
  Function(dynamic)? onSave;
  bool doSave;
  Map<String, dynamic> location;
  Map<String, dynamic> locationAddress;
  String neighborhoodUName;
  int maxEvents;
  String title;
  List<String> selectedKeys;
  WeeklyEventTemplates({ this.location = const {}, this.locationAddress = const {}, this.neighborhoodUName = '',
    this.onSave = null, this.doSave = true, this.maxEvents = 3, this.title = '',
    this.selectedKeys = const ['sandwichSundays', 'burritoWednesdays'] });

  @override
  _WeeklyEventTemplatesState createState() => _WeeklyEventTemplatesState();
}

class _WeeklyEventTemplatesState extends State<WeeklyEventTemplates> {
  ColorsService _colors = ColorsService();
  ConfigService _configService = ConfigService();
  InputFields _inputFields = InputFields();
  LayoutService _layoutService = LayoutService();
  Style _style = Style();
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();

  List<WeeklyEventClass> _weeklyEvents = [];
  bool _saving = false;
  String _message = '';
  Map<String, dynamic> _location = { 'coordinates': [0.0, 0.0] };

  List<Map<String, dynamic>> _formValsEventsList = [];

  @override
  void initState() {
    super.initState();

    SetTemplates();

    if (widget.location.containsKey('coordinates')) {
      _location = widget.location;
    }
    for (int i = 0; i < _formValsEventsList.length; i++) {
      if (widget.selectedKeys.contains(_formValsEventsList[i]['key'])) {
        _formValsEventsList[i]['selected'] = true;
      }
    }

    _routeIds.add(_socketService.onRoute('SaveWeeklyEvents', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        if (widget.onSave != null) {
          widget.onSave!(data);
        }
        setState(() { _saving = false; });
      } else {
        setState(() { _message = data['message'].length > 0 ? data['message'] : 'Error, please try again.'; _saving = false; });
      }
    }));
  }

  @override
  void dispose() {
    _socketService.offRouteIds(_routeIds);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _Events();
  }

  void SetTemplates() {
    _formValsEventsList = [
      {
        'key': 'sandwichSundays',
        'selected': false,
        'formVals': {
          'title': 'Sandwich Sundays',
          'dayOfWeek': 6,
          'startTime': '18:00',
          'endTime': '19:00',
          'imageUrls': ['/assets/assets/images/events/sandwich.jpg'],
          'description': 'Join your neighbors to eat sandwiches and connect. Bring a sandwich, or just yourself!',
        }
      },
      {
        'key': 'meatlessMondays',
        'selected': false,
        'formVals': {
          'title': 'Meatless Mondays',
          'dayOfWeek': 0,
          'startTime': '18:00',
          'endTime': '19:00',
          'imageUrls': ['/assets/assets/images/events/veggie-bowl.jpg'],
          'description': 'Join your neighbors to eat climate friendly vegetarian food and connect. Bring a veggie dish, or just yourself!',
        }
      },
      {
        'key': 'tacoTuesdays',
        'selected': false,
        'formVals': {
          'title': 'Taco Tuesdays',
          'dayOfWeek': 1,
          'startTime': '18:00',
          'endTime': '19:00',
          'imageUrls': ['/assets/assets/images/events/tacos-people.jpg'],
          'description': 'Join your neighbors to eat tacos and connect. Bring some tacos, or just yourself!',
        }
      },
      {
        'key': 'burritoWednesdays',
        'selected': false,
        'formVals': {
          'title': 'Burrito Wednesdays',
          'dayOfWeek': 2,
          'startTime': '18:00',
          'endTime': '19:00',
          'imageUrls': ['/assets/assets/images/events/burritos.jpg'],
          'description': 'Join your neighbors to eat burritos and connect. Bring a burrito, or just yourself!',
        }
      },
      {
        'key': 'happyHourThursdays',
        'selected': false,
        'formVals': {
          'title': 'Happy Hour Thursdays',
          'dayOfWeek': 3,
          'startTime': '18:00',
          'endTime': '19:00',
          'imageUrls': ['/assets/assets/images/events/drinks-people.jpg'],
          'description': 'Join your neighbors to enjoy drinks and connect. Bring a beverage of your choice, or just yourself!',
        }
      },
      {
        'key': 'frozenPizzaFridays',
        'selected': false,
        'formVals': {
          'title': 'Frozen Pizza Fridays',
          'dayOfWeek': 4,
          'startTime': '18:00',
          'endTime': '19:00',
          'imageUrls': ['/assets/assets/images/events/pizza-people.jpg'],
          'description': 'Join your neighbors to enjoy pizza and connect. Bring some pizza, or just yourself!',
        }
      },
      {
        'key': 'brunchSaturdays',
        'selected': false,
        'formVals': {
          'title': 'Brunch Saturdays',
          'dayOfWeek': 5,
          'startTime': '10:00',
          'endTime': '11:00',
          'imageUrls': ['/assets/assets/images/events/waffles-people.jpg'],
          'description': 'Join your neighbors to enjoy brunch and connect. Bring your favorite brunch item, or just yourself!',
        }
      },
    ];
    Map<String, dynamic> config = _configService.GetConfig();
    String ownUrl = '${config['SERVER_URL']}/own';
    _formValsEventsList += [
      {
        'key': 'shareSomethingWalk',
        'selected': false,
        'formVals': {
          'title': 'Share Something Walk',
          'dayOfWeek': 5,
          'startTime': '9:00',
          'endTime': '10:00',
          'imageUrls': ['/assets/assets/images/events/people-walking-in-park.jpg'],
          'description': 'Connect with another person or group to share (co-purchase or co-own) 1 item together, while enjoying a walk in nature. Sharing items is easy and accessible to all. Choose a few items you own or want that you would be open to sharing, and make some friends (and save some cash) with them, rather than letting them sit unused for weeks or months. Each item shared is one less item produced and later thrown away. It is better for both the planet and our pockets.\n\n[Add Your Shared Items Here](${ownUrl})',
          'hostGroupSizeDefault': 0,
        }
      },
    ];
  }

  Widget _Events() {
    List<Map<String, dynamic>> optsDayOfWeek = [
      {'value': 0, 'label': 'Monday'},
      {'value': 1, 'label': 'Tuesday'},
      {'value': 2, 'label': 'Wednesday'},
      {'value': 3, 'label': 'Thursday'},
      {'value': 4, 'label': 'Friday'},
      {'value': 5, 'label': 'Saturday'},
      {'value': 6, 'label': 'Sunday'},
    ];

    int selectedCount = 0;
    String userId = Provider.of<CurrentUserState>(context, listen: false).currentUser.id;
    List<Widget> items = [];
    for (int i = 0; i < _formValsEventsList.length; i++) {
      if (_formValsEventsList[i]['selected']) {
        selectedCount += 1;
      }
      _formValsEventsList[i]['formVals']['location'] = _location;
      _formValsEventsList[i]['formVals']['locationAddress'] = widget.locationAddress;
      _formValsEventsList[i]['formVals']['neighborhoodUName'] = widget.neighborhoodUName;
      if (!_formValsEventsList[i]['formVals'].containsKey('hostGroupSizeDefault')) {
        _formValsEventsList[i]['formVals']['hostGroupSizeDefault'] = 10;
      }
      if (!_formValsEventsList[i]['formVals'].containsKey('priceUSD')) {
        _formValsEventsList[i]['formVals']['priceUSD'] = 0;
      }
      if (!_formValsEventsList[i]['formVals'].containsKey('rsvpDeadlineHours')) {
        _formValsEventsList[i]['formVals']['rsvpDeadlineHours'] = 0;
      }
      _formValsEventsList[i]['formVals']['adminUserIds'] = [ userId ];

      items.add(
        InkWell(
          onTap: () {
            _formValsEventsList[i]['selected'] = !_formValsEventsList[i]['selected'];
            setState(() { _formValsEventsList = _formValsEventsList; });
          },
          child: Container(
            color: _formValsEventsList[i]['selected'] ? _colors.colors['secondary'] : null,
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(_formValsEventsList[i]['formVals']!['imageUrls']![0], height: 100, width: double.infinity, fit: BoxFit.cover),
                // ImageSaveComponent(formVals: _formValsEventsList[i]['formVals'], formValsKey: 'imageUrls', multiple: true,
                //   label: 'Image', imageUploadSimple: true,),
                SizedBox(height: 10),
                // _style.Text1('${_formValsEventsList[i]['formVals']!['title']}', size: 'large'),
                _inputFields.inputText(_formValsEventsList[i]['formVals'], 'title', label: 'Title', required: true),
                SizedBox(height: 10),
                _inputFields.inputSelect(optsDayOfWeek, _formValsEventsList[i]['formVals'], 'dayOfWeek', label: 'Day of Week', required: true,),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(flex: 1,
                      child: _inputFields.inputTime(_formValsEventsList[i]['formVals'], 'startTime', label: 'Start Time', required: true,),
                    ),
                    SizedBox(width: 10),
                    Expanded(flex: 1,
                      child: _inputFields.inputTime(_formValsEventsList[i]['formVals'], 'endTime', label: 'End Time', required: true,),
                    ),
                  ]
                ),
                SizedBox(height: 10),
              ]
            )
          )
        )
      );
    }

    List<Widget> colsSave = [];
    if (selectedCount > widget.maxEvents) {
      colsSave = [
        _style.Text1('Please select up to ${widget.maxEvents} events.'),
      ];
    } else if (selectedCount > 0) {
      String selectedCountStr = selectedCount > 1 ? 'Events' : 'Event';
      colsSave = [
        ElevatedButton(child: Text('Create ${selectedCount} ${selectedCountStr}'),
          onPressed: () {
            var data = {
              'weeklyEvents': [],
            };
            for (int i = 0; i < _formValsEventsList.length; i++) {
              if (_formValsEventsList[i]['selected']) {
                data['weeklyEvents']!.add(WeeklyEventClass.fromJson(_formValsEventsList[i]['formVals'],
                  imageUrlsReplaceLocalhost: false).toJson());
              }
            }
            if (widget.doSave) {
              setState(() { _saving = true; });
              _socketService.emit('SaveWeeklyEvents', data);
            } else {
              widget.onSave!(data);
            }
          },
        ),
      ];
    }
    String title = widget.title.length > 0 ? widget.title : 'Select 1 to 3 events you would like to start with:';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _style.Text1(title, size: 'large', colorKey: 'primary'),
        _style.SpacingH('medium'),
        _layoutService.WrapWidth(items, width: 200,),
        _style.SpacingH('medium'),
        ...colsSave,
      ]
    );
  }
}