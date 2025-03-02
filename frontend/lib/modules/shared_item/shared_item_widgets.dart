import 'package:flutter/material.dart';
import '../../common/currency_service.dart';
import '../../common/link_service.dart';
import '../../common/parse_service.dart';
import './shared_item_class.dart';
import '../user_auth/current_user_state.dart';

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
              'Owner paid ${currencyService.Format(sharedItem.currentPrice, sharedItem.currency)}. '),
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
