import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/buttons.dart';
import '../../common/colors_service.dart';
import '../../common/form_input/input_fields.dart';
import '../../common/socket_service.dart';
import '../../common/style.dart';
import '../neighborhood/neighborhood_events.dart';
import '../neighborhood/neighborhood_state.dart';
import '../user_auth/current_user_state.dart';
import '../user_auth/user_login_signup.dart';
import './mixer_game_class.dart';
import './mixer_game_state.dart';
import './mixer_match_player_class.dart';

class MixerMatch extends StatefulWidget {
  MixerGameClass mixerGame;
  Function(Map<String, dynamic>) onSelfPlayer;
  MixerMatch({required this.mixerGame, required this.onSelfPlayer,});

  @override
  _MixerMatchState createState() => _MixerMatchState();
}

class _MixerMatchState extends State<MixerMatch> {
  Buttons _buttons = Buttons();
  ColorsService _colors = ColorsService();
  InputFields _inputFields = InputFields();
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();
  Style _style = Style();

  bool _loading = false;
  List<MixerMatchPlayerClass> _mixerMatchPlayers = [];
  // key is player id, value is { name, answer }
  Map<String, dynamic> _answers = {};
  String _userId = '';
  int _selectedNameIndex = -1;
  int _selectedAnswerIndex = -1;
  MixerMatchPlayerClass _selfPlayer = MixerMatchPlayerClass.fromJson({});
  List<Map<String, dynamic>> _playerNames = [];
  List<Map<String, dynamic>> _playerAnswers = [];
  Map<String, dynamic> _formVals = {
    'firstName': '',
    'lastName': '',
    'name': '',
    'answer': '',
  };
  String _messageJoin = '';

  Timer? _timer;
  int _countdown = 60;
  String _gameState = ''; // 'countdown'
  String _nameMode = 'guest';
  bool _useCountdown = false;

  void startTimer() {
    const oneSec = const Duration(seconds: 1);
    _timer = new Timer.periodic(
      oneSec,
      (Timer timer) {
        if (_countdown == 0) {
          setState(() {
            timer.cancel();
          });
        } else {
          setState(() {
            _countdown--;
          });
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('OnMixerMatchPlayers', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1 && data.containsKey('mixerMatchPlayers')) {
        _mixerMatchPlayers = [];
        _playerNames = [];
        _playerAnswers = [];
        for (var i = 0; i < data['mixerMatchPlayers'].length; i++) {
          _mixerMatchPlayers.add(MixerMatchPlayerClass.fromJson(data['mixerMatchPlayers'][i]));
          if (!_answers.containsKey(data['mixerMatchPlayers'][i]['_id'])) {
            Map<String, dynamic> item = { 'playerId': data['mixerMatchPlayers'][i]['_id'],
              'name': data['mixerMatchPlayers'][i]['name'], 'answer': data['mixerMatchPlayers'][i]['answer'], };
            _playerNames.add(item);
            _playerAnswers.add(item);
          }
        }
        // _playerNames.shuffle();
        _playerAnswers.shuffle();
        setState(() { _mixerMatchPlayers = _mixerMatchPlayers;
          _playerNames = _playerNames; _playerAnswers = _playerAnswers; });
        UpdateMixerGameState(['mixerMatchPlayers', 'playerNames', 'playerAnswers']);
      }
    }));

    _routeIds.add(_socketService.onRoute('SaveMixerMatchPlayer', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1 && data.containsKey('mixerMatchPlayer') && data['mixerMatchPlayer'].containsKey('_id')) {
        _selfPlayer = MixerMatchPlayerClass.fromJson(data['mixerMatchPlayer']);
        if (_useCountdown) {
          _gameState = widget.mixerGame.state == 'gameOver' ? '' : 'countdown';
        }
        setState(() { _selfPlayer = _selfPlayer; _gameState = _gameState; });
        UpdateMixerGameState(['selfPlayer', 'gameState']);
        widget.onSelfPlayer({ 'playerId': data['mixerMatchPlayer']['_id'] });
        startTimer();
      }
    }));

    _routeIds.add(_socketService.onRoute('GetMixerMatchPlayerByUserId', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1 && data.containsKey('mixerMatchPlayer') && data['mixerMatchPlayer'].containsKey('_id')) {
        _selfPlayer = MixerMatchPlayerClass.fromJson(data['mixerMatchPlayer']);
        // _gameState = widget.mixerGame.state == 'gameOver' ? '' : 'countdown';
        if (_useCountdown) {
          _gameState = widget.mixerGame.state == 'gameOver' ? '' : 'countdown';
        }
        setState(() { _selfPlayer = _selfPlayer; _gameState = _gameState; });
        UpdateMixerGameState(['selfPlayer', 'gameState']);
        widget.onSelfPlayer({ 'playerId': data['mixerMatchPlayer']['_id'] });
        startTimer();
      }
    }));

    _routeIds.add(_socketService.onRoute('OnMixerGame', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1 && data.containsKey('mixerGame')) {
        if (data['mixerGame']['state'] == 'gameOver') {
          CheckSubmitAnswers(MixerGameClass.fromJson(data['mixerGame']));
        }
      }
    }));

    CurrentUserState currentUserState = Provider.of<CurrentUserState>(context, listen: false);
    if (currentUserState.isLoggedIn) {
      _socketService.emit('GetMixerMatchPlayerByUserId', { 'mixerGameUName': widget.mixerGame.uName,
        'userId': currentUserState.currentUser.id});
    // } else if (_mixerMatchPlayers.length == 0) {
    //   _socketService.emit('GetMixerMatchPlayers', { 'mixerGameUName': widget.mixerGame.uName, });
    }

    _formVals['mixerGameUName'] = widget.mixerGame.uName;

    var mixerGameState = Provider.of<MixerGameState>(context, listen: false);
    for (String key in mixerGameState.keyVals.keys) {
      dynamic val = mixerGameState.keyVals[key];
      if (key == 'mixerMatchPlayers') {
        _mixerMatchPlayers = [];
        for (var i = 0; i < val.length; i++) {
          _mixerMatchPlayers.add(MixerMatchPlayerClass.fromJson(val[i]));
        }
      } else if (key == 'selfPlayer') {
        _selfPlayer = MixerMatchPlayerClass.fromJson(val);
      } else if (key == 'gameState') {
        _gameState = val;
      } else if (key == 'answers') {
        _answers = val;
      } else if (key == 'playerNames') {
        _playerNames = val;
      } else if (key == 'playerAnswers') {
        _playerAnswers = val;
      } else if (key == 'formVals') {
        _formVals = val;
      } else if (key == 'selectedNameIndex') {
        _selectedNameIndex = val;
      } else if (key == 'selectedAnswerIndex') {
        _selectedAnswerIndex = val;
      }
    }
  }

  void UpdateMixerGameState(List<String> keys) {
    var mixerGameState = Provider.of<MixerGameState>(context, listen: false);
    var keyVals = mixerGameState.keyVals;
    for (String key in keys) {
      if (key == 'selfPlayer') {
        keyVals[key] = _selfPlayer.toJson();
      } else if (key == 'mixerMatchPlayers') {
        List<Map<String, dynamic>> val = [];
        for (var i = 0; i < _mixerMatchPlayers.length; i++) {
          val.add(_mixerMatchPlayers[i].toJson());
        }
        keyVals[key] = val;
      } else if (key == 'gameState') {
        keyVals[key] = _gameState;
      } else if (key == 'answers') {
        keyVals[key] = _answers;
      } else if (key == 'playerNames') {
        keyVals[key] = _playerNames;
      } else if (key == 'playerAnswers') {
        keyVals[key] = _playerAnswers;
      } else if (key == 'formVals') {
        keyVals[key] = _formVals;
      } else if (key == 'selectedNameIndex') {
        keyVals[key] = _selectedNameIndex;
      } else if (key == 'selectedAnswerIndex') {
        keyVals[key] = _selectedAnswerIndex;
      }
    }
    mixerGameState.Save(keyVals);
  }

  @override
  void dispose() {
    if (_timer != null) {
      _timer!.cancel(); 
    }
    _socketService.offRouteIds(_routeIds);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Column( children: [ LinearProgressIndicator() ]);
    }

    if (_gameState == 'countdown') {
      Widget gameStart = _style.Text1('Game starts in ${_countdown}', size: 'large');
      if (_countdown == 0) {
        gameStart = ElevatedButton(child: Text('Start Game'), onPressed: () {
          setState(() { _gameState = ''; });
          UpdateMixerGameState(['gameState']);
        });
      }
      return Column(
        children: [
          gameStart,
          _style.SpacingH('medium'),
          _style.Text1('Check out these other local events while you wait'),
          _style.SpacingH('medium'),
          NeighborhoodEvents(uName: widget.mixerGame.neighborhoodUName, withAppScaffold: false,
            withWeeklyEventFilters: 0, withWeeklyEventsCreateButton: 0, inlineMode: 1),
        ]
      );
    }

    // To begin, user adds their answer and name to start playing.
    bool showJoinButton = true;
    if (_selfPlayer.id.length == 0 && widget.mixerGame.state != 'gameOver') {
      List<Widget> colsJoinGame = [];
      CurrentUserState currentUserState = Provider.of<CurrentUserState>(context, listen: false);
      if (currentUserState.isLoggedIn) {
        _formVals['userId'] = currentUserState.currentUser.id;
        // name will be created later, so just set first and last name.
        // _formVals['name'] = currentUserState.currentUser.firstName + ' (' + currentUserState.currentUser.username + ')';
        _formVals['firstName'] = currentUserState.currentUser.firstName;
        _formVals['lastName'] = '(' + currentUserState.currentUser.username + ')';
      } else if (widget.mixerGame.state == 'playing') {
        if (_nameMode == 'loginSignup') {
          showJoinButton = false;
          colsJoinGame += [
            Column(
              // crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserLoginSignup(withHeader: false, mode: 'signup', logInText: 'Log In to Join Game',
                  signUpText: 'Sign Up and Join Game', firstName: _formVals['firstName'],
                  lastName: _formVals['lastName'], onSave: (Map<String, dynamic> data) {
                  String userId = data['user']['_id'];
                  // Add (new) user to this neighborhood.
                  if (data['mode'] == 'signup') {
                    Provider.of<NeighborhoodState>(context, listen: false).SaveUserNeighborhood(widget.mixerGame.neighborhoodUName, userId);
                  }
                  // Join game.
                  _formVals['name'] = data['user']['firstName'] + ' (' + data['user']['username'] + ')';
                  _formVals['userId'] = userId;
                  if (_formVals['answer'].length > 1) {
                    _socketService.emit('SaveMixerMatchPlayer', { 'mixerMatchPlayer': _formVals });
                    setState(() { _messageJoin = ''; _formVals = _formVals; });
                    UpdateMixerGameState(['formVals']);
                  } else {
                    setState(() { _messageJoin = 'Please answer the question'; _formVals = _formVals; });
                    UpdateMixerGameState(['formVals']);
                  }
                }),
                _style.SpacingH('medium'),
                TextButton(child: Text('Or play as a guest'), onPressed: () {
                  setState(() { _nameMode = 'guest'; });
                }),
              ]
            ),
          ];
        } else {
          colsJoinGame += [
            Column(
              // crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _inputFields.inputText(_formVals, 'firstName', label: 'Your name',),
                // _inputFields.inputText(_formVals, 'firstName', label: 'What is your first name?',),
                // _inputFields.inputText(_formVals, 'lastName', label: 'Your last name?',),
                // _style.SpacingH('medium'),
                // TextButton(child: Text('Or Log In / Sign Up'), onPressed: () {
                //   setState(() { _nameMode = 'loginSignup'; });
                // }),
              ],
            ),
          ];
        }
      }
      if (widget.mixerGame.state == 'playing') {
        if (showJoinButton) {
          colsJoinGame += [
            _style.SpacingH('large'),
            ElevatedButton(child: Text('Join Game'), onPressed: () {
              if (_formVals['answer'].length > 1) {
                _formVals['name'] = _formVals['firstName'] + ' ' + _formVals['lastName'];
                _socketService.emit('SaveMixerMatchPlayer', { 'mixerMatchPlayer': _formVals });
                setState(() { _messageJoin = ''; });
              } else {
                setState(() { _messageJoin = 'Please answer the question'; });
              }
            }),
            _style.SpacingH('medium'),
            _style.Text1(_messageJoin),
            _style.SpacingH('medium'),
          ];
        }
      }
      return Container(
        width: 600,
        child: Column(
          // crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _style.SpacingH('medium'),
            _style.Text1('Mixer Match', size: 'xxlarge', colorKey: 'primary'),
            _style.SpacingH('medium'),
            _style.Text1('This is a mix and match game. Fill out your answer below and join the game to play.',
              align: 'center'),
            _style.SpacingH('medium'),
            _style.Text1(widget.mixerGame.gameDetails['question'], fontWeight: FontWeight.bold),
            _inputFields.inputText(_formVals, 'answer', label: 'Your answer',),
            // _style.SpacingH('medium'),
            ...colsJoinGame,
          ],
        ),
      );
    }

    List<Widget> colsNotSubmitted = [];
    List<Widget> colsSubmitted = [];
    if (_playerNames.length > 0 && widget.mixerGame.state != 'gameOver') {
      // Two columns (names on left, answers on right).
      // Answered ones at the bottom, non answered at the top (shuffled).
      // Press a name and answer to make a match. Press an answered (name or answer) to un-answer.
      List<Widget> colsNames = [];
      List<Widget> colsAnswers = [];
      List<Widget> colsAnsweredNames = [];
      List<Widget> colsAnsweredAnswers = [];
      for (String playerId in _answers.keys) {
        String name = _answers[playerId]['name'];
        String answer = _answers[playerId]['answer'];
        colsAnsweredNames.add(
          Container(padding: EdgeInsets.only(top: 5, bottom: 5), child: FilledButton(
            onPressed: () {
              if (widget.mixerGame.state == 'playing') {
                _answers.remove(playerId);
                Map<String, dynamic> item1 = { 'playerId': playerId, 'name': name, 'answer': answer, };
                _playerNames.add(item1);
                _playerAnswers.add(item1);
                setState(() { _answers = _answers; _playerNames = _playerNames; _playerAnswers = _playerAnswers; });
                UpdateMixerGameState(['answers', 'playerNames', 'playerAnswers']);
              }
            },
            child: _style.Text1(name),
            style: FilledButton.styleFrom(
              backgroundColor: _colors.colors['greyLighter'],
              // foregroundColor: _colors.colors['white'],
            ),
          )),
        );
        colsAnsweredAnswers.add(
          Container(padding: EdgeInsets.only(top: 5, bottom: 5), child: FilledButton(
            onPressed: () {
              if (widget.mixerGame.state == 'playing') {
                _answers.remove(playerId);
                Map<String, dynamic> item1 = { 'playerId': playerId, 'name': name, 'answer': answer, };
                _playerNames.add(item1);
                _playerAnswers.add(item1);
                setState(() { _answers = _answers; _playerNames = _playerNames; _playerAnswers = _playerAnswers; });
                UpdateMixerGameState(['answers', 'playerNames', 'playerAnswers']);
              }
            },
            child: _style.Text1(answer,),
            style: FilledButton.styleFrom(
              backgroundColor: _colors.colors['greyLighter'],
              // foregroundColor: _colors.colors['white'],
            ),
          )),
        );
      }

      for (int i = 0; i < _playerNames.length; i++) {
        Map<String, dynamic> item = _playerNames[i];
        String colorKeyName = 'greyLighter';
        if (_selectedNameIndex == i) {
          colorKeyName = 'secondary';
        }
        colsNames.add(
          Container(padding: EdgeInsets.only(top: 5, bottom: 5), child: FilledButton(
            onPressed: () {
              if (widget.mixerGame.state == 'playing') {
                if (_selectedNameIndex == i) {
                  _selectedNameIndex = -1;
                } else {
                  _selectedNameIndex = i;
                  if (_selectedAnswerIndex >= 0) {
                    _answers[_playerNames[_selectedNameIndex]['playerId']] = { 'name': _playerNames[_selectedNameIndex]['name'],
                      'answer': _playerAnswers[_selectedAnswerIndex]['answer'], };
                    _playerNames.removeAt(_selectedNameIndex);
                    _playerAnswers.removeAt(_selectedAnswerIndex);
                    setState(() { _answers = _answers; _selectedNameIndex = -1; _selectedAnswerIndex = -1;
                      _playerNames = _playerNames; _playerAnswers = _playerAnswers; });
                    UpdateMixerGameState(['answers', 'playerNames', 'playerAnswers', 'selectedNameIndex',
                      'selectedAnswerIndex']);
                    if (_playerNames.length == 0) {
                      CheckSubmitAnswers(widget.mixerGame);
                    }
                  }
                }
                setState(() { _selectedNameIndex = _selectedNameIndex; });
                UpdateMixerGameState(['selectedNameIndex']);
              }
            },
            child: _style.Text1(item['name']),
            style: FilledButton.styleFrom(
              backgroundColor: _colors.colors[colorKeyName],
              // foregroundColor: _colors.colors['white'],
            ),
          )),
        );
      }
      for (int i = 0; i < _playerAnswers.length; i++) {
        Map<String, dynamic> item = _playerAnswers[i];
        String colorKeyAnswer = 'greyLighter';
        if (_selectedAnswerIndex == i) {
          colorKeyAnswer = 'secondary';
        }
        colsAnswers.add(
          Container(padding: EdgeInsets.only(top: 5, bottom: 5), child: FilledButton(
            onPressed: () {
              if (widget.mixerGame.state == 'playing') {
                if (_selectedAnswerIndex == i) {
                  _selectedAnswerIndex = -1;
                } else {
                  _selectedAnswerIndex = i;
                  if (_selectedNameIndex >= 0) {
                    _answers[_playerNames[_selectedNameIndex]['playerId']] = { 'name': _playerNames[_selectedNameIndex]['name'],
                      'answer': _playerAnswers[_selectedAnswerIndex]['answer'], };
                    _playerNames.removeAt(_selectedNameIndex);
                    _playerAnswers.removeAt(_selectedAnswerIndex);
                    setState(() { _answers = _answers; _selectedNameIndex = -1; _selectedAnswerIndex = -1;
                      _playerNames = _playerNames; _playerAnswers = _playerAnswers; });
                    UpdateMixerGameState(['answers', 'playerNames', 'playerAnswers', 'selectedNameIndex',
                      'selectedAnswerIndex']);
                    if (_playerNames.length == 0) {
                      CheckSubmitAnswers(widget.mixerGame);
                    }
                  }
                }
                setState(() { _selectedAnswerIndex = _selectedAnswerIndex; });
                UpdateMixerGameState(['selectedAnswerIndex']);
              }
            },
            child: _style.Text1(item['answer']),
            style: FilledButton.styleFrom(
              backgroundColor: _colors.colors[colorKeyAnswer],
              // foregroundColor: _colors.colors['white'],
            ),
          )),
        );
      }

      List<Widget> colsDone = [];
      if (colsAnsweredNames.length > 0) {
        colsDone = [
          _style.SpacingH('xlarge'),
          _style.Text1('Your Answers (Press to Unmatch)',),
          _style.SpacingH('medium'),
          Row(
            children: [
              Expanded(flex: 1, child: Column(
                children: [
                  _style.Text1('Name', fontWeight: FontWeight.bold,),
                  _style.SpacingH('medium'),
                  ...colsAnsweredNames,
                ]
              )),
              _style.SpacingV('medium'),
              Expanded(flex: 1, child: Column(
                children: [
                  _style.Text1('Answer', fontWeight: FontWeight.bold,),
                  _style.SpacingH('medium'),
                  ...colsAnsweredAnswers,
                ]
              )),
            ]
          ),
        ];
      }

      colsNotSubmitted = [
        _style.SpacingH('large'),
        _style.Text1('Match each person\'s name to their answer',),
        _style.SpacingH('medium'),
        Row(
          children: [
            Expanded(flex: 1, child: Column(
              children: [
                _style.Text1('Name', fontWeight: FontWeight.bold,),
                _style.SpacingH('medium'),
                ...colsNames,
              ]
            )),
            _style.SpacingV('medium'),
            Expanded(flex: 1, child: Column(
              children: [
                _style.Text1('Answer', fontWeight: FontWeight.bold,),
                _style.SpacingH('medium'),
                ...colsAnswers,
              ]
            )),
          ]
        ),
        ...colsDone,
      ];
    } else {
      List<Widget> colsPlayers = [];
      int score = 0;
      for (int i = 0; i < _mixerMatchPlayers.length; i++) {
        String playerId = _mixerMatchPlayers[i].id;
        String colorKey = 'text';
        if (_answers.containsKey(playerId)) {
          if (_answers[playerId]['answer'] == _mixerMatchPlayers[i].answer) {
            colorKey = 'success';
            score += 1;
          } else {
            colorKey = 'error';
          }
        }
        colsPlayers += [
          _style.Text1('${_mixerMatchPlayers[i].name}: ${_mixerMatchPlayers[i].answer}', colorKey: colorKey),
          _style.SpacingH('medium'),
        ];
      }

      if (_answers.length > 0) {
        colsSubmitted += [
          _style.Text1('You got ${score} of ${_mixerMatchPlayers.length} correct', size: 'large'),
          _style.SpacingH('medium'),
        ];
      } else if (_mixerMatchPlayers.length > 0) {
        colsSubmitted += [
          _style.Text1('Answers:', size: 'large'),
          _style.SpacingH('medium'),
        ];
      }
      colsSubmitted += [
        ...colsPlayers,
        _style.SpacingH('medium'),
        _style.Text1('Join other local events to play more!', size: 'large'),
        _style.SpacingH('medium'),
        NeighborhoodEvents(uName: widget.mixerGame.neighborhoodUName, withAppScaffold: false,
          withWeeklyEventFilters: 0, withWeeklyEventsCreateButton: 0, inlineMode: 1),
      ];
    }

    List<Widget> colsQuestion = [];
    if (widget.mixerGame.state != 'gameOver') {
      colsQuestion = [
        _style.Text1('${widget.mixerGame.gameDetails['question']}', size: 'xlarge', colorKey: 'primary'),
        _style.SpacingH('medium'),
      ];
    }

    return Align(
      alignment: Alignment.center,
      child: Column(
        children: [
          ...colsQuestion,
          ...colsNotSubmitted,
          ...colsSubmitted,
        ]
      ),
    );
  }

  void CheckSubmitAnswers(MixerGameClass mixerGame) {
    if (_selfPlayer.id.length > 0) {
      // See if user has submitted score yet.
      // bool submitted = true;
      // for (int i = 0; i < mixerGame.players.length; i++) {
      //   if (mixerGame.players[i]['playerId'] == _selfPlayer.id && mixerGame.players[i]['scoreState'] != 'submitted') {
      //     submitted = false;
      //     break;
      //   }
      // }
      // if (mixerGame.state == 'gameOver' || !submitted) {
      if (true) {
        // Compute score
        int score = 0;
        for (int i = 0; i < _mixerMatchPlayers.length; i++) {
          String playerId = _mixerMatchPlayers[i].id;
          if (_answers.containsKey(playerId) && _answers[playerId]['answer'] == _mixerMatchPlayers[i].answer) {
            score += 1;
          }
        }
        var dataSend = {
          'mixerGameUName': mixerGame.uName,
          'player': { 'playerId': _selfPlayer.id, 'score': score, }
        };
        _socketService.emit('UpdateMixerGamePlayerScore', dataSend);
      }
    }
  }
}