import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app_scaffold.dart';
import '../../common/config_service.dart';
import '../../common/currency_service.dart';
import '../../common/link_service.dart';
import '../../common/parse_service.dart';
import '../../common/socket_service.dart';
import './shared_item_class.dart';
import './shared_item_service.dart';
import './shared_item_state.dart';
import '../user_auth/current_user_state.dart';

class SharedItem extends StatefulWidget {
  String uName;
  SharedItem({this.uName = ''});

  @override
  _SharedItemState createState() => _SharedItemState();
}

class _SharedItemState extends State<SharedItem> {
  ConfigService _configService = ConfigService();
  CurrencyService _currency = CurrencyService();
  LinkService _linkService = LinkService();
  SharedItemService _sharedItemService = SharedItemService();
  List<String> _routeIds = [];
  SocketService _socketService = SocketService();
  ParseService _parseService = ParseService();

  SharedItemClass _sharedItem = SharedItemClass.fromJson({});
  bool _loading = true;
  String _message = '';

  @override
  void initState() {
    super.initState();

    _routeIds.add(_socketService.onRoute('GetSharedItemByUName', callback: (String resString) {
      var res = jsonDecode(resString);
      var data = res['data'];
      if (data['valid'] == 1) {
        _sharedItem = SharedItemClass.fromJson(data['sharedItem']);
        setState(() { _sharedItem = _sharedItem; });
      } else {
        _message = data['message'].length > 0 ? data['message'] : 'Error.';
      }
      setState(() {
        _loading = false;
      });
    }));

    GetSharedItem();
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
        body: Column(
          children: [
            LinearProgressIndicator(),
          ]
        )
      );
    }

    var currentUserState = context.watch<CurrentUserState>();
    List<Widget> buttons = [
      ElevatedButton(
        onPressed: () async {
          String msg =
              'Hey! Can I borrow ${_sharedItem.title} from you? ${'https://tealtowns.com/si/${_sharedItem.uName}'}';
          Clipboard.setData(ClipboardData(text: msg)).then((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'A request message has been copied to your clipboard!')),
            );
          });
        },
        child: Text('Reqest'),
      ),
      SizedBox(width: 10),
    ];
    if (currentUserState.isLoggedIn &&
        _sharedItem.currentOwnerUserId == currentUserState.currentUser.id) {
      buttons.addAll([
        ElevatedButton(
          onPressed: () {
            Provider.of<SharedItemState>(context, listen: false).setSharedItem(_sharedItem);
            _linkService.Go('/shared-item-save?id=${_sharedItem.id}', context, currentUserState: currentUserState);
          },
          child: Text('Edit'),
        ),
        SizedBox(width: 10),
      ]);
    }

    List<Widget> columnsDistance = [];
    if (_sharedItem.xDistanceKm >= 0) {
      columnsDistance = [
        Text('${_sharedItem.xDistanceKm.toStringAsFixed(1)} km away'),
        SizedBox(height: 10),
      ];
    }

    String currentPriceString = _currency.Format(_sharedItem.currentPrice, _sharedItem.currency!);

    Map<String, String> texts;
    Map<String, dynamic> paymentInfo;
    paymentInfo = _sharedItemService.GetPayments(_sharedItem.currentPrice!,
      _sharedItem.monthsToPayBack!, _sharedItem.maxOwners, _sharedItem.maintenancePerYear!);
    texts = _sharedItemService.GetTexts(paymentInfo['downPerPersonWithFee']!,
      paymentInfo['monthlyPaymentWithFee']!, paymentInfo['monthsToPayBack']!, _sharedItem.currency);
    String perPersonMaxOwners = "${texts['perPerson']} with max owners (${_sharedItem.maxOwners})";

    Map<String, dynamic> config = _configService.GetConfig();
    String shareUrl = '${config['SERVER_URL']}/si/${_sharedItem.uName}';
    return AppScaffoldComponent(
      listWrapper: true,
      body: Column(
        children: [
          _sharedItem.imageUrls.length <= 0 ?
            Image.asset('assets/images/no-image-available-icon-flat-vector.jpeg', height: 300, width: double.infinity, fit: BoxFit.cover,)
              :Image.network(_sharedItem.imageUrls![0], height: 300, width: double.infinity, fit: BoxFit.cover),
          SizedBox(height: 5),
          Text(_sharedItem.title!,
            style: Theme.of(context).textTheme.displayMedium,
          ),
          SizedBox(height: 5),
          ...columnsDistance,
          if(_parseService.toIntNoNull(_sharedItem.bought) <= 0) Text("${perPersonMaxOwners}"),
          SharedItemSections(
            sharedItem: _sharedItem,
            currentUserState: currentUserState,
            currencyService: _currency,
            linkService: _linkService,
            parseService: _parseService,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...buttons,
            ]
          ),
          SizedBox(height: 10),
          QrImageView(
            data: shareUrl,
            version: QrVersions.auto,
            size: 200.0,
          ),
          SizedBox(height: 10),
          Text(shareUrl),
          SizedBox(height: 10),
        ],
      )
    );
  }

  void GetSharedItem() {
    setState(() { _loading = true; });
    String userId = Provider.of<CurrentUserState>(context, listen: false).isLoggedIn ?
      Provider.of<CurrentUserState>(context, listen: false).currentUser.id : '';
    var data = {
      'uName': widget.uName,
      'withOwnerUserId': userId,
    };
    _socketService.emit('GetSharedItemByUName', data);
  }
}

// Make this a reusable widget for shared items page too
class SharedItemSections extends StatelessWidget {
  final SharedItemClass sharedItem;
  final CurrentUserState currentUserState;
  final CurrencyService currencyService;
  final LinkService linkService;
  final ParseService parseService;

  const SharedItemSections({
    Key? key,
    required this.sharedItem,
    required this.currentUserState,
    required this.currencyService,
    required this.linkService,
    required this.parseService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...buildCoBuySection(context),
        const SizedBox(height: 10),
        ...buildInvestmentSection(context),
        ...buildStatusSection(context),
      ],
    );
  }

  List<Widget> buildCoBuySection(BuildContext context) {
    final List<Widget> colsCoBuy = [];
    final bool isBought = parseService.toIntNoNull(sharedItem.bought) > 0;

    if (sharedItem.sharedItemOwner_current.sharedItemId == sharedItem.id) {
      if (sharedItem.sharedItemOwner_current.investorOnly > 0) {
        colsCoBuy.add(
          Text(
              'You invested ${currencyService.Format(sharedItem.sharedItemOwner_current.totalPaid, sharedItem.currency)}. '
              'Once there are enough co-owners you can purchase this and will start being paid back.'),
        );
      } else if (isBought) {
        colsCoBuy.add(
           Text(
            'Owner paid ${currencyService.Format(sharedItem.currentPrice, sharedItem.currency)}. '
        
          ),
        );
      } else {
        colsCoBuy.add(
          Text(
              'Owner paid ${currencyService.Format(sharedItem.sharedItemOwner_current.totalPaid, sharedItem.currency)}. Once there are enough co-owners you will own this!'),
        );
      }
    } else {
      colsCoBuy.add(
        ElevatedButton(
          onPressed: () {
            final String id = sharedItem.sharedItemOwner_current.id;
            linkService.Go(
                '/shared-item-owner-save?sharedItemId=${sharedItem.id}&id=$id',
                context,
                currentUserState: currentUserState);
          },
          child: const Text('Co-Buy'),
        ),
      );
    }

    return colsCoBuy;
  }

  List<Widget> buildInvestmentSection(BuildContext context) {
    final List<Widget> colsInvest = [];

    if (sharedItem.fundingRequired > 0) {
      final String fundingRequired =
          "${currencyService.Format(sharedItem.fundingRequired, sharedItem.currency)} funding required";

      colsInvest.addAll([
        Text(fundingRequired),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            final String id = sharedItem.sharedItemOwner_current.id;
            linkService.Go(
                '/shared-item-owner-save?sharedItemId=${sharedItem.id}&id=$id',
                context,
                currentUserState: currentUserState);
          },
          child: const Text('Invest'),
        ),
        const SizedBox(height: 10),
      ]);
    }

    return colsInvest;
  }

  List<Widget> buildStatusSection(BuildContext context) {
    final List<Widget> colsStatus = [];

    if (sharedItem.sharedItemOwner_current.status == 'pendingMonthlyPayment') {
      colsStatus.addAll([
        ElevatedButton(
          onPressed: () {
            final String id = sharedItem.sharedItemOwner_current.id;
            linkService.Go(
                '/shared-item-owner-save?sharedItemId=${sharedItem.id}&id=$id',
                context,
                currentUserState: currentUserState);
          },
          child: const Text('Set Up Monthly Payments'),
        ),
        const SizedBox(height: 10),
      ]);
    }

    return colsStatus;
  }
}
