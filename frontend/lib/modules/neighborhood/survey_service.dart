import 'dart:math';

class SurveyService {
  SurveyService._privateConstructor();
  static final SurveyService _instance = SurveyService._privateConstructor();
  factory SurveyService() {
    return _instance;
  }

  Map<String, Map<String, dynamic>> BelongingBarometer() {
    List<Map<String, dynamic>> opts = [
      {'value': 1, 'label': 'Strongly disagree'},
      {'value': 2, 'label': 'Disagree'},
      {'value': 3, 'label': 'Neutral'},
      {'value': 4, 'label': 'Agree'},
      {'value': 5, 'label': 'Strongly agree'},
    ];
    List<Map<String, dynamic>> optsReverse = [
      {'value': 5, 'label': 'Strongly disagree'},
      {'value': 4, 'label': 'Disagree'},
      {'value': 3, 'label': 'Neutral'},
      {'value': 2, 'label': 'Agree'},
      {'value': 1, 'label': 'Strongly agree'},
    ];
    List<Map<String, dynamic>> questions = [
      { 'label': 'I feel emotionally connected to my neighborhood', 'options': opts, 'type': 'selectButtons', },
      { 'label': 'People in my neighborhood welcome and include me in activities', 'options': opts, 'type': 'selectButtons', },
      { 'label': 'I am unable to influence decision making in my neighborhood', 'options': optsReverse, 'type': 'selectButtons', },
      { 'label': 'I feel unable to be my whole and authentic self with people in my neighborhood', 'options': optsReverse, 'type': 'selectButtons', },
      { 'label': 'People in my neighborhood value me and my contributions', 'options': opts, 'type': 'selectButtons', },
      { 'label': 'My relationships with others in my neighborhood are as satisfying as I want them to be', 'options': opts, 'type': 'selectButtons', },
      { 'label': 'I feel like an \'insider\' who understands how my neighborhood works', 'options': opts, 'type': 'selectButtons', },
      { 'label': 'I am comfortable expressing my opinions in my neighborhood', 'options': opts, 'type': 'selectButtons', },
      { 'label': 'I am treated as \'less than\' other residents in my neighborhood', 'options': optsReverse, 'type': 'selectButtons', },
      { 'label': 'When interacting with my neighbors, I feel like I truly belong', 'options': opts, 'type': 'selectButtons', },
    ];
    questions.shuffle();
    Map<String, Map<String, dynamic>> questionsFields = {};
    for (int i = 0; i < questions.length; i++) {
      questionsFields['q${i+1}'] = questions[i];
    }
    return questionsFields;
  }
}