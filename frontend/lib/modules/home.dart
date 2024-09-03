import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../app_scaffold.dart';
import '../common/buttons.dart';
import '../common/colors_service.dart';
// import '../common/config_service.dart';
import '../common/style.dart';
import '../common/video.dart';
import '../modules/neighborhood/neighborhoods.dart';
import '../modules/neighborhood/neighborhood_state.dart';
import '../modules/event/featured_event_photos.dart';

class HomeComponent extends StatefulWidget {
  @override
  _HomeComponentState createState() => _HomeComponentState();
}

class _HomeComponentState extends State<HomeComponent> {
  Buttons _buttons = Buttons();
  ColorsService _colors = ColorsService();
  // ConfigService _configService = ConfigService();
  Style _style = Style();
  Video _video = Video();
  // late YoutubePlayerController _youtubeController;
  // late YoutubePlayerController _youtubeControllerNeighbors;

  @override
  void initState() {
    super.initState();

    // _youtubeController = YoutubePlayerController.fromVideoId(
    //   videoId: 'B-Gz9VCGoa0',
    //   autoPlay: false,
    //   params: const YoutubePlayerParams(showFullscreenButton: false),
    // );
    // _youtubeControllerNeighbors = YoutubePlayerController.fromVideoId(
    //   videoId: '2Rm2kM36c5g',
    //   autoPlay: false,
    //   params: const YoutubePlayerParams(showFullscreenButton: false),
    // );
  }

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
            return BuildBody(topHeight: 400, titleSize: 50);
          }
        }
      )
    );
  }

  Widget BuildBody({double topHeight = 200, double titleSize = 30}) {
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
            padding: EdgeInsets.only(top: 50, bottom: 50, left: 50, right: 50),
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
                  // child: _buttons.LinkElevated(context, 'Join or Create Your TealTown', '/neighborhoods'),
                  child: _buttons.LinkElevated(context, 'Create Your TealTown', '/ambassador', track: true),
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
      // Container(padding: EdgeInsets.only(left: 20, right: 20), child: Neighborhoods() ),
      // // Extra height for neighborhoods input location overlay.
      // SizedBox(height: 100),

      // _style.Text1('For Ambassadors', size: 'large'),
      // _style.SpacingH('medium'),
      Container(height: 300, width: 533,
        child: _video.Youtube('B-Gz9VCGoa0'),
      ),
      _style.SpacingH('xlarge'),

      // _style.Text1('For Neighbors', size: 'large'),
      // _style.SpacingH('medium'),
      // Container(height: 300, width: 533,
      //   // child: YoutubePlayer(
      //   //   controller: _youtubeControllerNeighbors,
      //   //   aspectRatio: 16 / 9,
      //   // ),
      //   // child: Video('2Rm2kM36c5g'),
      //   child: _video.Youtube('2Rm2kM36c5g'),
      // ),
      // _style.SpacingH('medium'),

      FeaturedEventPhotos(),
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

  // Widget Video(String videoId) {
  //   // final YoutubePlayerController controller;
  //   final controller = YoutubePlayerController();
  //   // controller = YoutubePlayerController.fromVideoId(
  //   //   videoId: videoId,
  //   //   params: const YoutubePlayerParams(
  //   //     showFullscreenButton: true
  //   //   ),
  //   // );
  //   controller.loadVideoById(videoId: videoId);
  //   return YoutubePlayer(
  //     controller: controller,
  //     aspectRatio: 16 / 9,
  //   );
  // }
}
