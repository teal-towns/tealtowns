import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app_scaffold.dart';
import '../../common/buttons.dart';
import '../../common/config_service.dart';
import '../../common/form_input/input_fields.dart';
import '../../common/layout_service.dart';
import '../../common/layout_wrap.dart';
import '../../common/link_service.dart';
import '../../common/socket_service.dart';
import '../../common/style.dart';
import '../neighborhood/neighborhood_state.dart';
import '../user_auth/current_user_state.dart';
import '../user_auth/user_login_signup.dart';
import './mixer_game_class.dart';
import './mixer_match.dart';
import '../icebreaker/icebreakers.dart';

class MixerGame extends StatefulWidget {
  String uName;
  MixerGame({this.uName = ''});

  @override
  _MixerGameState createState() => _MixerGameState();
}

class _MixerGameState extends State<MixerGame> {
  Buttons _buttons = Buttons();
  ConfigService _configService = ConfigService();
  InputFields _inputFields = InputFields();
  LayoutService _layoutService = LayoutService();
  LinkService _linkService = LinkService();
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();
  Style _style = Style();

  bool _loading = false;
  Map<String, dynamic> _formVals = {
    'uName': '',
  };
  Map<String, dynamic> _formValsSave = {
    'neighborhoodUName': '',
    'gameType': 'match',
    'gameDetails': {
      'question': '',
    },
  };
  List<Map<String, dynamic>> _optsNeighborhood = [];
  MixerGameClass _mixerGame = MixerGameClass.fromJson({});
  // List<Map<String, dynamic>> _optsGameState = [
  //   {'value': 'playing', 'label': 'Start Game'},
  //   {'value': 'gameOver', 'label': 'End Game'},
  // ];
  String _selfPlayerId = '';
  bool _gameNotFound = false;

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('GetMixerGameByUName', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        if (!data.containsKey('mixerGame')) {
          data['mixerGame'] = {};
        }
        _mixerGame = MixerGameClass.fromJson(data['mixerGame']);
        if (_mixerGame.id.length < 1) {
          setState(() { _gameNotFound = true; _loading = false; });
        } else {
          setState(() { _mixerGame = _mixerGame; _formValsSave = _mixerGame.toJson(); _loading = false; });
        }
      }
    }));

    _routeIds.add(_socketService.onRoute('SaveMixerGame', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1 && data.containsKey('mixerGame')) {
        _mixerGame = MixerGameClass.fromJson(data['mixerGame']);
        if (_mixerGame.uName.length > 0 && Uri.base.path.contains('mixer-game')) {
          context.go('/mg/' + _mixerGame.uName);
        } else {
          setState(() { _mixerGame = _mixerGame; _formValsSave = _mixerGame.toJson(); _loading = false; });
        }
      }
    }));

    _routeIds.add(_socketService.onRoute('OnMixerGame', callback: (String resString) {
      var res = json.decode(resString);
      var data = res['data'];
      if (data['valid'] == 1 && data.containsKey('mixerGame')) {
        _mixerGame = MixerGameClass.fromJson(data['mixerGame']);
        setState(() { _mixerGame = _mixerGame; _formValsSave = _mixerGame.toJson(); _loading = false; });
      }
    }));

    _routeIds.add(_socketService.onRoute('GetRandomIcebreakers', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        _formValsSave['gameDetails']['question'] = data['icebreakers'][0]['icebreaker'];
        setState(() { _formValsSave = _formValsSave; });
      }
    }));

    NeighborhoodState neighborhoodState = Provider.of<NeighborhoodState>(context, listen: false);
    if (neighborhoodState.defaultUserNeighborhood != null) {
      _formValsSave['neighborhoodUName'] = neighborhoodState.defaultUserNeighborhood!.neighborhood.uName;
      if (neighborhoodState.userNeighborhoods.length > 1) {
        _optsNeighborhood = [];
        for (int i = 0; i < neighborhoodState.userNeighborhoods.length; i++) {
          String uName = neighborhoodState.userNeighborhoods[i].neighborhood.uName;
          _optsNeighborhood.add({'value': uName, 'label': uName, });
        }
      }
    } else if (widget.uName.length < 1) {
      // _redirecting = true;
      Timer(Duration(milliseconds: 200), () {
        context.go('/neighborhoods');
      });
    }

    if (widget.uName.length > 0) {
      setState(() { _loading = true; });
      _socketService.emit('GetMixerGameByUName', {'uName': widget.uName});
    }
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
        body: Column( children: [ LinearProgressIndicator() ]),
      );
    }

    if (_gameNotFound) {
      return AppScaffoldComponent(
        listWrapper: true,
        body: Column( children: [
          _style.Text1('Game Not Found'),
          _style.SpacingH('medium'),
          _style.Text1('Try checking the URL and try again.',),
          _style.SpacingH('medium'),
          _buttons.Link(context, 'Or Create a New Game', '/mixer-game', checkLoggedIn: true),
        ]),
      );
    }

    Map<String, dynamic> config = _configService.GetConfig();
    CurrentUserState currentUserState = context.watch<CurrentUserState>();
    List<Widget> colsHostControls = [];
    List<Widget> colsWinner = [];
    List<Widget> colsScores = [];
    List<Widget> colsGame = [];
    List<Widget> colsJoinOrCreate = [];
    List<Widget> colsQR = [];
    if (_mixerGame.id.length > 0) {
      bool isHost = false;
      if (currentUserState.isLoggedIn && _mixerGame.hostUserIds.contains(currentUserState.currentUser.id)) {
        isHost = true;
        if (_mixerGame.state == 'playing') {
          colsHostControls = [
            ElevatedButton(child: Text('End Game'), onPressed: () {
              _mixerGame.state = 'gameOver';
              _socketService.emit('SaveMixerGame', { 'mixerGame': _mixerGame.toJson() });
            }),
            _style.SpacingH('medium'),
          ];
        }
      }
      if (_mixerGame.state == 'gameOver' || isHost) {
        int submittedPlayersCount = 0;
        if (_mixerGame.state == 'gameOver') {
          colsScores += [
            _style.Text1('Scores', size: 'large'),
            _style.SpacingH('medium'),
          ];
        }
        bool isWinner = false;
        List<Widget> scoresItems = [];
        for (int i = 0; i < _mixerGame.players.length; i++) {
          if (_mixerGame.players[i]['scoreState'] == 'submitted') {
            submittedPlayersCount += 1;
            if (_mixerGame.state == 'gameOver') {
              String textTemp = '${_mixerGame.players[i]['playerName']}: ${_mixerGame.players[i]['score']}';
              if (_mixerGame.players[i]['reward'] == 'winner') {
                textTemp += ' (WINNER!)';
                if (_selfPlayerId.length > 0 && _selfPlayerId == _mixerGame.players[i]['playerId']) {
                  isWinner = true;
                }
              } else if (_mixerGame.players[i]['reward'] == 'random') {
                textTemp += ' (RANDOM WINNER!)';
                if (_selfPlayerId.length > 0 && _selfPlayerId == _mixerGame.players[i]['playerId']) {
                  isWinner = true;
                }
              }
              // colsScores += [
              //   _style.Text1(textTemp),
              //   _style.SpacingH('medium'),
              // ];
              scoresItems.add(_style.Text1(textTemp));
            }
          }
        }
        if (scoresItems.length > 0) {
          colsScores += [
            LayoutWrap(items: scoresItems,),
            _style.SpacingH('medium'),
          ];
        }

        if (isHost && _mixerGame.players.length > 0) {
          colsHostControls += [
            _style.Text1('${submittedPlayersCount} of ${_mixerGame.players.length} players submitted (${(submittedPlayersCount / _mixerGame.players.length * 100).toStringAsFixed(0)}%)',),
            _style.SpacingH('medium'),
          ];
        }

        // If self player is winner, show that, and note to sign up or log in to claim it.
        if (_mixerGame.state == 'gameOver' && isWinner) {
          if (currentUserState.isLoggedIn) {
            colsWinner = [
              _style.Text1('YOU WON!'),
              _style.SpacingH('medium'),
              // ElevatedButton(child: Text('Claim Your \$10 Credit'), onPressed: () {
              //   var dataSend = { 'mixerGameUName': _mixerGame.uName, 'userId': currentUserState.currentUser.id, 'playerId': _selfPlayerId };
              //   _socketService.emit('ClaimMixerGameReward', dataSend);
              // }),
              // _style.SpacingH('medium'),
            ];
          } else {
            colsWinner = [
              _style.Text1('YOU WON!', size: 'large'),
              _style.SpacingH('medium'),
              // _style.Text1('Sign up (or log in) to claim your \$10 credit'),
              // _style.SpacingH('medium'),
              // UserLoginSignup(onSave: (Map<String, dynamic> data) {
              //   var dataSend = { 'mixerGameUName': _mixerGame.uName, 'userId': data['user']['_id'], 'playerId': _selfPlayerId };
              //   _socketService.emit('ClaimMixerGameReward', dataSend);
              // }),
              // _style.SpacingH('medium'),
            ];
          }
        }
      }
      if (_mixerGame.gameType == 'match') {
        if (_mixerGame.state == 'gameOver') {
          colsGame += [
            // _style.Text1('Game is over',),
            // _style.SpacingH('medium'),
            _buttons.Link(context, 'Create a New Game', '/mixer-game', checkLoggedIn: true),
            _style.SpacingH('medium'),
          ];
        }
        colsGame += [
          MixerMatch(mixerGame: _mixerGame, onSelfPlayer: (Map<String, dynamic> data) {
            _selfPlayerId = data['playerId'];
            setState(() { _selfPlayerId = _selfPlayerId; });
          }),
        ];
      }

      if (_mixerGame.state != 'gameOver') {
        String shareUrl = '${config['SERVER_URL']}/mg/${_mixerGame.uName}';
        colsQR = [
          _style.SpacingH('xlarge'),
          _style.Text1('Invite others to play:', size: 'large'),
          _style.SpacingH('medium'),
          QrImageView(
            data: shareUrl,
            version: QrVersions.auto,
            size: 200.0,
          ),
          _style.SpacingH('medium'),
          _style.Text1(shareUrl),
          _style.SpacingH('medium'),
        ];
      }
    } else {
      List<Widget> colsCreate = [];
      if (currentUserState.isLoggedIn) {
        List<Widget> colsNeighborhood = [];
        if (_optsNeighborhood.length > 0) {
          colsNeighborhood = [
            _inputFields.inputSelect(_optsNeighborhood, _formValsSave, 'neighborhoodUName', label: 'Neighborhood',),
          ];
        }
        colsCreate = [
          _inputFields.inputText(_formValsSave['gameDetails'], 'question', label: 'Enter a question to create a new game'),
          ...colsNeighborhood,
          _style.SpacingH('medium'),
          ElevatedButton(child: Text('Create Game'), onPressed: () {
            if (_formValsSave['gameDetails']['question'].length > 1) {
              setState(() { _loading = true; });
              _formValsSave['hostUserIds'] = [currentUserState.currentUser.id];
              _socketService.emit('SaveMixerGame', { 'mixerGame': _formValsSave });
            }
          }),
          _style.SpacingH('medium'),
          TextButton(child: Text('Generate Random Question'), onPressed: () {
            _socketService.emit('GetRandomIcebreakers', {'count': 1});
          }),
          _style.SpacingH('medium'),
          _style.Text1('Or search and select a question from below.'),
          Icebreakers(withScaffold: false, showCreate: false, withHeader: false, onSelect: (Map<String, dynamic> data) {
            _formValsSave['gameDetails']['question'] = data['icebreaker']['icebreaker'];
            setState(() { _formValsSave = _formValsSave; });
          }),
        ];
      } else {
        colsCreate = [
          _style.Text1('Or log in to create a new game.'),
          _style.SpacingH('medium'),
          UserLoginSignup(onSave: (Map<String, dynamic> data) {
          }),
        ];
      }
      colsJoinOrCreate = [
        // _inputFields.inputText(_formVals, 'uName', label: 'Enter the game code to join!', onChanged: (val) {
        //   setState(() { _loading = true; });
        //   _socketService.emit('GetMixerGameByUName', {'uName': val});
        // }),
        // _style.SpacingH('xlarge'),
        ...colsCreate,
      ];
    }

    return AppScaffoldComponent(
      listWrapper: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...colsJoinOrCreate,
          ...colsHostControls,
          ...colsWinner,
          ...colsScores,
          ...colsGame,
          ...colsQR,
        ]
      )
    );
  }
}