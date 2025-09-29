import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app_scaffold.dart';
import '../common/buttons.dart';
import '../common/colors_service.dart';
import '../common/style.dart';
import '../modules/neighborhood/neighborhoods.dart';
import '../modules/neighborhood/neighborhood_state.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Buttons _buttons = Buttons();
  ColorsService _colors = ColorsService();
  Style _style = Style();

  @override
  void initState() {
    super.initState();

    // var neighborhoodState = Provider.of<NeighborhoodState>(context, listen: false);
    // if (neighborhoodState.defaultUserNeighborhood != null && neighborhoodState.defaultUserNeighborhood!.neighborhood.uName.length > 0) {
    //   Timer(Duration(milliseconds: 100), () {
    //     context.go('/ne/${neighborhoodState.defaultUserNeighborhood!.neighborhood.uName}');
    //   });
    // }
  }

  @override
  Widget build(BuildContext context) {
    double height = 500;
    return AppScaffoldComponent(
      listWrapper: true,
      paddingLeft: 0, paddingRight: 0, paddingTop: 0,
      body: Column(
        children: [
          // _style.Text1('Neighbor Dinners', size: 'xlarge'),
          // _style.SpacingH('medium'),
          // _style.Text1('At TealTowns, we believe the loneliness and climate crises can be solved by connecting people together to work on local green (nature based) projects. The first step is to join (or create) your neighborhood community to meet for weekly shared meals.',),
          // _style.SpacingH('medium'),
          // Neighborhoods(showSeeAll: false, showLink: false, redirectTo: 'events',),

          // Simple Concord page
          Stack(
            children: [
              Image.asset('assets/images/park-play.png', height: height, width: double.infinity, fit: BoxFit.cover,),
              Container(
                color: Colors.black.withOpacity(0.33),
                child: Center(
                  child: SizedBox(
                    // height: MediaQuery.of(context).size.height,
                    height: height,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          // height: 200,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _style.Text1('Village Games Concord', size: 'xlarge', colorKey: 'white', fontWeight: FontWeight.bold,),
                              _style.SpacingH('medium'),
                              _style.Text1('Weekly Sunday gatherings for games, laughter, and community.', colorKey: 'white',),
                              _style.SpacingH('medium'),
                              _style.Text1('Sundays 4pm @ Todos Santos Park', colorKey: 'white', size: 'large',),
                              _style.SpacingH('medium'),
                              _buttons.LinkElevated(context, 'Join Us', 'mailto:luke.madera@gmail.com', launchUrl: true),
                            ],
                          )
                        )
                      ]
                    )
                  ),
                )
              )
            ]
          ),
        ]
      )
    );
  }
}
