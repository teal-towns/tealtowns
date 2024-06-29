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

    Widget topLeft = Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _style.SpacingH('medium'),
          _style.Text1('TealTowns1', size: 'xxlarge', colorKey: 'white', fontWeight: FontWeight.bold),
          _style.SpacingH('medium'),
          _style.Text1('Friendship at the Heart of Sustainable Living', colorKey: 'white', size: 'large'),
          _style.SpacingH('medium'),
        ]
      ),
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
              child: Image.asset('assets/images/food-dish.jpg', width: 450, height: 450),
            ),
          ),
          Align(alignment: Alignment.center, child: Container(
            // color: Colors.white,
            width: 600,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(20)),
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

    return AppScaffoldComponent(
      listWrapper: true,
      width: 2000,
      paddingLeft: 0,
      paddingRight: 0,
      paddingTop: 0,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 900) {
            return Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/images/green-leaf-background.jpg"),
                      fit: BoxFit.cover,
                      // colorFilter: new ColorFilter.mode(Colors.black.withOpacity(0.8), BlendMode.dstATop),
                    ),
                  ),
                  child: topLeft,
                ),
                BuildTiles(),
                SizedBox(height: 30),
                content,
                // SizedBox(height: 20),
                Container(padding: EdgeInsets.only(left: 20, right: 20), child: Neighborhoods() ),
                // Extra height for neighborhoods input location overlay.
                SizedBox(height: 100),
              ]
            );
          } else {
            return Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 400,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/images/green-leaf-background.jpg"),
                      fit: BoxFit.cover,
                      // colorFilter: new ColorFilter.mode(Colors.black.withOpacity(0.8), BlendMode.dstATop),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 1, child: Container()),
                      Column(
                        children: [
                          Expanded(flex: 1, child: Container()),
                          topLeft,
                          Expanded(flex: 1, child: Container()),
                        ]
                      ),
                      Expanded(flex: 3, child: Container()),
                      Column(
                        children: [
                          Expanded(flex: 1, child: Container()),
                          BuildTiles(backgroundColorKey: 'transparent', width: 400),
                          Expanded(flex: 1, child: Container()),
                        ]
                      ),
                      Expanded(flex: 1, child: Container()),
                    ]
                  )
                ),
                SizedBox(height: 30),
                content,
                // SizedBox(height: 20),
                Container(padding: EdgeInsets.only(left: 20, right: 20), child: Neighborhoods() ),
                // Extra height for neighborhoods input location overlay.
                SizedBox(height: 100),
              ]
            );
          }
        }
      )
    );
  }

  Widget BuildTiles({ String backgroundColorKey = 'primary', double width = double.infinity }) {
    Color white = Colors.white;
    Color background = _colors.colors[backgroundColorKey];
    Color border = _colors.colors['white'];
    double tileHeight = 100;
    double tileTextWidth = 75;
    Widget tiles = Container(width: width, child: Column(
      children: [
        Row(
          children: [
            Expanded(flex: 1, child: Container(decoration: BoxDecoration(border: Border.all(color: border), color: background), padding: EdgeInsets.all(10), height: tileHeight, child: InkWell(
              onTap: () { context.go('/weekly-events'); },
              child: Align(alignment: Alignment.center, child: Text('Neighborhood Events', style: TextStyle(color: white), textAlign: TextAlign.center)),
            ))),
            Expanded(flex: 1, child: Image.asset('assets/images/food-1.jpg', width: double.infinity, height: tileHeight, fit: BoxFit.cover),),
            Expanded(flex: 1, child: Container(decoration: BoxDecoration(border: Border.all(color: border), color: background), padding: EdgeInsets.all(10), height: tileHeight, child: InkWell(
              onTap: () { context.go('/own'); },
              child: Align(alignment: Alignment.center, child: Text('Shared Items', style: TextStyle(color: white), textAlign: TextAlign.center)),
            ))),
          ]
        ),
        Row(
          children: [
            Expanded(flex: 1, child: Image.asset('assets/images/photo-party-1.jpg', width: double.infinity, height: tileHeight, fit: BoxFit.cover),),
            Expanded(flex: 1, child: Container(decoration: BoxDecoration(border: Border.all(color: border), color: background), padding: EdgeInsets.all(10), height: tileHeight, child: InkWell(
              onTap: () { context.go('/eat'); },
              child: Align(alignment: Alignment.center, child: Text('Meals With Friends', style: TextStyle(color: white), textAlign: TextAlign.center)),
            ))),
            Expanded(flex: 1, child: Image.asset('assets/images/neighborhood-court-birds-eye.jpg', width: double.infinity, height: tileHeight, fit: BoxFit.cover),),
          ]
        )
      ]
    ));
    return tiles;
  }
}
