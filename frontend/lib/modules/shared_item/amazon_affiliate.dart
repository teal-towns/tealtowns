import 'package:flutter/material.dart';

import '../../app_scaffold.dart';
import '../../common/buttons.dart';
import '../../common/layout_service.dart';

class AmazonAffiliate extends StatefulWidget {
  @override
  _AmazonAffiliateState createState() => _AmazonAffiliateState();
}

class _AmazonAffiliateState extends State<AmazonAffiliate> {
  Buttons _buttons = Buttons();
  LayoutService _layoutService = LayoutService();

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> links = [
      { 'image': 'https://m.media-amazon.com/images/I/81UmM4AHBXL._AC_SX679_.jpg', 'url': 'https://www.amazon.com/gp/product/B0CCF5F9J8?&linkCode=ll1&tag=tealtowns-20&linkId=80c2026e962bcdb57dd4af92cd3de76f&language=en_US&ref_=as_li_ss_tl', },
      { 'image': 'https://m.media-amazon.com/images/I/51rL2bBjI7L._AC_SX679_.jpg', 'url': 'https://www.amazon.com/gp/product/B0BZHH6HJW?&linkCode=ll1&tag=tealtowns-20&linkId=98bb9b618e956c96b8af22be7acbba79&language=en_US&ref_=as_li_ss_tl', },
      { 'image': 'https://m.media-amazon.com/images/I/716TwH3VD3L._AC_SY879_.jpg', 'url': 'https://www.amazon.com/gp/product/B09TPTBGYL?&linkCode=ll1&tag=tealtowns-20&linkId=5ade55da951591baa281c4a2099e8c7c&language=en_US&ref_=as_li_ss_tl', },
      { 'image': 'https://m.media-amazon.com/images/I/41uitYlFlxL._AC_SX679_.jpg', 'url': 'https://www.amazon.com/gp/product/B0BKTJ99P6?&linkCode=ll1&tag=tealtowns-20&linkId=987b9ba2385d52fbab35b54a7a15aa4e&language=en_US&ref_=as_li_ss_tl', },
    ];
    List<Widget> linkWidgets = [];
    for (var link in links) {
      linkWidgets.add(
        Column(
          children: [
            Image.network(link['image']!, width: 200, height: 200, fit: BoxFit.cover),
            SizedBox(height: 10),
            _buttons.LinkElevated(context, 'Buy', link['url']!, launchUrl: true),
            SizedBox(height: 10),
          ],
        )
      );
    }
    return AppScaffoldComponent(
      listWrapper: true,
      body: Column(
        children: [
          Text("Amazon Affiliate"),
          SizedBox(height: 10),
          _layoutService.WrapWidth(linkWidgets),
          SizedBox(height: 10),
        ],
      ),
    );
  }
}