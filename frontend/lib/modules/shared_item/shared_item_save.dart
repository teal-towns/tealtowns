import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';

import '../../app_scaffold.dart';
import '../../common/currency_service.dart';
import '../../common/layout_service.dart';
import '../../common/classes/location_class.dart';
import '../../common/socket_service.dart';
import '../../common/form_input/input_fields.dart';
import '../../common/form_input/input_location.dart';
import '../../common/form_input/image_save.dart';
import '../../common/location_service.dart';
import '../../common/parse_service.dart';
import './shared_item_class.dart';
import './shared_item_state.dart';
import './shared_item_service.dart';
import '../user_auth/current_user_state.dart';

class SharedItemSave extends StatefulWidget {
  @override
  _SharedItemSaveState createState() => _SharedItemSaveState();
}

class _SharedItemSaveState extends State<SharedItemSave> {
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();
  InputFields _inputFields = InputFields();
  Location _location = Location();
  SharedItemService _sharedItemService = SharedItemService();
  CurrencyService _currency = CurrencyService();
  LayoutService _layoutService = LayoutService();
  LocationService _locationService = LocationService();
  ParseService _parseService = ParseService();

  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> _formVals = {
    'bought': 0,
    'currency': 'USD',
    'generation': 0,
    'monthsToPayBack': 12,
    'maintenancePerYear': 50,
    'minOwners': 2,
    'maxOwners': 10,
    'maxMeters': 1500,
    'status': 'available',
  };
  List<Map<String, String>> _selectOptsStatus = [
    {'value': 'available', 'label': 'Available'},
    {'value': 'owned', 'label': 'Owned'},
  ];
  List<Map<String, String>> _selectOptsBought = [
    {'value': '1', 'label': 'Already bought (I own this)'},
    {'value': '0', 'label': 'Need to buy'},
  ];
  List<Map<String, dynamic>> _selectOptsMaxMeters = [
    {'value': 500, 'label': '5 min walk'},
    {'value': 1500, 'label': '15 min walk'},
    {'value': 3500, 'label': '15 min bike'},
    {'value': 8000, 'label': '15 min car'},
  ];
  Map<String, dynamic?> _formValsInfo = {
    'maxCurrentPrice': null,
    'minMonthlyPaymentPerPerson': null,
    'minDownPaymentPerPerson': null,
    'minMonthsToPayBack': null,
    'maxMonthlyPaymentPerPerson': null,
    'maxDownPaymentPerPerson': null,
    'maxMonthsToPayBack': null,
  };
  bool _loading = false;
  String _message = '';
  Map<String, dynamic> _formValsLngLat = {
    'lngLat': [-999.0, -999.0],
    // 'latitude': -999.0,
    // 'longitude': -999.0,
  };

  bool _loadedSharedItem = false;
  bool _skipCurrentLocation = false;

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('saveSharedItem', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        String sharedItemId = data['sharedItem']['_id'];
        String sharedItemOwnerId = '';
        if (data.containsKey('sharedItemOwner') && data['sharedItemOwner'].containsKey('_id')) {
          sharedItemOwnerId = data['sharedItemOwner']['_id'];
        }
        // If new item that is already bought, user is already an owner and there is nothing to invest, so skip owner page.
        if ((!_formVals.containsKey('_id') ||_formVals['_id'].length < 1) &&
          _parseService.toIntNoNull(_formVals['bought']) > 0) {
          context.go('/own');
        } else {
          context.go('/shared-item-owner-save?sharedItemId=${sharedItemId}&id=${sharedItemOwnerId}');
        }
      } else {
        setState(() { _message = data['msg'].length > 0 ? data['msg'] : 'Error, please try again.'; });
      }
      setState(() { _loading = false; });
    }));

    if (!Provider.of<CurrentUserState>(context, listen: false).isLoggedIn) {
      Timer(Duration(milliseconds: 200), () {
        context.go('/own');
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_){
        _init();
      });
    }
  }

  @override
  void dispose() {
    _socketService.offRouteIds(_routeIds);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var sharedItemState = context.watch<SharedItemState>();
    if (sharedItemState.sharedItem != null && !_loadedSharedItem) {
      _loadedSharedItem = true;
      setFormVals(sharedItemState.sharedItem);
    }

    if (!Provider.of<CurrentUserState>(context, listen: false).isLoggedIn) {
      return Text("You must be logged in");
    }
    var currentUserState = context.watch<CurrentUserState>();

    List<Widget> colsMinMax = [];
    if (_formValsInfo['minDownPaymentPerPerson'] != null && _formValsInfo['minMonthlyPaymentPerPerson'] != null) {
      Map<String, String> texts = _sharedItemService.GetTexts(_formValsInfo['minDownPaymentPerPerson']!,
        _formValsInfo['minMonthlyPaymentPerPerson']!, _formValsInfo['minMonthsToPayBack']!, _formVals['currency']);
      colsMinMax += [
        Text("Payments per person with ${_formVals['maxOwners'].toString()} owners: ${texts['perPerson']}"),
        SizedBox(height: 10),
      ];
    }
    if (_formValsInfo['maxDownPaymentPerPerson'] != null && _formValsInfo['maxMonthlyPaymentPerPerson'] != null) {
      Map<String, String> texts = _sharedItemService.GetTexts(_formValsInfo['maxDownPaymentPerPerson']!,
        _formValsInfo['maxMonthlyPaymentPerPerson']!, _formValsInfo['maxMonthsToPayBack']!, _formVals['currency']);
      colsMinMax += [
        Text("Payments per person with ${_formVals['minOwners'].toString()} owners: ${texts['perPerson']}"),
        SizedBox(height: 10),
      ];
    }
    String money = _currency.Format(_formValsInfo['maxCurrentPrice'], _formVals['currency']);
    String maxCurrentPriceText = _formValsInfo['maxCurrentPrice'] != null ? "(Max ${money})" : '';

    return AppScaffoldComponent(
      body: ListView(
        children: [
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 800,
              padding: EdgeInsets.only(top: 20, left: 10, right: 10),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // _buildUserLngLat(context, currentUserState),
                    ImageSaveComponent(formVals: _formVals, formValsKey: 'imageUrls', multiple: true,
                      label: 'Images', imageUploadSimple: true, maxImageSize: 1200),
                    // ImageSaveComponent(formVals: _formVals, formValsKey: 'imageUrls', multiple: true,
                    //   label: 'Images', maxImageSize: 1200),
                    SizedBox(height: 10),
                    _inputFields.inputText(_formVals, 'title', label: 'Title', required: true),
                    SizedBox(height: 10),
                    _inputFields.inputText(_formVals, 'description', label: 'Description', required: false, minLines: 5, maxLines: 5),
                    SizedBox(height: 10),
                    // Row(
                    //   children: [
                    //     Expanded(
                    //       flex: 1,
                    //       child: _inputFields.inputNumber(_formValsLngLat, 'longitude', label: 'Longitude', required: true, onChange: (double? val) {
                    //         if (val != null) {
                    //           setState(() { _formValsLngLat['longitude'] = val!; });
                    //         }
                    //       }),
                    //     ),
                    //     SizedBox(width: 10),
                    //     Expanded(
                    //       flex: 1,
                    //       child: _inputFields.inputNumber(_formValsLngLat, 'latitude', label: 'Latitude', required: true, onChange: (double? val) {
                    //         if (val != null) {
                    //           setState(() { _formValsLngLat['latitude'] = val!; });
                    //         }
                    //       }),
                    //     ),
                    //     // SizedBox(width: 10),
                    //     // ElevatedButton(
                    //     //   onPressed: () {
                    //     //     saveUser(currentUserState);
                    //     //   },
                    //     //   child: Text('Save'),
                    //     // ),
                    //   ]
                    // ),
                    // SizedBox(height: 10),
                    _layoutService.WrapWidth([
                      InputLocation(formVals: _formValsLngLat, formValsKey: 'lngLat', label: 'Location'),
                      _inputFields.inputSelect(_selectOptsBought, _formVals, 'bought', label: 'Do you already own this item?', ),
                      _inputFields.inputNumber(_formVals, 'originalPrice', label: 'Original (New) Price ', required: true, onChange: (double? val) {
                        ValidateSharedItem();
                        }),
                      // SizedBox(height: 10),
                      // Generation is auto updated.
                      // _inputFields.inputNumber(_formVals, 'generation', label: 'Generation', required: true, onChange: (double? val) {
                      //   ValidateSharedItem();
                      //   }),
                      // SizedBox(height: 10),
                      _inputFields.inputNumber(_formVals, 'currentPrice',
                        label: 'Current Price  ${maxCurrentPriceText}', required: true, onChange: (double? val) {
                        ValidateSharedItem();
                        }),
                      // SizedBox(height: 10),
                      _inputFields.inputNumber(_formVals, 'monthsToPayBack', label: 'Months to Pay Back', required: true, onChange: (double? val) {
                        ValidateSharedItem();
                        }),
                      // SizedBox(height: 10),
                      _inputFields.inputNumber(_formVals, 'maintenancePerYear', label: 'Yearly Maintenance Cost ', required: true, onChange: (double? val) {
                        ValidateSharedItem();
                        }),
                      // SizedBox(height: 10),
                      _inputFields.inputNumber(_formVals, 'minOwners', label: 'Minimum Owners', required: true, onChange: (double? val) {
                        ValidateSharedItem();
                        }),
                      // SizedBox(height: 10),
                      _inputFields.inputNumber(_formVals, 'maxOwners', label: 'Maximum Owners', required: true, onChange: (double? val) {
                        ValidateSharedItem();
                        }),
                      _inputFields.inputSelect(_selectOptsMaxMeters, _formVals, 'maxMeters', label: 'Owners max distance away', ),
                      _inputFields.inputSelect(_selectOptsStatus, _formVals, 'status', label: 'Status', required: true),
                    ]),
                    SizedBox(height: 10),
                    ...colsMinMax,
                    _buildSubmit(context, currentUserState),
                    _buildMessage(context),
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

  void _init() async {
    if (!_skipCurrentLocation) {
      List<double> lngLat = await _locationService.GetLocation(context);
      setState(() {
        _formValsLngLat['lngLat'] = lngLat;
      });
    }
    // var currentUser = Provider.of<CurrentUserState>(context, listen: false).currentUser;
    // if (currentUser.location.coordinates.length > 0) {
    //   setState(() {
    //     _formValsLngLat['longitude'] = currentUser.location.coordinates[0];
    //     _formValsLngLat['latitude'] = currentUser.location.coordinates[1];
    //   });
    // }
    // else if (!_skipCurrentLocation) {
    //   var coordinates = await _location.getLocation();
    //   if (coordinates.latitude != null) {
    //     setState(() {
    //       _formValsLngLat['latitude'] = coordinates.latitude!;
    //       _formValsLngLat['longitude'] = coordinates.longitude!;
    //     });
    //   }
    // }
  }

  Widget _buildSubmit(BuildContext context, currentUserState) {
    if (_loading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: LinearProgressIndicator(),
      );
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
            save(currentUserState);
          } else {
            _message = 'Please fill out all fields and try again.';
          }
          setState(() { _message = _message; });
        },
        child: Text('Save Item'),
      ),
    );
  }

  Widget _buildMessage(BuildContext context) {
    if (_message.length > 0) {
      return Text(_message);
    }
    return SizedBox.shrink();
  }

  void setFormVals(SharedItemClass sharedItem) {
    _formVals = sharedItem.toJson();
    // _formVals['_id'] = sharedItem.id;
    // _formVals['title'] = sharedItem.title;
    // _formVals['description'] = sharedItem.description;
    // _formVals['imageUrls'] = sharedItem.imageUrls;
    // //_formVals['tags'] = sharedItem.tags;
    // _formVals['tags'] = [];
    if (sharedItem.location.coordinates.length > 0) {
      _formValsLngLat['lngLat'] = sharedItem.location.coordinates;
    }
    ValidateSharedItem();
  }

  bool formValid(currentUserState) {
    if (_formValsLngLat['lngLat'] == null) {
      return false;
    } else {
      _formVals['location'] = {
        'type': 'Point',
        'coordinates': _formValsLngLat['lngLat'],
      };
    }
    _formVals['currentOwnerUserId'] = currentUserState.currentUser.id;
    if (!_formKey.currentState!.validate()) {
      return false;
    }
    ValidateSharedItem();
    // if (currentUserState.currentUser.location.coordinates.length < 1 && 
    //   (_formValsUser['latitude'] == null || _formValsUser['longitude'] == null)) {
    //   return false;
    // }
    return true;
  }

  void ValidateSharedItem() {
    bool shouldUpdate = false;
    if (_formVals['originalPrice'] != null && _formVals['generation'] != null && _formVals['currentPrice'] != null) {
      double maxCurrentPrice = _sharedItemService.MaxCurrentPrice(_formVals['originalPrice'], _formVals['generation']);
      _formValsInfo['maxCurrentPrice'] = maxCurrentPrice;
      shouldUpdate = true;
      if (_formVals['currentPrice'] > maxCurrentPrice) {
        _formVals['currentPrice'] = maxCurrentPrice;
        setState(() { _formVals = _formVals; });
      }
    }
    if (_formVals['currentPrice'] != null && _formVals['monthsToPayBack'] != null && _formVals['minOwners'] != null &&
      _formVals['maxOwners'] != null && _formVals['maintenancePerYear'] != null) {
      Map<String, dynamic> paymentInfoMin = _sharedItemService.GetPayments(_formVals['currentPrice']!,
        _formVals['monthsToPayBack']!, _formVals['maxOwners']!, _formVals['maintenancePerYear']!);
      _formValsInfo['minDownPaymentPerPerson'] = paymentInfoMin['downPerPerson'];
      _formValsInfo['minMonthlyPaymentPerPerson'] = paymentInfoMin['monthlyPayment'];
      _formValsInfo['minMonthsToPayBack'] = paymentInfoMin['monthsToPayBack'];

      Map<String, dynamic> paymentInfoMax = _sharedItemService.GetPayments(_formVals['currentPrice']!,
        _formVals['monthsToPayBack']!, _formVals['minOwners']!, _formVals['maintenancePerYear']!);
      _formValsInfo['maxDownPaymentPerPerson'] = paymentInfoMax['downPerPerson'];
      _formValsInfo['maxMonthlyPaymentPerPerson'] = paymentInfoMax['monthlyPayment'];
      _formValsInfo['maxMonthsToPayBack'] = paymentInfoMax['monthsToPayBack'];

      shouldUpdate = true;
    }
    if (shouldUpdate) {
      setState(() { _formValsInfo = _formValsInfo; });
    }
  }

  void save(currentUserState) {
    // if (currentUserState.currentUser.location.coordinates.length < 1) {
    //   saveUser(currentUserState);
    // }

    var data = {
      'sharedItem': _formVals,
    };
    _socketService.emit('saveSharedItem', data);
  }

}
