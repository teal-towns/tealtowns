import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_scaffold.dart';
import '../../common/currency_service.dart';
import '../../common/link_service.dart';
import '../../common/parse_service.dart';
import '../../common/socket_service.dart';
import '../../common/form_input/input_fields.dart';
import './shared_item_class.dart';
import './shared_item_owner_class.dart';
import './shared_item_service.dart';
import '../user_auth/current_user_state.dart';

class SharedItemOwnerSave extends StatefulWidget {
  String sharedItemOwnerId;
  String sharedItemId;
  String userId;
  int generation;
  SharedItemOwnerSave({this.sharedItemOwnerId = '', this.sharedItemId = '', this.userId = '',
    this.generation = 1});

  @override
  _SharedItemOwnerSaveState createState() => _SharedItemOwnerSaveState();
}

class _SharedItemOwnerSaveState extends State<SharedItemOwnerSave> {
  List<String> _routeIds = [];
  CurrencyService _currency = CurrencyService();
  LinkService _linkService = LinkService();
  ParseService _parseService = ParseService();
  SocketService _socketService = SocketService();
  InputFields _inputFields = InputFields();
  SharedItemService _sharedItemService = SharedItemService();

  SharedItemOwnerClass _sharedItemOwner = SharedItemOwnerClass.fromJson({});
  SharedItemClass _sharedItem = SharedItemClass.fromJson({});
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> _formVals = {
    'totalPaid': 0,
    'totalOwed': 0,
    'generation': 1,
    'investorOnly': 0,
  };
  List<Map<String, dynamic>> _selectOptsInvestorOnly = [
    {'value': 0, 'label': 'Co-Owner'},
    {'value': 1, 'label': 'Investor Only'},
  ];
  Map<String, dynamic> _formValsInfo = {
    'numOwners': 0,
    'downPaymentUSDWithFee': 0,
    'downPaymentUSD': 0,
    'investTotalPaid': 0,
  };
  List<Map<String, String>> _selectOptsNumOwners = [];
  List<Map<String, dynamic>> _selectOptsInvest = [];
  String _paymentDetails = '';
  String _investmentDetails = '';
  bool _firstLoadDone = false;
  bool _loading = false;
  String _message = '';
  bool _paymentMade = false;
  bool _loadingPayment = false;

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('getSharedItemOwner', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        if (!data['sharedItem'].containsKey('_id')) {
          context.go('/own');
        } else {
          _sharedItem = SharedItemClass.fromJson(data['sharedItem']);
          _sharedItemOwner = SharedItemOwnerClass.fromJson(data['sharedItemOwner']);
          _selectOptsNumOwners = [];
          for (int ii = _sharedItem.minOwners; ii <= _sharedItem.maxOwners; ii++) {
            _selectOptsNumOwners.add({'value': ii.toString(), 'label': ii.toString()});
          }
          // _formValsInfo['numOwners'] = _sharedItem.minOwners;
          _formValsInfo['numOwners'] = _sharedItemService.GetMinOwnersFromMaxMonthlyPayment(
            _sharedItemOwner.monthlyPayment, _sharedItem.minOwners, _sharedItem.maxOwners, _sharedItem.currentPrice,
            _sharedItem.monthsToPayBack, _sharedItem.maintenancePerYear);
          _selectOptsInvest = [
            {'value': 0, 'label': 'No'},
            {'value': _sharedItem.currentPrice, 'label': 'Yes, I will purchase for \$${_sharedItem.currentPrice}'},
          ];
          if (_formVals['totalPaid'] == _sharedItem.currentPrice) {
            _formValsInfo['investTotalPaid'] = _formVals['totalPaid'];
          }
          setState(() {
            _sharedItemOwner = _sharedItemOwner;
            _sharedItem = _sharedItem;
            _selectOptsNumOwners = _selectOptsNumOwners;
            _selectOptsInvest = _selectOptsInvest;
            _formValsInfo = _formValsInfo;
          });
          setFormVals(_sharedItemOwner);
          SetPaymentDetails();
          SetInvestmentDetails();
        }
      } else {
        setState(() { _message = data['message'].length > 0 ? data['message'] : 'Error, please try again.'; });
      }
      setState(() { _loading = false; _loadingPayment = false; });
    }));

    _routeIds.add(_socketService.onRoute('saveSharedItemOwner', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        context.go('/own');
      } else {
        setState(() { _message = data['message'].length > 0 ? data['message'] : 'Error, please try again.'; });
      }
      setState(() { _loading = false; });
    }));

    _routeIds.add(_socketService.onRoute('GetSharedItemDownPaymentLink', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        if (data.containsKey('haveBalance') && data['haveBalance'] > 0) {
          _formVals['totalPaid'] = data['totalPaid'];
          _formVals['investorOnly'] = 0;
          _paymentMade = true;
          save();
        } else {
          _linkService.LaunchURL(data['url']);
        }
      } else {
        setState(() { _message = data['message'].length > 0 ? data['message'] : 'Error, please try again.'; });
      }
      setState(() { _loading = false; });
    }));

    _routeIds.add(_socketService.onRoute('GetSharedItemMonthlyPaymentLink', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        _linkService.LaunchURL(data['url']);
      } else {
        setState(() { _message = data['message'].length > 0 ? data['message'] : 'Error, please try again.'; });
      }
      setState(() { _loading = false; });
    }));

    _routeIds.add(_socketService.onRoute('StripePaymentComplete', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['sharedItemId'] == _sharedItem.id) {
        if (data['type'] == 'sharedItemDownPayment') {
          _formVals['totalPaid'] = data['totalPaid'];
          _formVals['investorOnly'] = 0;
          _paymentMade = true;
          save();
        } else if (data['type'] == 'sharedItemMonthlyPayment') {
          var dataSend = {
            'sharedItemOwner': {
              '_id': _sharedItemOwner.id,
              'monthlyPayment': data['monthlyPayment'],
              'status': 'paying',
              'stripeMonthlyPriceId': data['stripeMonthlyPriceId'],
            },
          };
          saveData(dataSend);
        }
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
    if (!Provider.of<CurrentUserState>(context, listen: false).isLoggedIn) {
      return Text("You must be logged in");
    }
    var currentUserState = context.watch<CurrentUserState>();

    CheckFirstLoad();

    return AppScaffoldComponent(
      body: ListView(
        children: [
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 500,
              padding: EdgeInsets.only(top: 20, left: 10, right: 10),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SharedItemInfo(_sharedItem),
                    SizedBox(height: 10),
                    SharedItemOwnerContent(currentUserState),
                    SizedBox(height: 50),
                  ]
                )
              )
            )
          )
        ]
      )
    );
  }

  void CheckFirstLoad() {
    if (!_firstLoadDone) {
      _firstLoadDone = true;

      GetSharedItemOwner();
    }
  }

  void GetSharedItemOwner({int checkUpdatePayments = 0}) {
    var data = {
        'id': widget.sharedItemOwnerId,
        'sharedItemId': widget.sharedItemId,
        'userId': widget.userId,
        'generation': widget.generation,
        'withSharedItem': 1,
        'checkUpdatePayments': checkUpdatePayments,
      };
      _socketService.emit('getSharedItemOwner', data);
  }

  Widget _buildSubmit(BuildContext context, currentUserState) {
    if (_loading) {
      List<Widget> cols = [];
      if (_loadingPayment) {
        cols += [
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              GetSharedItemOwner(checkUpdatePayments: 1);
            },
            child: Text('Refresh Once Payment Is Made'),
          )
        ];
      }
      return Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: LinearProgressIndicator(),
          ),
          ...cols,
        ]
      );
    }
    // Do not allow submitting if payment has not been made.
    if (!_paymentMade && _parseService.toIntNoNull(_formVals['investorOnly']) == 0) {
      return SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.only(top: 15, bottom: 5),
      child: ElevatedButton(
        onPressed: () {
          _message = '';
          _loading = false;
          if (formValid(currentUserState)) {
            _loading = true;
            _formKey.currentState?.save();
            save();
          } else {
            _message = 'Please fill out all fields and try again.';
          }
          setState(() { _message = _message; });
        },
        child: Text('Save'),
      ),
    );
  }

  Widget _buildMessage(BuildContext context) {
    if (_message.length > 0) {
      return Text(_message);
    }
    return SizedBox.shrink();
  }

  Widget SharedItemOwnerContent(currentUserState) {
    if (_sharedItemOwner.status == 'pendingMonthlyPayment') {
      return Column(
        children: [
          Text('Set up your monthly payment to start using your shared item!'),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              _message = '';
              _loading = true;
              GetMonthlyPaymentLink(currentUserState);
              setState(() { _message = _message; _loading = _loading; });
            },
            child: Text('Set Up Monthly Payment'),
          ),
          SizedBox(height: 10),
        ]
      );
    } else {
      return Column(
        children: [
          SharedItemOwnerForm(currentUserState),
          SizedBox(height: 10),
          _buildSubmit(context, currentUserState),
          _buildMessage(context),
        ]
      );
    }
  }

  void SetPaymentDetails() {
    Map<String, dynamic> paymentInfo = _sharedItemService.GetPayments(_sharedItem.currentPrice!,
      _sharedItem.monthsToPayBack!, _parseService.toIntNoNull(_formValsInfo['numOwners']), _sharedItem.maintenancePerYear!);
    Map<String, String> texts = _sharedItemService.GetTexts(paymentInfo['downPerPersonWithFee']!,
      paymentInfo['monthlyPaymentWithFee']!, paymentInfo['monthsToPayBack']!, _sharedItem.currency);
    _paymentDetails = "${texts['perPersonDownLast']} (${_formValsInfo['numOwners']} owners)";
    _formVals['monthlyPayment'] = paymentInfo['monthlyPayment'];
    _formValsInfo['downPaymentUSDWithFee'] = paymentInfo['downPerPersonWithFee'];
    _formValsInfo['downPaymentUSD'] = paymentInfo['downPerPerson'];
    setState(() { _paymentDetails = _paymentDetails; _formVals = _formVals; _formValsInfo = _formValsInfo; });
  }

  void SetInvestmentDetails() {
    // Use max owners as they will pay it off the quickest, thus leading to the minimum profit.
    Map<String, dynamic> paymentInfo = _sharedItemService.GetPayments(_sharedItem.currentPrice!,
      _sharedItem.monthsToPayBack!, _sharedItem.maxOwners, _sharedItem.maintenancePerYear!);
    double profitPartial = min(paymentInfo['investorProfit'],
      paymentInfo['investorProfit'] * (_formValsInfo['investTotalPaid'] / _sharedItem.currentPrice!));
    String profit = _currency.Format(profitPartial, _sharedItem.currency);
    _investmentDetails = "${profit} total profit";
    setState(() { _investmentDetails = _investmentDetails; });
  }

  Widget SharedItemInfo(SharedItemClass sharedItem) {
    if (sharedItem == null || sharedItem.id.length < 1) {
      return SizedBox.shrink();
    }
    return Column(
      children: [
        Text(sharedItem.title),
        SizedBox(height: 10),
      ]
    );
  }

  Widget SharedItemOwnerForm(currentUserState) {
    List<Widget> colsInvest = [];
    if (_sharedItem.bought <= 0) {
      colsInvest += [
        Text('Investor'),
        SizedBox(height: 10),
        _inputFields.inputSelect(_selectOptsInvest, _formValsInfo, 'investTotalPaid', label: 'Will you purchase this item?', onChanged: (String newVal) {
          _formValsInfo['investTotalPaid'] = _parseService.toDoubleNoNull(newVal);
          setState(() {
            _formValsInfo = _formValsInfo;
          });
          SetInvestmentDetails();
        }),
        SizedBox(height: 10),
        Text(_investmentDetails),
        SizedBox(height: 10),
        _inputFields.inputSelect(_selectOptsInvestorOnly, _formVals, 'investorOnly', label: 'Will you co-own (also)?', onChanged: (String newVal) {
          _formVals['investorOnly'] = _parseService.toIntNoNull(newVal);
          setState(() {
            _formVals = _formVals;
          });
        }),
        SizedBox(height: 30),
      ];
    }

    List<Widget> colsCoOwn = [];
    List<Widget> colsPay =[];
    if (_parseService.toIntNoNull(_formVals['investorOnly']) == 0) {
      colsCoOwn += [
        Text('Co-Owner'),
        SizedBox(height: 10),
        _inputFields.inputSelect(_selectOptsNumOwners, _formValsInfo, 'numOwners', label: 'Minimum owners (max price you will pay)', onChanged: (String newVal) {
          SetPaymentDetails();
        }),
        SizedBox(height: 10),
        Text(_paymentDetails),
        SizedBox(height: 10),
      ];

      // if (_paymentMade) {
      //   colsPay += [
      //     Text('Payment received'),
      //     SizedBox(height: 10),
      //   ];
      // } else {
        String buttonText = _sharedItemOwner.id.length > 0 ? 'Update Your Spot' : 'Reserve Your Spot';
        colsPay += [
          ElevatedButton(
            onPressed: () {
              _message = '';
              _loading = false;
              if (formValid(currentUserState)) {
                _loading = true;
                _formKey.currentState?.save();
                GetDownPaymentLink(currentUserState);
              } else {
                _message = 'Please fill out all fields and try again.';
              }
              setState(() { _message = _message; });
            },
            child: Text(buttonText),
          ),
          SizedBox(height: 10),
        ];
      // }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...colsInvest,
        ...colsCoOwn,
        ...colsPay,
        SizedBox(height: 10),
      ],
    );
  }

  void setFormVals(SharedItemOwnerClass sharedItemOwner) {
    _formVals = sharedItemOwner.toJson();
  }

  bool formValid(currentUserState) {
    if (_formVals['userId'].length < 1) {
      _formVals['userId'] = currentUserState.currentUser.id;
    }
    if (_formVals['sharedItemId'].length < 1) {
      _formVals['sharedItemId'] = _sharedItem.id!;
    }
    // Only increase (if want to be an investor), do not reduce (if already paid, e.g. down payment as shared owner).
    if (_formValsInfo['investTotalPaid'] > _formVals['totalPaid']) {
      _formVals['totalPaid'] = _formValsInfo['investTotalPaid'];
    }
    // Can only update for pledges (future generation).
    _formVals['generation'] = _sharedItem.generation + 1;
    if (!_formKey.currentState!.validate()) {
      return false;
    }
    return true;
  }

  void save() {
    var data = {
      'sharedItemOwner': _formVals,
    };
    saveData(data);
  }

  void saveData(var data) {
    _socketService.emit('saveSharedItemOwner', data);
  }

  void GetDownPaymentLink(currentUserState) {
    var data = {
      'amountUSD': _formValsInfo['downPaymentUSDWithFee'],
      'sharedItemTitle': _sharedItem.title,
      'sharedItemId': _sharedItem.id!,
      'userId': currentUserState.currentUser.id,
      'checkAndUseBalance': 1,
    };
    _socketService.emit('GetSharedItemDownPaymentLink', data);
    setState(() { _loadingPayment = true; });
    // TODO - set loading payment
  }

  void GetMonthlyPaymentLink(currentUserState) {
    var data = {
      'sharedItemOwnerId': _sharedItemOwner.id,
    };
    _socketService.emit('GetSharedItemMonthlyPaymentLink', data);
    setState(() { _loadingPayment = true; });
    // TODO - set loading payment
  }
}