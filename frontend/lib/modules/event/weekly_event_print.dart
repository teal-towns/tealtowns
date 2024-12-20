import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:universal_html/html.dart' as html;

import '../../app_scaffold.dart';
import '../../common/colors_service.dart';
import '../../common/config_service.dart';
import '../../common/date_time_service.dart';
import '../../common/form_input/input_fields.dart';
import '../../common/layout_service.dart';
import '../../common/map/map_it.dart';
import '../../common/socket_service.dart';
import '../../common/style.dart';
import '../user_auth/current_user_state.dart';
import './event_class.dart';
import './weekly_event_class.dart';

class WeeklyEventPrint extends StatefulWidget {
  String uName;
  int rows;
  int columns;
  int showImage;
  int showTearOffs;
  WeeklyEventPrint({this.uName = '', this.rows = 1, this.columns = 1, this.showImage = 1, this.showTearOffs = 1});

  @override
  _WeeklyEventPrintState createState() => _WeeklyEventPrintState();
}

class _WeeklyEventPrintState extends State<WeeklyEventPrint> {
  ColorsService _colors = ColorsService();
  ConfigService _configService = ConfigService();
  DateTimeService _dateTime = DateTimeService();
  LayoutService _layoutService = LayoutService();
  Style _style = Style();
  InputFields _inputFields = InputFields();
  ScreenshotController _screenshotController = ScreenshotController();
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();

  WeeklyEventClass _weeklyEvent = WeeklyEventClass.fromJson({});
  EventClass _event = EventClass.fromJson({});
  bool _loading = true;

  Map<String, dynamic>_formVals = {
    'preset': 'largePublicInkSaver',
    'rows': 1,
    'columns': 1,
    'showImage': 1,
    'showMap': 0,
    'showQrCodeEvent': 1,
    'showQrCodeEvents': 0,
    'qrCodeUrl': '',
    'showNeighborhoodEvents': 1,
    'showEventBasics': 1,
    'showEmail': 1,
    'showInterests': 0,
    'userMessage': '',
    'showTearOffs': 1,
    'showMessage': 0,
    'userMessage': '',
    'imageKey': 'event',
    'showIcons': 0,
    'showDescription': 0,
    // 'googleFontFamily': '',
    // 'googleFontFamily': 'Shadows Into Light',
    'googleFontFamily': 'Handlee',
    'fontSize': 'large',
    'widthTotal': 1000,
  };
  List<Map<String, dynamic>> _optsYesNo = [
    {'value': 1, 'label': 'Yes'},
    {'value': 0, 'label': 'No'},
  ];
  List<Map<String, dynamic>> _optsPreset = [
    {'value': 'largePublicInkSaver', 'label': 'Large Public'},
    {'value': 'mediumPublicInkSaver', 'label': 'Medium Public'},
    {'value': 'largePublic', 'label': 'Large Public, Image'},
    {'value': 'mediumPublic', 'label': 'Medium Public, Image'},
    {'value': 'oneNeighbor', 'label': 'One Neighbor'},
    {'value': 'oneNeighborEvents', 'label': 'One Neighbor Events'},
    {'value': 'custom', 'label': 'Custom'},
  ];
  List<Map<String, dynamic>> _optsImage = [
    {'value': 'event', 'label': 'Event'},
    {'value': 'logo', 'label': 'Logo'},
    // {'value': 'i_eco', 'label': 'Sustainable - Leaf', 'icon': Icons.eco},
    // {'value': 'i_compost', 'label': 'Sustainable - Plant', 'icon': Icons.compost},
    {'value': 'image_shared_meal', 'label': 'Shared Meal', 'url': 'assets/images/events/line_art/shared-meal.png'},
    {'value': 'image_standing_nature', 'label': 'Standing in Nature', 'url': 'assets/images/events/line_art/people-standing-nature.jpg'},
    {'value': 'image_walking_park', 'label': 'Walking in Park', 'url': 'assets/images/events/line_art/people-walking-in-park.jpg'},
  ];

  @override
  void initState() {
    super.initState();

    _formVals['rows'] = widget.rows;
    _formVals['columns'] = widget.columns;
    _formVals['showImage'] = widget.showImage;
    _formVals['showTearOffs'] = widget.showTearOffs;
    SetValsFromPreset(_formVals['preset']);

    _routeIds.add(_socketService.onRoute('GetWeeklyEventByIdWithData', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        if (data.containsKey('weeklyEvent') && data['weeklyEvent'].containsKey('_id') &&
          data.containsKey('event') && data['event'].containsKey('_id')) {
          _weeklyEvent = WeeklyEventClass.fromJson(data['weeklyEvent']);
          if (_weeklyEvent.tags.contains('walk')) {
            _formVals['imageKey'] = 'image_walking_park';
          }
          for (String tag in ['food', 'breakfast', 'lunch', 'dinner']) {
            if (_weeklyEvent.tags.contains(tag)) {
              _formVals['imageKey'] = 'image_shared_meal';
              break;
            }
          }
          if (data.containsKey('event')) {
            _event = EventClass.fromJson(data['event']);
          }
          setState(() {
            _weeklyEvent = _weeklyEvent;
            _event = _event;
            _loading = false;
          });
        // } else {
        //   context.go('/weekly-events');
        }
      } else {
        context.go('/weekly-events');
      }
    }));

    var data = {
      'uName': widget.uName,
      'withAdmins': 1,
      'withEvent': 1,
    };
    _socketService.emit('GetWeeklyEventByIdWithData', data);
  }

  void SetValsFromPreset(String val) {
    if (val == 'largePublic' || val == 'largePublicInkSaver') {
      _formVals['rows'] = 1;
      _formVals['columns'] = 1;
      _formVals['showImage'] = 1;
      _formVals['showQrCodeEvent'] = 0;
      _formVals['showQrCodeEvents'] = 0;
      _formVals['qrCodeUrl'] = '';
      _formVals['showEventBasics'] = 1;
      _formVals['showEmail'] = 1;
      _formVals['showNeighborhoodEvents'] = 1;
      _formVals['showTearOffs'] = 1;
      _formVals['showMessage'] = 0;
      _formVals['userMessage'] = '';
      // _formVals['imageKey'] = 'event';
      // if (val == 'largePublicInkSaver') {
      //   _formVals['imageKey'] = 'logo';
      // }
    } else if (val == 'mediumPublic' || val == 'mediumPublicInkSaver') {
      _formVals['rows'] = 2;
      _formVals['columns'] = 2;
      _formVals['showImage'] = 1;
      _formVals['showQrCodeEvent'] = 0;
      _formVals['showQrCodeEvents'] = 0;
      _formVals['qrCodeUrl'] = '';
      _formVals['showEventBasics'] = 1;
      _formVals['showEmail'] = 1;
      _formVals['showNeighborhoodEvents'] = 1;
      _formVals['showTearOffs'] = 0;
      _formVals['showMessage'] = 0;
      _formVals['userMessage'] = '';
      // _formVals['imageKey'] = 'event';
      // if (val == 'mediumPublicInkSaver') {
      //   _formVals['imageKey'] = 'logo';
      // }
    } else if (val == 'oneNeighbor') {
      _formVals['rows'] = 3;
      _formVals['columns'] = 3;
      _formVals['showImage'] = 0;
      _formVals['showQrCodeEvent'] = 0;
      _formVals['showQrCodeEvents'] = 0;
      _formVals['qrCodeUrl'] = '';
      _formVals['showEventBasics'] = 1;
      _formVals['showEmail'] = 1;
      // _formVals['showNeighborhoodEvents'] = 1;
      _formVals['showTearOffs'] = 0;
      _formVals['showMessage'] = 1;
      _formVals['userMessage'] = FormMessage();
    } else if (val == 'oneNeighborEvents') {
      _formVals['rows'] = 7;
      _formVals['columns'] = 3;
      _formVals['showImage'] = 0;
      _formVals['showQrCodeEvent'] = 0;
      _formVals['showQrCodeEvents'] = 0;
      _formVals['qrCodeUrl'] = '';
      _formVals['showEventBasics'] = 0;
      _formVals['showEmail'] = 0;
      _formVals['showNeighborhoodEvents'] = 0;
      _formVals['showTearOffs'] = 0;
      _formVals['showMessage'] = 1;
      _formVals['userMessage'] = FormMessage();
    }
  }

  String FormMessage({ String type = 'phone'}) {
    String userMessage = 'Hey neighbor! I\'m hosting community events for our neighborhood and wanted to invite you!';
    CurrentUserState currentUserState = Provider.of<CurrentUserState>(context, listen: false);
    if (currentUserState.currentUser != null) {
      String firstName = currentUserState.currentUser!.firstName;
      if (type == 'name') {
        userMessage += ' - ${firstName}';
      } else if (type == 'phone') {
        Map<String, dynamic> phoneData = currentUserState.GetPhoneData();
        if (phoneData['number'].length > 0) {
          if (phoneData['type'] == 'phone') {
            userMessage += ' Text ${firstName} @ ${phoneData['number']} to learn more & RSVP';
          } else if (phoneData['type'] == 'whatsapp') {
            userMessage += ' WhatsApp ${firstName} @ ${phoneData['number']} to learn more & RSVP';
          }
        }
      }
    }
    return userMessage;
  }

  @override
  void dispose() {
    _socketService.offRouteIds(_routeIds);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return AppScaffoldComponent(
        listWrapper: true,
        body: Column( children: [ LinearProgressIndicator() ] ),
      );
    }

    double buffer = 5;
    if (_formVals['columns'] == null || _formVals['columns'] < 1) {
      _formVals['columns'] = 1;
    }
    if (_formVals['rows'] == null || _formVals['rows'] < 1) {
      _formVals['rows'] = 1;
    }
    double size = (_formVals['widthTotal'] / _formVals['columns']) - buffer;
    double imageHeight = size / 2;
    List<Widget> rows = [];
    for (int i = 0; i < _formVals['columns']; i++) {
      rows.add(Container(width: size, child: OneEvent(imageHeight)));
    }
    List<Widget> colCopies = [];
    for (int i = 0; i < _formVals['rows']; i++) {
      // colCopies.add(Container(height: size, child: Row(children: rows )));
      colCopies.add(Row(children: rows));
    }

    List<Widget> inputs = [
      _inputFields.inputSelect(_optsPreset, _formVals, 'preset', label: 'Preset', onChanged: (val) {
        _formVals['preset'] = val;
        SetValsFromPreset(val);
        setState(() { _formVals = _formVals; });
      }),
      _inputFields.inputSelect(_optsImage, _formVals, 'imageKey', label: 'Image', onChanged: (val) {
        setState(() { _formVals = _formVals; });
      }),
    ];
    if (_formVals['preset'] == 'custom') {
      inputs += [
        _inputFields.inputNumber(_formVals, 'rows', label: 'Rows', min: 1, max: 10, onChanged: (val) {
          setState(() { _formVals = _formVals; });
        }),
        _inputFields.inputNumber(_formVals, 'columns', label: 'Columns', min: 1, max: 5, onChanged: (val) {
          setState(() { _formVals = _formVals; });
        }),
        _inputFields.inputNumber(_formVals, 'widthTotal', label: 'Width', min: 250, onChanged: (val) {
          setState(() { _formVals = _formVals; });
        }),
        _inputFields.inputSelect(_optsYesNo, _formVals, 'showImage', label: 'Show Image?', onChanged: (val) {
          _formVals['showImage'] = int.parse(val);
          setState(() { _formVals = _formVals; });
        }),
        // _inputFields.inputSelect(_optsYesNo, _formVals, 'showMap', label: 'Show Map?', onChanged: (val) {
        //   _formVals['showMap'] = int.parse(val);
        //   setState(() { _formVals = _formVals; });
        // }),
        _inputFields.inputSelect(_optsYesNo, _formVals, 'showQrCodeEvent', label: 'Event QR Code?', onChanged: (val) {
          _formVals['showQrCodeEvent'] = int.parse(val);
          setState(() { _formVals = _formVals; });
        }),
        _inputFields.inputSelect(_optsYesNo, _formVals, 'showQrCodeEvents', label: 'EventS QR Code?', onChanged: (val) {
          _formVals['showQrCodeEvents'] = int.parse(val);
          setState(() { _formVals = _formVals; });
        }),
        _inputFields.inputText(_formVals, 'qrCodeText', label: 'QR Code URL', onChanged: (val) {
          _formVals['qrCodeUrl'] = val;
          setState(() { _formVals = _formVals; });
        }),
        _inputFields.inputSelect(_optsYesNo, _formVals, 'showNeighborhoodEvents', label: 'Show Neighborhood Events?', onChanged: (val) {
          _formVals['showNeighborhoodEvents'] = int.parse(val);
          setState(() { _formVals = _formVals; });
        }),
        _inputFields.inputSelect(_optsYesNo, _formVals, 'showInterests', label: 'Show Interests?', onChanged: (val) {
          _formVals['showInterests'] = int.parse(val);
          setState(() { _formVals = _formVals; });
        }),
        _inputFields.inputSelect(_optsYesNo, _formVals, 'showTearOffs', label: 'Show Tear Offs?', onChanged: (val) {
          _formVals['showTearOffs'] = int.parse(val);
          setState(() { _formVals = _formVals; });
        }),
        _inputFields.inputSelect(_optsYesNo, _formVals, 'showEventBasics', label: 'Show Event Basics?', onChanged: (val) {
          _formVals['showEventBasics'] = int.parse(val);
          setState(() { _formVals = _formVals; });
        }),
        _inputFields.inputSelect(_optsYesNo, _formVals, 'showEmail', label: 'Show Email?', onChanged: (val) {
          _formVals['showEmail'] = int.parse(val);
          setState(() { _formVals = _formVals; });
        }),
      ];
    }

    List<Widget> colsMessage = [];
    if (_formVals['showMessage'] == 1 || _formVals['preset'] == 'custom') {
      colsMessage += [
        _inputFields.inputText(_formVals, 'userMessage', label: 'Message', onChanged: (val) {
          setState(() { _formVals = _formVals; });
        }),
      ];
    }

    return AppScaffoldComponent(
      listWrapper: true,
      body: Column(
        children: [
          _layoutService.WrapWidth(inputs, width: 200),
          SizedBox(height: 10),
          ...colsMessage,
          // _inputFields.inputText(_formVals, 'outroNote', label: 'Outro Note (optional)', onChanged: (val) {
          //   setState(() { _formVals = _formVals; });
          // }),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              _screenshotController.capture().then((Uint8List? image) {
                SaveImage(image!);
              });
            },
            child: Text('Save Image to Print'),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(flex: 1, child: SizedBox.shrink()),
              Screenshot(controller: _screenshotController,
                child: Column(
                  children: colCopies,
                )
              ),
              Expanded(flex: 1, child: SizedBox.shrink()),
            ],
          ),
          SizedBox(height: 10),
        ]
      )
    );
  }

  Widget OneEvent(double imageHeight) {
    // String startDate = _dateTime.Format(_event.start, 'EEEE HH:mm');
    String day = _dateTime.Format(_event.start, 'EEEE');
    String time = _dateTime.Format(_event.start, 'h:mma');
    String startDate = '${day}s ${time}';
    List<Widget> admins = [];
    if (_weeklyEvent.adminUsers.length > 0 && _formVals['showEmail'] == 1) {
      if (_formVals['columns'] < 4 && _formVals['showIcons'] > 0) {
        admins += [ _style.Text1('${_weeklyEvent.adminUsers[0].email}', left: Icon(Icons.mail),
          googleFontFamily: _formVals['googleFontFamily'], size: _formVals['fontSize']) ];
      } else {
        admins += [ _style.Text1('${_weeklyEvent.adminUsers[0].email}',
          googleFontFamily: _formVals['googleFontFamily'], size: _formVals['fontSize']) ];
      }
      admins += [ SizedBox(height: 10), ];
    }

    List<Widget> colsImage = [];
    if (_formVals['showImage'] == 1) {
      if (_formVals['imageKey'] == 'event') {
        colsImage += [
          _weeklyEvent.imageUrls.length <= 0 ?
            Image.asset('assets/images/shared-meal.jpg', height: imageHeight, width: double.infinity, fit: BoxFit.cover,)
            : Image.network(_weeklyEvent.imageUrls![0], height: imageHeight, width: double.infinity, fit: BoxFit.cover),
          SizedBox(height: 10),
        ];
      } else if (_formVals['imageKey'] == 'logo') {
        colsImage += [
          Image.asset('assets/images/logo.png', width: double.infinity, height: imageHeight,),
          SizedBox(height: 10),
        ];
      } else if (_formVals['imageKey'].startsWith('image_')) {
        for (Map<String, dynamic> opt in _optsImage) {
          if (_formVals['imageKey'] == opt['value']) {
            colsImage += [
              Image.asset(opt['url'], height: imageHeight, width: double.infinity, fit: BoxFit.cover),
              SizedBox(height: 10),
            ];
            break;
          }
        }
      } else if (_formVals['imageKey'].startsWith('i_')) {
        for (Map<String, dynamic> opt in _optsImage) {
          if (_formVals['imageKey'] == opt['value']) {
            colsImage += [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(opt['icon'], size: imageHeight,),
                ]
              ),
              SizedBox(height: 10),
            ];
            break;
          }
        }
      }
    }

    List<Widget> colsUserMessage = [];
    if (_formVals['userMessage'].length > 0) {
      colsUserMessage += [
        _style.Text1(_formVals['userMessage'], googleFontFamily: _formVals['googleFontFamily'],
          size: _formVals['fontSize']),
        SizedBox(height: 10),
      ];
    }

    List<Widget> colsNeighborhoodEvents = [];
    if (_formVals['showNeighborhoodEvents'] == 1) {
      String url = _configService.GetUrl('/ne/${_weeklyEvent.neighborhoodUName}', withScheme: false);
      if (_formVals['showEventBasics'] == 1) {
        colsNeighborhoodEvents += [
          _style.Text1('Can\'t make this time or have different interests?',
            googleFontFamily: _formVals['googleFontFamily'], size: _formVals['fontSize']),
          SizedBox(height: 10),
        ];
      }
      if (_formVals['columns'] < 4 && _formVals['showIcons'] > 0) {
        colsNeighborhoodEvents += [ _style.Text1('${url}', left: Icon(Icons.link),
          googleFontFamily: _formVals['googleFontFamily'], size: _formVals['fontSize']), ];
      } else {
        colsNeighborhoodEvents += [ _style.Text1('${url}',
          googleFontFamily: _formVals['googleFontFamily'], size: _formVals['fontSize']), ];
      }
      colsNeighborhoodEvents.add(SizedBox(height: 10));
    }

    List<Widget> colsInterests = [];
    if (_formVals['showInterests'] == 1) {
      String url = _configService.GetUrl('/interests', withScheme: false);
      if (_formVals['columns'] < 4 && _formVals['showIcons'] > 0) {
        colsInterests += [ _style.Text1('${url}', left: Icon(Icons.link),
          googleFontFamily: _formVals['googleFontFamily'], size: _formVals['fontSize']), ];
      } else {
        colsInterests += [ _style.Text1('${url}',
          googleFontFamily: _formVals['googleFontFamily'], size: _formVals['fontSize']), ];
      }
      colsInterests.add(SizedBox(height: 10));
    }

    List<Widget> colsTearOffs = [];
    if (_formVals['showTearOffs'] == 1) {
      // int size = 23;
      int size = 30;
      int padding = 10;
      int count = ((_formVals['widthTotal'] / _formVals['columns']).round() / (size + padding * 2)).floor() - 1;
      String url1 = _configService.GetUrl('/we/${_weeklyEvent.uName}', withScheme: false);
      List<Widget> rows = [];
      for (int i = 0; i < count; i++) {
        rows += [
          Container(
            decoration: BoxDecoration(
              border: Border(right: BorderSide(width: 1, color: _colors.colors['grey'],)),
            ),
            padding: EdgeInsets.only(left: padding.toDouble(), right: padding.toDouble()),
            child: RotatedBox(
              quarterTurns: 1,
              child: _style.Text1('${url1}', googleFontFamily: _formVals['googleFontFamily'],
                size: _formVals['fontSize']),
            ),
          ),
        ];
      }
      colsTearOffs += [
        Row(
          children: rows,
        ),
      ];
    }

    // List<Widget> colsMap = [];
    // if (_formVals['showMap'] == 1) {
    //   colsMap += [
    //     MapIt(mapHeight: 300,
    //       longitude: _weeklyEvent.location.coordinates[0], latitude: _weeklyEvent.location.coordinates[1],
    //       zoom: 17, markerLngLat: [_weeklyEvent.location.coordinates[0], _weeklyEvent.location.coordinates[1]],
    //     ),
    //     SizedBox(height: 10),
    //   ];
    // }

    String shareUrl = '';
    if (_formVals['showQrCodeEvents'] == 1) {
      shareUrl = _configService.GetUrl('/ne/${_weeklyEvent.neighborhoodUName}', withScheme: false);
    }
    if (_formVals['showQrCodeEvent'] == 1) {
      shareUrl = _configService.GetUrl('/we/${_weeklyEvent.uName}', withScheme: false);
    }
    if (_formVals['qrCodeUrl'] != '') {
      shareUrl = _formVals['qrCodeUrl'];
    }
    List<Widget> colsQrCode = [];
    if (shareUrl.length > 0) {
      colsQrCode += [
        QrImageView(
          data: shareUrl,
          version: QrVersions.auto,
          size: 200.0,
        ),
        SizedBox(height: 10),
      ];
    }
    String shareUrlEvents = _configService.GetUrl('/ne/${_weeklyEvent.neighborhoodUName}', withScheme: false);
    // List<Widget> colsQrCodeEvents = [];
    // if (_formVals['showQrCodeEvents'] == 1 && _formVals['showQrCodeEvent'] != 1) {
    //   colsQrCodeEvents += [
    //     QrImageView(
    //       data: shareUrlEvents,
    //       version: QrVersions.auto,
    //       size: 200.0,
    //     ),
    //     SizedBox(height: 10),
    //   ];
    // }

    Widget? iconCalendar = (_formVals['columns'] < 4 && _formVals['showIcons'] > 0) ? Icon(Icons.calendar_month) : null;
    Widget? iconLink = (_formVals['columns'] < 4 && _formVals['showIcons'] > 0) ? Icon(Icons.link) : null;
    List<Widget> colsDetails = [];
    if (_formVals['showEventBasics'] == 1) {
      colsDetails += [
        _style.Text1('${startDate}', left: iconCalendar,
          googleFontFamily: _formVals['googleFontFamily'], size: _formVals['fontSize']),
        SizedBox(height: 10),
        _style.Text1('${shareUrl}', left: iconLink,
          googleFontFamily: _formVals['googleFontFamily'], size: _formVals['fontSize']),
        SizedBox(height: 10),
      ];
    }
    if (_formVals['showEmail'] == 1) {
      colsDetails += [
        ...admins,
      ];
    }
    colsDetails += [
      ...colsNeighborhoodEvents,
      ...colsInterests,
    ];
    List<Widget> colsDetailsQR = [];
    if (_formVals['columns'] > 2) {
      colsDetailsQR = [
        ...colsDetails,
        ...colsQrCode,
        // ...colsQrCodeEvents,
      ];
    } else {
      if (_formVals['showQrCodeEvent'] > 0 || _formVals['showQrCodeEvents'] > 0) {
        colsDetailsQR = [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 1, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...colsDetails,
                ]
              )),
              Expanded(flex: 1, child: Column(
                children: [
                  ...colsQrCode,
                  // ...colsQrCodeEvents,
                ]
              )),
            ]
          )
        ];
      } else {
        colsDetailsQR = colsDetails;
      }
    }

    List<Widget> colsDescription = [];
    if (_formVals['columns'] < 3 && _formVals['showDescription'] == 1) {
      colsDescription += [
        _style.Text1(_weeklyEvent.description, googleFontFamily: _formVals['googleFontFamily'],
          size: _formVals['fontSize']),
        SizedBox(height: 10),
      ];
    }
    List<Widget> colsTitle = [];
    if (_formVals['showEventBasics'] == 1) {
      colsTitle += [
        _style.Text1('${_weeklyEvent.title}', size: 'xlarge', googleFontFamily: _formVals['googleFontFamily']),
        SizedBox(height: 10),
      ];
    }

    return Container(padding: EdgeInsets.all(10), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...colsUserMessage,
        ...colsImage,
        ...colsTitle,
        ...colsDescription,
        ...colsDetailsQR,
        // ...colsMap,
        ...colsTearOffs,
      ]
    ));
  }

  void SaveImage(Uint8List imageData) {
    // var filename = '${dir.path}/image.png';
    // final file = File(filename);
    // await file.writeAsBytes(imageData);

    final base64data = base64Encode(imageData);
    final a = html.AnchorElement(href: 'data:image/jpeg;base64,$base64data');
    a.download = 'download.jpg';
    a.click();
    a.remove();
  }
}
