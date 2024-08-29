import 'package:flutter/material.dart';

import '../../app_scaffold.dart';
// import '../../common/form_input/input_fields.dart';
import '../../common/form_input/form_save.dart';
import '../../common/colors_service.dart';
import '../../common/style.dart';

class DesignLibrary extends StatefulWidget {
  @override
  _DesignLibraryState createState() => _DesignLibraryState();
}

class _DesignLibraryState extends State<DesignLibrary> {
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
  List<Map<String, dynamic>> _optsRange = [
    {'value': 1, 'label': 'Strongly disagree'},
    {'value': 2, 'label': 'Disagree'},
    {'value': 3, 'label': 'Neutral'},
    {'value': 4, 'label': 'Agree'},
    {'value': 5, 'label': 'Strongly agree'},
  ];
  Map<String, Map<String, dynamic>> _formFields = {
    'imageUrls': { 'type': 'image', 'multiple': true, 'label': 'Images', 'required': false, },
    'location': { 'type': 'location', 'nestedCoordinates': true, 'fullScreen': false, },
    'locationFullScreen': { 'type': 'location', 'nestedCoordinates': true },
    'title': {},
    'description': { 'type': 'text', 'minLines': 4, 'required': false, 'label': 'Description (optional)' },
    'dayOfWeek': { 'type': 'select' },
    'startTime': { 'type': 'time' },
    'hostGroupSizeDefault': { 'type': 'number', 'min': 0, 'required': true },
    'range': { 'type': 'selectButtons', 'label': 'I like food?' },
    'ranges': { 'type': 'multiSelectButtons', 'label': 'Choose multiple', },
    'days': { 'type': 'multiSelect', 'label': 'Days' },
  };
  Map<String, dynamic>_formVals = {
    'location': { 'coordinates': [0.0,0.0] },
    'locationFullScreen': { 'coordinates': [0.0,0.0] },
    'range': 2,
    'days': [0,2],
  };

  @override
  void initState() {
    super.initState();

    _formFields['dayOfWeek']!['options'] = _optsDayOfWeek;
    _formFields['range']!['options'] = _optsRange;
    _formFields['ranges']!['options'] = _optsRange;
    _formFields['days']!['options'] = _optsDayOfWeek;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> colors = [];
    for (var keyVal in _colors.colors.entries) {
      String key = keyVal.key;
      colors.add(
        Column(
          children: [
            Container(
              height: 150,
              width: 150,
              color: _colors.colors[key],
              // child: Text(key),
            ),
            Text('${key}'),
            _style.SpacingH('medium'),
            Text('${_colors.GetRGB(key)}'),
          ],
        ),
      );
    }

    List<Widget> fonts = [];
    Map<String, double> fontSizes = _style.GetFontSizes();
    for (var keyVal in fontSizes.entries) {
      String key = keyVal.key;
      fonts.add(
        Column(
          children: [
            _style.Text1(key, size: key),
            _style.Spacing(height: key),
          ],
        ),
      );
    }

    return AppScaffoldComponent(
      listWrapper: true,
      body: Column(
        children: [
          _style.Text1('Design Library', size: 'xlarge'),
          _style.SpacingH('medium'),
          Text('We use Material 3 with Flutter: https://docs.flutter.dev/ui/widgets/material | See also: https://docs.flutter.dev/ui/widgets for Flutter widgets and https://pub.dev/ for other libraries'),
          _style.SpacingH('medium'),
          _style.Text1('Forms', size: 'large'),
          _style.SpacingH('medium'),
          FormSave(formVals: _formVals, formFields: _formFields, requireLoggedIn: false, preSave: (dynamic data) {
            print ('preSave: ${data}');
          }),
          _style.SpacingH('medium'),
          _style.Text1('Colors', size: 'large'),
          _style.SpacingH('medium'),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: colors,
          ),
          _style.SpacingH('medium'),
          _style.Text1('Font Size', size: 'large'),
          _style.SpacingH('medium'),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...fonts,
            ]
          ),
        ]
      )
    );
  }
}
