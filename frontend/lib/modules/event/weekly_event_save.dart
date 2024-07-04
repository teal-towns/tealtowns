import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_scaffold.dart';
import '../../common/colors_service.dart';
import '../../common/form_input/form_save.dart';
import '../../common/style.dart';
import './weekly_event_class.dart';
import '../about/welcome_about.dart';
import '../neighborhood/neighborhood_state.dart';
import '../user_auth/current_user_state.dart';

class WeeklyEventSave extends StatefulWidget {
  String id;
  String type;
  WeeklyEventSave({this.id = '', this.type = ''});

  @override
  _WeeklyEventSaveState createState() => _WeeklyEventSaveState();
}

class _WeeklyEventSaveState extends State<WeeklyEventSave> {
  ColorsService _colors = ColorsService();
  Style _style = Style();

  List<Map<String, dynamic>> _optsDayOfWeek = [
    {'value': 0, 'label': 'Monday'},
    {'value': 1, 'label': 'Tuesday'},
    {'value': 2, 'label': 'Wednesday'},
    {'value': 3, 'label': 'Thursday'},
    {'value': 4, 'label': 'Friday'},
    {'value': 5, 'label': 'Saturday'},
    {'value': 6, 'label': 'Sunday'},
  ];
  List<Map<String, dynamic>> _optsNeighborhood = [];
  Map<String, Map<String, dynamic>> _formFields = {
    'location': { 'type': 'location', 'nestedCoordinates': true, 'guessLocation': false },
    'title': {},
    'dayOfWeek': { 'type': 'select' },
    'startTime': { 'type': 'time' },
    'endTime': { 'type': 'time' },
    'hostGroupSizeDefault': { 'type': 'number', 'min': 0, 'required': true },
    'priceUSD': { 'type': 'number', 'min': 0, 'required': true },
    'rsvpDeadlineHours': { 'type': 'number', 'min': 0, 'required': true },
    'neighborhoodUName': { 'type': 'select', 'label': 'Neighborhood', },
    'imageUrls': { 'type': 'image', 'multiple': true, 'label': 'Images', },
    'description': { 'type': 'text', 'minLines': 4, 'required': false, 'label': 'Description (optional)' },
  };
  Map<String, dynamic> _formValsDefault = {
    'hostGroupSizeDefault': 0,
    'priceUSD': 0,
    'rsvpDeadlineHours': 0,
    'type': '',
    'archived': 0,
  };
  String _formMode = '';
  List<String> _formStepKeys = [];
  String _title = 'Save Event';

  @override
  void initState() {
    super.initState();

    var neighborhoodState = Provider.of<NeighborhoodState>(context, listen: false);
    if (neighborhoodState.defaultUserNeighborhood != null) {
      _formValsDefault['neighborhoodUName'] = neighborhoodState.defaultUserNeighborhood!.neighborhood.uName;

      if (neighborhoodState.userNeighborhoods.length > 1) {
        _optsNeighborhood = [];
        for (int i = 0; i < neighborhoodState.userNeighborhoods.length; i++) {
          String uName = neighborhoodState.userNeighborhoods[i].neighborhood.uName;
          _optsNeighborhood.add({'value': uName, 'label': uName, });
        }
        _formFields['neighborhoodUName']!['options'] = _optsNeighborhood;
      } else {
        _formFields.remove('neighborhoodUName');
      }
    } else {
      Timer(Duration(milliseconds: 200), () {
        context.go('/neighborhoods');
      });
    }

    _formValsDefault['type'] = widget.type;
    if (widget.type == 'sharedMeal') {
      _formValsDefault['hostGroupSizeDefault'] = 10;
      _formValsDefault['priceUSD'] = 10;
      _formValsDefault['rsvpDeadlineHours'] = 72;
      _formValsDefault['title'] = 'Shared Meal';
      _formValsDefault['dayOfWeek'] = 6;
      _formValsDefault['startTime'] = '17:00';
      _formValsDefault['endTime'] = '18:30';

      // _formFields['priceUSD']!['min'] = 5;

      _formMode = 'step';

      _formFields['location']!['helpText'] = 'Where will people meet to eat?';
      _formFields['description']!['helpText'] = 'Any special instructions for where people should meet?';
      _formFields['dayOfWeek']!['helpText'] = 'We suggest Sundays at 5pm, but if you would like to do a different day or time, set it here.';
      _formFields['priceUSD']!['helpText'] = 'This single event price will be discounted for subscriptions and hosts will earn their next event free, so with a host group size of 10, a \$10 event will be about \$7 for a yearly subscription and about \$5 event budget.';
      _formStepKeys = ['location', 'description', 'dayOfWeek', 'startTime'];

      _title = 'Create Shared Meal';
    }
    _formFields['dayOfWeek']!['options'] = _optsDayOfWeek;

    // Do not allow changing some fields.
    if (widget.id != null && widget.id!.length > 0) {
      _formFields.remove('hostGroupSizeDefault');
      _formFields.remove('priceUSD');
    }
  }

  @override
  Widget build(BuildContext context) {
    double fieldWidth = 300;
    List<Widget> colsNewEvent = [];
    if (widget.id == null || widget.id!.length <= 0) {
      _title = 'New Event';
      colsNewEvent = [
        _style.Text1('Welcome, TealTowns Ambassador! Ready to bring your neighborhood together? Follow these simple steps to create an engaging event and share it with your neighbors:'),
        _style.SpacingH('medium'),
        Text.rich(TextSpan(
          children: [
            TextSpan(
              text: 'Event Details: ',
              style: TextStyle(color: _colors.colors['primary']),
            ),
            TextSpan(
              text: 'Start by filling out the event fields with all the important details. Include the event name, date, time, location, and a brief description. Make sure to highlight any special activities or themes to get everyone excited!',
            ),
          ],
        )),
        _style.SpacingH('medium'),
        Text.rich(TextSpan(
          children: [
            TextSpan(
              text: 'Generate Your Event: ',
              style: TextStyle(color: _colors.colors['primary']),
            ),
            TextSpan(
              text: 'Once you\'ve completed the event details, customize your event flyer by selecting which details to include. Choose from a map, QR code, neighborhood events link, an intro note, and an end note. Tailor your flyer to suit your audience and make it as informative and engaging as possible.',
            ),
          ],
        )),
        _style.SpacingH('medium'),
        Text.rich(TextSpan(
          children: [
            TextSpan(
              text: 'Share the QR Code: ',
              style: TextStyle(color: _colors.colors['primary']),
            ),
            TextSpan(
              text: 'Print the QR code or save it to your device. You can distribute it to your neighbors by placing it on community boards, sharing it in local social media groups, or handing out flyers.',
            ),
          ],
        )),
        _style.SpacingH('medium'),
        _style.Text1('By following these steps, you\'ll make it easy for your neighbors to stay informed and excited about your event. Thank you for being a part of TealTowns and helping to create a connected, vibrant community!'),
        _style.SpacingH('xlarge'),
        Row(
          children: [
            Image.asset('assets/images/logo.png', width: 30, height: 30),
            SizedBox(width: 10),
            _style.Text1('Event Details', size: 'large', colorKey: 'primary'),
          ]
        ),
        _style.SpacingH('medium'),
      ];
    }
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _style.Text1(_title, size: 'xlarge', colorKey: 'primary'),
        _style.SpacingH('medium'),
        ...colsNewEvent,
        // _style.SpacingH('xlarge'),
        FormSave(formVals: WeeklyEventClass.fromJson(_formValsDefault).toJson(), dataName: 'weeklyEvent',
          routeGet: 'getWeeklyEventById', routeSave: 'saveWeeklyEvent', id: widget.id, fieldWidth: fieldWidth,
          formFields: _formFields, mode: _formMode, stepKeys: _formStepKeys, saveText: 'Save Event',
          parseData: (dynamic data) => WeeklyEventClass.fromJson(data).toJson(),
          preSave: (dynamic data) {
            data = WeeklyEventClass.fromJson(data).toJson();
            if (data['adminUserIds'] == null) {
              data['adminUserIds'] = [];
            }
            if (data['adminUserIds'].length == 0) {
              var currentUser = Provider.of<CurrentUserState>(context, listen: false).currentUser;
              if (currentUser != null) {
                data['adminUserIds'].add(currentUser.id);
              }
            }
            return data;
          }, onSave: (dynamic data) {
            String uName = data['weeklyEvent']['uName'];
            context.go('/we/${uName}');
          },
        )
      ]
    );
    return AppScaffoldComponent(
      listWrapper: true,
      width: 650,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 1, child: content),
                // SizedBox(width: 10),
                // Container(
                //   width: 300,
                //   child: WelcomeAbout(type: 'sidebar'),
                // ),
              ]
            );
          } else {
            return Column(
              children: [
                // WelcomeAbout(),
                // SizedBox(height: 10),
                content,
              ]
            );
          }
        }
      )
    );
  }
}
