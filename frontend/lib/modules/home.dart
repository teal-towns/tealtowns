import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../app_scaffold.dart';
import '../common/buttons.dart';
import '../common/colors_service.dart';
// import '../common/config_service.dart';
import '../common/style.dart';
import '../modules/neighborhood/neighborhoods.dart';
import '../modules/neighborhood/neighborhood_state.dart';

class HomeComponent extends StatefulWidget {
  @override
  _HomeComponentState createState() => _HomeComponentState();
}

class _HomeComponentState extends State<HomeComponent> {
  Buttons _buttons = Buttons();
  ColorsService _colors = ColorsService();
  // ConfigService _configService = ConfigService();
  Style _style = Style();

  @override
  Widget build(BuildContext context) {
    return AppScaffoldComponent(
      listWrapper: true,
      width: 2000,
      paddingLeft: 0,
      paddingRight: 0,
      paddingTop: 0,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 900) {
            return BuildBody();
          } else {
            return BuildBody(topHeight: 300, titleSize: 75);
          }
        }
      )
    );
  }

  Widget BuildBody({double topHeight = 200, double titleSize = 50}) {
    Widget top = Container(
      child: Row(
        children: [
          Expanded(flex: 1, child: Container()),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _style.SpacingH('medium'),
              Row(
                children: [
                  _style.Text1('TealTowns', fontSize: titleSize, colorKey: 'white', fontWeight: FontWeight.bold),
                  Image.asset('assets/images/logo-white.png', width: titleSize, height: titleSize),
                ]
              ),
              _style.SpacingH('medium'),
              _style.Text1('Friendship at the Heart of Sustainable Living', colorKey: 'white', size: 'large'),
              _style.SpacingH('medium'),
            ]
          ),
          Expanded(flex: 1, child: Container()),
        ]
      )
    );

    Widget content = Container(
      padding: EdgeInsets.only(left: 20, right: 20),
      child: Stack(
        children: [
          Container(
            padding: EdgeInsets.only(top: 125),
            child: Align(
              alignment: Alignment.bottomCenter,
              // width: 300,
              // height: 300,
              child: Image.asset('assets/images/food-dish.png', width: 450, height: 450),
            ),
          ),
          Align(alignment: Alignment.center, child: Container(
            // color: Colors.white,
            width: 600,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: Offset(0, 3), // changes position of shadow
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _style.SpacingH('medium'),
                _style.Text1('Find your TealTown and share your first meal!', size: 'large', colorKey: 'primary'),
                _style.SpacingH('medium'),
                _style.Text1('We believe that communities and a healthier planet go hand-in-hand. TealTowns paves the way for vibrant, resilient living by encouraging neighbors to meet, make friends, and plan events together. By fostering local connections, TealTowns create an environment where everyone feels connected and empowered - one neighbor at a time.'),
                _style.SpacingH('large'),
                Align(alignment: Alignment.center,
                  child: _buttons.LinkElevated(context, 'Join or Create Your TealTown', '/neighborhoods'),
                ),
                SizedBox(height: 30),
              ],
            ),
          ))
        ]
      )
    );

    List<Widget> colsBottom = [
      SizedBox(height: 30),
      content,
      // SizedBox(height: 20),
      Container(padding: EdgeInsets.only(left: 20, right: 20), child: Neighborhoods() ),
      // Extra height for neighborhoods input location overlay.
      SizedBox(height: 100),
    ];

    return Column(
      children: [
        Container(
          width: double.infinity,
          height: topHeight,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/green-town.png"),
              fit: BoxFit.cover,
              // colorFilter: new ColorFilter.mode(Colors.black.withOpacity(0.8), BlendMode.dstATop),
            ),
          ),
          child: Column(
            children: [
              Expanded(flex: 1, child: Container()),
              top,
              Expanded(flex: 1, child: Container()),
            ]
          ),
        ),
        ...colsBottom,
      ]
    );
  }
}
