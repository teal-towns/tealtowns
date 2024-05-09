import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import './survey_service.dart';
import '../../app_scaffold.dart';
import '../../common/form_input/form_save.dart';
import '../../common/style.dart';
import '../user_auth/current_user_state.dart';

class BelongingSurvey extends StatefulWidget {
  @override
  _BelongingSurveyState createState() => _BelongingSurveyState();
}

class _BelongingSurveyState extends State<BelongingSurvey> {
  Style _style = Style();
  SurveyService _surveyService = SurveyService();

  Map<String, dynamic>_formVals = {};
  Map<String, Map<String, dynamic>> _formFields = {};

  String _scoreText = '';

  @override
  void initState() {
    super.initState();

    _formFields = _surveyService.BelongingBarometer();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffoldComponent(
      listWrapper: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _style.Text1('Belonging Barometer', size: 'xlarge'),
          _style.Spacing(height: 'medium'),
          _style.Text1('https://www.projectoverzero.org/media-and-publications/belongingbarometer'),
          _style.Spacing(height: 'medium'),
          FormSave(formVals: _formVals, formFields: _formFields, fieldWidth: double.infinity, align: 'left',
            saveText: 'See my score',
            preSave: (dynamic data) {
              int score = 0;
              int count = 0;
              for(var v in data.values) {
                score += int.tryParse(v) ?? 0;
                count += 1;
              }
              double average = score / count;
              String scoreLabel = 'Exclusion';
              if (average > 2.33) {
                scoreLabel = 'Ambiguity';
              }
              if (average > 3.67) {
                scoreLabel = 'Belonging';
              }
              setState(() { _scoreText = '${scoreLabel} (${average.toStringAsFixed(2)} of 5)'; });
              return data;
            },
          ),
          // SizedBox(height: 10,),
          _style.Text1(_scoreText, size: 'large', fontWeight: FontWeight.bold),
        ]
      )
    );
  }

}
