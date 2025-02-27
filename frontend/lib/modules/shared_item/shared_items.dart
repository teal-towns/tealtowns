import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:universal_html/html.dart' as html;

import '../../app_scaffold.dart';
import '../../common/buttons.dart';
import '../../common/currency_service.dart';
import '../../common/link_service.dart';
import '../../common/socket_service.dart';
import '../../common/form_input/input_fields.dart';
import '../../common/form_input/input_location.dart';
import '../../common/layout_service.dart';
import '../../common/location_service.dart';
import './shared_item_class.dart';
import './shared_item_state.dart';
import './shared_item_service.dart';
import './shared_item_owner_class.dart';
import '../user_auth/current_user_state.dart';
import '../../common/parse_service.dart';
import './shared_item.dart';

class SharedItems extends StatefulWidget {
  final double lat;
  final double lng;
  final double maxMeters;
  String myType;

  SharedItems({ this.lat = -999, this.lng = -999, this.maxMeters = 1500, this.myType = '', });

  @override
  _SharedItemsState createState() => _SharedItemsState();
}

class _SharedItemsState extends State<SharedItems> {
  Buttons _buttons = Buttons();
  InputFields _inputFields = InputFields();
  LayoutService _layoutService = LayoutService();
  LinkService _linkService = LinkService();
  LocationService _locationService = LocationService();
  CurrencyService _currency = CurrencyService();
  SharedItemService _sharedItemService = SharedItemService();
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();

  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic?> _filters = {
    'title': '',
    //'tags': '',
    'maxMeters': 1500,
    'fundingRequired_min': '',
    'fundingRequired_max': '',
    // 'lngLat': [-79.574983, 8.993036],
    'inputLocation': { 'lngLat': [0.0, 0.0], 'address': {} },
    'myType': '',
  };
  bool _loading = true;
  String _message = '';
  bool _canLoadMore = false;
  int _lastPageNumber = 1;
  int _itemsPerPage = 25;
  bool _skipCurrentLocation = false;
  bool _locationLoaded = false;

  List<SharedItemClass> _sharedItems = [];
  bool _firstLoadDone = false;
  var _selectedSharedItem = {
    'id': '',
  };

  List<Map<String, dynamic>> _selectOptsMaxMeters = [
    {'value': 500, 'label': '5 min walk'},
    {'value': 1500, 'label': '15 min walk'},
    {'value': 3500, 'label': '15 min bike'},
    {'value': 8000, 'label': '15 min car'},
  ];
  List<Map<String, dynamic>> _selectOptsMyType = [
    {'value': '', 'label': 'Any'},
    {'value': 'owner', 'label': 'My Owned Items'},
    {'value': 'purchaser', 'label': 'My Purchased Items'},
  ];
  List<Map<String, dynamic>> _selectOptsInvestor = [
    {'value': '', 'label': 'Any'},
    {'value': 1, 'label': 'Needs Investment'},
  ];

  @override
  void initState() {
    super.initState();
    
    _routeIds.add(_socketService.onRoute('searchSharedItems', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        if (data.containsKey('sharedItems')) {
          _sharedItems = [];
          for (var sharedItem in data['sharedItems']) {
            _sharedItems.add(SharedItemClass.fromJson(sharedItem));
          }
          if (_sharedItems.length == 0) {
            _message = 'No results found.';
          }
        } else {
          _message = 'Error.';
        }
      } else {
        _message = data['message'].length > 0 ? data['message'] : 'Error.';
      }
      setState(() {
        _loading = false;
      });
    }));

    _routeIds.add(_socketService.onRoute('removeSharedItem', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        _searchSharedItems();
      } else {
        _message = data['message'].length > 0 ? data['message'] : 'Error.';
      }
      setState(() {
        _loading = false;
      });
    }));

    _filters['inputLocation']['lngLat'] = _locationService.GetLngLat();
    if (widget.lat != 0 && widget.lng != 0) {
      _filters['inputLocation']['lngLat'] = [widget.lng, widget.lat];
      _skipCurrentLocation = true;
    }
    for (int ii = 0; ii < _selectOptsMaxMeters.length; ii++) {
      if (_selectOptsMaxMeters[ii]['value'] == widget.maxMeters) {
        _filters['maxMeters'] = widget.maxMeters;
        break;
      }
    }
    if (widget.myType.length > 0) {
      _filters['myType'] = widget.myType;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init();
    });
  }

  @override
  void dispose() {
    _socketService.offRouteIds(_routeIds);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    checkFirstLoad();

    var currentUserState = context.watch<CurrentUserState>();

    List<Widget> columnsCreate = [];
    // if (currentUserState.isLoggedIn) {
      columnsCreate = [
        Align(
          alignment: Alignment.topRight,
          child: ElevatedButton(
            onPressed: () {
              Provider.of<SharedItemState>(context, listen: false).clearSharedItem();
              _linkService.Go('/shared-item-save', context, currentUserState: currentUserState);
              _socketService.TrackEvent('Post New Item');
            },
            child: Text('Post New Item'),
          ),
        ),
        SizedBox(height: 10),
      ];
    // }

    return AppScaffoldComponent(
      listWrapper: true,
      width: 1500,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...columnsCreate,
          Align(
            alignment: Alignment.center,
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: _layoutService.WrapWidth([
                // _inputFields.inputSelect(_selectOptsMyType, _filters, 'myType',
                //     label: 'Type', onChanged: (String val) {
                //     _searchSharedItems();
                //   }),
                InputLocation(formVals: _filters, formValsKey: 'inputLocation', label: 'Location',
                  guessLocation: !_skipCurrentLocation, onChanged: (Map<String, dynamic> val) {
                  _searchSharedItems();
                  }),
                _inputFields.inputSelect(_selectOptsMaxMeters, _filters, 'maxMeters',
                    label: 'Range', onChanged: (String val) {
                    _searchSharedItems();
                  }),
                _inputFields.inputText(_filters, 'title', hint: 'title',
                    label: 'Title', debounceChange: 1000, onChanged: (String val) {
                    _searchSharedItems();
                  }),
                // _inputFields.inputSelect(_selectOptsInvestor, _filters, 'fundingRequired_min',
                //     label: 'Needs Investment', onChanged: (String val) {
                //     _searchSharedItems();
                //   }),
                // _inputFields.inputNumber(_filters, 'fundingRequired_min', hint: '\$1000',
                //     label: 'Minimum Funding Needed', debounceChange: 1000, onChanged: (double? val) {
                //     _searchSharedItems();
                //   }),
                // _inputFields.inputNumber(_filters, 'fundingRequired_max', hint: '\$500',
                //     label: 'Maximum Funding Needed', debounceChange: 1000, onChanged: (double? val) {
                //     _searchSharedItems();
                //   }),
              ], width: 225),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: _buildSharedItemResults(context, currentUserState),
          ),
        ]
      )
    );
  }

  void checkFirstLoad() {
    if (!_firstLoadDone && _locationLoaded) {
      _firstLoadDone = true;
      _searchSharedItems();
    }
  }

  void _init() async {
    if (!_skipCurrentLocation) {
      if (_locationService.LocationValid(_filters['inputLocation']['lngLat'])) {
        _searchSharedItems();
      }
      List<double> lngLat = await _locationService.GetLocation(context);
      if (_locationService.IsDifferent(lngLat, _filters['inputLocation']['lngLat'])) {
        setState(() {
          _filters['inputLocation']['lngLat'] = lngLat;
        });
      }
    }

    _locationLoaded = true;
    checkFirstLoad();
  }

  Widget _buildMessage(BuildContext context) {
    if (_message.length > 0) {
      return Container(
        padding: EdgeInsets.only(top: 20, bottom: 20, left: 10, right: 10),
        child: Text(_message),
      );
    }
    return SizedBox.shrink();
  }

  _buildSharedItem(SharedItemClass sharedItem, BuildContext context, var currentUserState) {
    var buttons = [
      _buttons.LinkElevated(context, 'View', '/si/${sharedItem.uName}'),
      SizedBox(width: 10),
    ];
    if (currentUserState.isLoggedIn && sharedItem.currentOwnerUserId == currentUserState.currentUser.id) {
      buttons += [
        TextButton(
          onPressed: () {
            Provider.of<SharedItemState>(context, listen: false).setSharedItem(sharedItem);
            _linkService.Go('/shared-item-save?id=${sharedItem.id}', context, currentUserState: currentUserState);
            // context.go('/shared-item-save');
          },
          child: Text('Edit'),
        ),
        SizedBox(width: 10),
        // SizedBox(width: 10),
        // ElevatedButton(
        //   onPressed: () {
        //     _socketService.emit('removeSharedItem', { 'id': sharedItem.id });
        //   },
        //   child: Text('Delete'),
        //   style: ElevatedButton.styleFrom(
        //     foregroundColor: Theme.of(context).colorScheme.error,
        //   ),
        // ),
        // SizedBox(width: 10),
      ];
    }
    // if (currentUserState.isLoggedIn && sharedItem.currentOwnerUserId != currentUserState.currentUser.id) {
    //   buttons += [
    //     ElevatedButton(
    //       onPressed: () {
    //         setState(() {
    //           _selectedSharedItem = {
    //             'id': sharedItem.id!,
    //           };
    //         });
    //       },
    //       child: Text('Borrow'),
    //       //style: ElevatedButton.styleFrom(
    //       //  foregroundColor: Theme.of(context).successColor,
    //       //),
    //     ),
    //     SizedBox(width: 10),
    //   ];
    // }

    var columnsDistance = [];
    if (sharedItem.xDistanceKm >= 0) {
      columnsDistance = [
        Text('${sharedItem.xDistanceKm.toStringAsFixed(1)} km away'),
        SizedBox(height: 10),
      ];
    }

    var columnsSelected = [];
    // if (sharedItem.id == _selectedSharedItem['id']) {
    //   columnsSelected = [
    //     Text('${sharedItem.xOwner['email']}'),
    //     SizedBox(height: 10),
    //   ];
    // }

    String currentPriceString = _currency.Format(sharedItem.currentPrice, sharedItem.currency!);

    Map<String, String> texts;
    Map<String, dynamic> paymentInfo;
    // int newOwners = (sharedItem.pledgedOwners >= sharedItem.minOwners) ? sharedItem.pledgedOwners + 1 : sharedItem.minOwners;
    // paymentInfo = _sharedItemService.GetPayments(sharedItem.currentPrice!,
    //   sharedItem.monthsToPayBack!, newOwners, sharedItem.maintenancePerYear!);
    // texts = _sharedItemService.GetTexts(paymentInfo['downPerPersonWithFee']!,
    //   paymentInfo['monthlyPaymentWithFee']!, paymentInfo['monthsToPayBack']!, sharedItem.currency);
    paymentInfo = _sharedItemService.GetPayments(sharedItem.currentPrice!,
      sharedItem.monthsToPayBack!, sharedItem.maxOwners, sharedItem.maintenancePerYear!);
    texts = _sharedItemService.GetTexts(paymentInfo['downPerPersonWithFee']!,
      paymentInfo['monthlyPaymentWithFee']!, paymentInfo['monthsToPayBack']!, sharedItem.currency);
    String perPersonMaxOwners =
        ParseService().toIntNoNull(sharedItem.bought) > 0
            ? ''
            : "${['perPerson']} with max owners (${sharedItem.maxOwners})";




    return SizedBox(
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sharedItem.imageUrls.length <= 0 ?
            Image.asset('assets/images/no-image-available-icon-flat-vector.jpeg', height: 300, width: double.infinity, fit: BoxFit.cover,)
              :Image.network(sharedItem.imageUrls![0], height: 300, width: double.infinity, fit: BoxFit.cover),
          SizedBox(height: 5),
          Text(sharedItem.title!,
            style: Theme.of(context).textTheme.displayMedium,
          ),
          SizedBox(height: 5),
          //Text('Tags: ${sharedItem.tags.join(', ')}'),
          //SizedBox(height: 5),
          ...columnsDistance,
          // Text('${currentPriceString}'),
          // Text('${(sharedItem.maxOwners - sharedItem.pledgedOwners)} spots left'),
          // Text('${sharedItem.minOwners} to ${sharedItem.maxOwners} owners'),
          // SizedBox(height: 10),
          Text("${perPersonMaxOwners}"),
          SizedBox(height: 10),
          SharedItemSections(
            sharedItem: sharedItem,
            currentUserState: currentUserState,
            currencyService: _currency,
            linkService: _linkService,
            parseService: ParseService(),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...buttons,
            ]
          ),
          SizedBox(height: 10),
          ...columnsSelected,
          SizedBox(height: 10),
        ]
      )
    );
  }

  _buildSharedItemResults(BuildContext context, CurrentUserState currentUserState) {
    if (_sharedItems.length > 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: <Widget> [
              ..._sharedItems.map((sharedItem) => _buildSharedItem(sharedItem, context, currentUserState) ).toList(),
            ]
          ),
        ]
      );
    }
    return Column(
      children: [
        _buildMessage(context),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            Provider.of<SharedItemState>(context, listen: false).clearSharedItem();
            _linkService.Go('/shared-item-save', context, currentUserState: currentUserState);
            _socketService.TrackEvent('Post First Shared Item');
          },
          child: Text('Post the first Shared Item!'),
        ),
      ]
    );
  }

  void _searchSharedItems({int lastPageNumber = 0}) {
    if(mounted) {
      setState(() {
        _loading = true;
        _message = '';
        _canLoadMore = false;
      });
    }
    var currentUser = Provider.of<CurrentUserState>(context, listen: false).currentUser;
    if (lastPageNumber != 0) {
      _lastPageNumber = lastPageNumber;
    } else {
      _lastPageNumber = 1;
    }
    var data = {
      //'page': _lastPageNumber,
      'skip': (_lastPageNumber - 1) * _itemsPerPage,
      'limit': _itemsPerPage,
      //'sortKey': '-created_at',
      //'tags': [],
      // 'withOwnerInfo': 1,
      'lngLat': _filters['inputLocation']['lngLat'],
      'maxMeters': _filters['maxMeters'],
      'withOwnerUserId': currentUser != null ? currentUser.id : '',
    };
    List<String> keys = ['title', 'fundingRequired_min', 'fundingRequired_max', 'myType'];
    for (var key in keys) {
      if (_filters[key] != null && _filters[key] != '') {
        data[key] = _filters[key]!;
      }
    }
    //if (_filters['tags'] != '') {
    //  data['tags'] = [ _filters['tags'] ];
    //}
    _socketService.emit('searchSharedItems', data);
    _UpdateUrl();
  }
  
  void _UpdateUrl() {
    if(mounted && kIsWeb) {
      String? lng = _filters['inputLocation']['lngLat'][0]?.toString();
      String? lat = _filters['inputLocation']['lngLat'][1]?.toString();
      String? maxMeters = _filters['maxMeters']?.toString();
      String? myType = _filters['myType']?.toString();
      String url = '/own?lng=${lng}&lat=${lat}&range=${maxMeters}';
      if (myType != null && myType.length > 0) {
        url += '&myType=${myType!}';
      }
      html.window.history.pushState({}, '', url);
      // final url =  html.window.history.state.toString();
    }
  }

}
