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
  int withTearOffs;
  WeeklyEventPrint({this.uName = '', this.rows = 1, this.columns = 1, this.showImage = 1, this.withTearOffs = 1});

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
  double _widthTotal = 1000;

  Map<String, dynamic>_formVals = {
    'preset': 'largePublic',
    'rows': 1,
    'columns': 1,
    'showImage': 1,
    'showMap': 0,
    'showQrCode': 1,
    'showNeighborhoodEvents': 1,
    'showInterests': 0,
    'userMessage': '',
    'withTearOffs': 1,
    'showMessage': 0,
    'userMessage': '', 
  };
  List<Map<String, dynamic>> _optsYesNo = [
    {'value': 1, 'label': 'Yes'},
    {'value': 0, 'label': 'No'},
  ];
  List<Map<String, dynamic>> _optsPreset = [
    {'value': 'largePublic', 'label': 'Large Public'},
    {'value': 'mediumPublic', 'label': 'Medium Public'},
    {'value': 'singleNeighbor', 'label': 'Single Neighbor'},
    {'value': 'custom', 'label': 'Custom'},
  ];

  @override
  void initState() {
    super.initState();

    _formVals['rows'] = widget.rows;
    _formVals['columns'] = widget.columns;
    _formVals['showImage'] = widget.showImage;
    _formVals['withTearOffs'] = widget.withTearOffs;

    _routeIds.add(_socketService.onRoute('GetWeeklyEventByIdWithData', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        if (data.containsKey('weeklyEvent') && data['weeklyEvent'].containsKey('_id') &&
          data.containsKey('event') && data['event'].containsKey('_id')) {
          _weeklyEvent = WeeklyEventClass.fromJson(data['weeklyEvent']);
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
    double size = (_widthTotal / _formVals['columns']) - buffer;
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
        if (val == 'largePublic') {
          _formVals['rows'] = 1;
          _formVals['columns'] = 1;
          _formVals['showImage'] = 1;
          _formVals['showQrCode'] = 1;
          _formVals['showNeighborhoodEvents'] = 1;
          _formVals['withTearOffs'] = 1;
          _formVals['showMessage'] = 0;
          _formVals['userMessage'] = '';
        } else if (val == 'mediumPublic') {
          _formVals['rows'] = 2;
          _formVals['columns'] = 2;
          _formVals['showImage'] = 1;
          _formVals['showQrCode'] = 1;
          _formVals['showNeighborhoodEvents'] = 1;
          _formVals['withTearOffs'] = 0;
          _formVals['showMessage'] = 0;
          _formVals['userMessage'] = '';
        } else if (val == 'singleNeighbor') {
          _formVals['rows'] = 2;
          _formVals['columns'] = 4;
          _formVals['showImage'] = 0;
          _formVals['showQrCode'] = 0;
          // _formVals['showNeighborhoodEvents'] = 1;
          _formVals['withTearOffs'] = 0;
          _formVals['showMessage'] = 1;
          CurrentUserState currentUserState = Provider.of<CurrentUserState>(context, listen: false);
          if (currentUserState.currentUser != null) {
            String firstName = currentUserState.currentUser!.firstName;
            _formVals['userMessage'] = 'Hey neighbor! I\'m hosting community events for our neighborhood and wanted to invite you! - ${firstName}';
          }
        }
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
        _inputFields.inputSelect(_optsYesNo, _formVals, 'showImage', label: 'Show Image?', onChanged: (val) {
          _formVals['showImage'] = int.parse(val);
          setState(() { _formVals = _formVals; });
        }),
        // _inputFields.inputSelect(_optsYesNo, _formVals, 'showMap', label: 'Show Map?', onChanged: (val) {
        //   _formVals['showMap'] = int.parse(val);
        //   setState(() { _formVals = _formVals; });
        // }),
        _inputFields.inputSelect(_optsYesNo, _formVals, 'showQrCode', label: 'Show QR Code?', onChanged: (val) {
          _formVals['showQrCode'] = int.parse(val);
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
        _inputFields.inputSelect(_optsYesNo, _formVals, 'withTearOffs', label: 'With Tear Offs?', onChanged: (val) {
          _formVals['withTearOffs'] = int.parse(val);
          setState(() { _formVals = _formVals; });
        }),
      ];
    }

    List<Widget> colsMessage = [];
    if (_formVals['showMessage'] == 1) {
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
          _layoutService.WrapWidth(inputs),
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
    Map<String, dynamic> config = _configService.GetConfig();
    // String startDate = _dateTime.Format(_event.start, 'EEEE HH:mm');
    String day = _dateTime.Format(_event.start, 'EEEE');
    String time = _dateTime.Format(_event.start, 'h:mma');
    String startDate = '${day}s ${time}';
    List<Widget> admins = [];
    if (_weeklyEvent.adminUsers.length > 0) {
      if (_formVals['columns'] < 4) {
        admins += [ _style.Text1('${_weeklyEvent.adminUsers[0].email}', left: Icon(Icons.mail)), ];
      } else {
        admins += [ _style.Text1('${_weeklyEvent.adminUsers[0].email}'), ];
      }
      admins += [ SizedBox(height: 10), ];
    }

    List<Widget> colsImage = [];
    if (_formVals['showImage'] == 1) {
      colsImage += [
        _weeklyEvent.imageUrls.length <= 0 ?
          Image.asset('assets/images/shared-meal.jpg', height: imageHeight, width: double.infinity, fit: BoxFit.cover,)
          : Image.network(_weeklyEvent.imageUrls![0], height: imageHeight, width: double.infinity, fit: BoxFit.cover),
        SizedBox(height: 10),
      ];
    }

    List<Widget> colsUserMessage = [];
    if (_formVals['userMessage'].length > 0) {
      colsUserMessage += [
        // _style.Text1('Message From Host', size: 'large', colorKey: 'primary'),
        // SizedBox(height: 10),
        Text(_formVals['userMessage'], style: GoogleFonts.dancingScript(fontSize: 20),),
        SizedBox(height: 10),
      ];
    }

    // List<Widget> colsOutro = [];
    // if (_formVals['outroNote'].length > 0) {
    //   colsOutro += [
    //     Text(_formVals['outroNote']),
    //     SizedBox(height: 10),
    //   ];
    // }

    List<Widget> colsNeighborhoodEvents = [];
    if (_formVals['showNeighborhoodEvents'] == 1) {
      String url = '${config['SERVER_URL']}/ne/${_weeklyEvent.neighborhoodUName}';
      colsNeighborhoodEvents += [
        _style.Text1('Can\'t make this time or have different interests?'),
        SizedBox(height: 10),
      ];
      if (_formVals['columns'] < 4) {
        colsNeighborhoodEvents += [ _style.Text1('${url}', left: Icon(Icons.link)), ];
      } else {
        colsNeighborhoodEvents += [ _style.Text1('${url}'), ];
      }
      colsNeighborhoodEvents.add(SizedBox(height: 10));
    }

    List<Widget> colsInterests = [];
    if (_formVals['showInterests'] == 1) {
      String url = '${config['SERVER_URL']}/interests';
      if (_formVals['columns'] < 4) {
        colsInterests += [ _style.Text1('${url}', left: Icon(Icons.link)), ];
      } else {
        colsInterests += [ _style.Text1('${url}'), ];
      }
      colsInterests.add(SizedBox(height: 10));
    }

    List<Widget> colsTearOffs = [];
    if (_formVals['withTearOffs'] == 1) {
      int size = 23;
      int padding = 10;
      int count = ((_widthTotal / _formVals['columns']).round() / (size + padding * 2)).floor() - 1;
      String url1 = '${config['SERVER_URL']}/we/${_weeklyEvent.uName}';
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
              child: Text('${url1}'),
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

    String shareUrl = '${config['SERVER_URL']}/we/${_weeklyEvent.uName}';
    List<Widget> colsQrCode = [];
    if (_formVals['showQrCode'] == 1) {
      colsQrCode += [
        QrImageView(
          data: shareUrl,
          version: QrVersions.auto,
          size: 200.0,
        ),
        SizedBox(height: 10),
      ];
    }

    Widget? iconCalendar = _formVals['columns'] < 4 ? Icon(Icons.calendar_month) : null;
    Widget? iconLink = _formVals['columns'] < 4 ? Icon(Icons.link) : null;
    List<Widget> colsDetails = [
      _style.Text1('${startDate}', left: iconCalendar),
      SizedBox(height: 10),
      ...admins,
      _style.Text1('${shareUrl}', left: iconLink),
      SizedBox(height: 10),
      ...colsNeighborhoodEvents,
      ...colsInterests,
    ];
    List<Widget> colsDetailsQR = [
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
            ]
          )),
        ]
      )
    ];
    if (_formVals['columns'] > 2) {
      colsDetailsQR = [
        ...colsDetails,
        ...colsQrCode,
      ];
    }

    List<Widget> colsDescription = [];
    if (_formVals['columns'] < 3) {
      colsDescription += [
        // _style.Text1('Description', size: 'large', colorKey: 'primary'),
        // SizedBox(height: 10),
        Text(_weeklyEvent.description),
        SizedBox(height: 10),
      ];
    }
    return Container(padding: EdgeInsets.all(10), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...colsUserMessage,
        ...colsImage,
        _style.Text1('${_weeklyEvent.title}', size: 'large', colorKey: 'primary'),
        SizedBox(height: 10),
        ...colsDescription,
        // _style.Text1('Event Details', size: 'large', colorKey: 'primary'),
        // SizedBox(height: 10),
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
