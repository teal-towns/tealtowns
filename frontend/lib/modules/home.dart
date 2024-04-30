import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_scaffold.dart';
import '../common/buttons.dart';
import '../common/style.dart';

class HomeComponent extends StatefulWidget {
  @override
  _HomeComponentState createState() => _HomeComponentState();
}

class _HomeComponentState extends State<HomeComponent> {
  Buttons _buttons = Buttons();
  Style _style = Style();

  // @override
  // void initState() {
  //   super.initState();
  //   Timer(Duration(milliseconds: 500), () {
  //     context.go('/about');
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    double imageSize = 150;
    return AppScaffoldComponent(
      listWrapper: true,
      width: 900,
      body: Column(
        children: [
          // Text('Loading..'),
          _style.Text1('Welcome to TealTowns!', size: 'xlarge', fontWeight: FontWeight.bold),
          _style.SpacingH('medium'),
          Row(
            children: [
              Expanded(flex: 1, child: _style.Text1('To address climate change and loneliness, our mission is to help neighbors green their town together.',
                size: 'large', fontWeight: FontWeight.bold)),
              _style.SpacingV('xlarge'),
              Image.asset('assets/images/green-city-1.jpg', height: imageSize * 1.5, width: imageSize * 1.5, fit: BoxFit.cover,),
            ]
          ),
          _style.SpacingH('medium'),
          Row(
            children: [
              Image.asset('assets/images/shared-meal.jpg', height: imageSize, width: imageSize, fit: BoxFit.cover,),
              _style.SpacingV('xlarge'),
              Expanded(flex: 1, child: _style.Text1('Connect with your neighbors over a shared meal and other weekly events.', fontWeight: FontWeight.bold)),
            ]
          ),
          _style.SpacingH('medium'),
          Row(
            children: [
              Image.asset('assets/images/event.jpg', height: imageSize, width: imageSize, fit: BoxFit.cover,),
              _style.SpacingV('xlarge'),
              Expanded(flex: 1, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _style.Text1('Regular meetings build trust and community and allow for conversations and small 1% greener actions.', fontWeight: FontWeight.bold),
                  _style.SpacingH('medium'),
                  _style.Text1('Such as co-owning items to reduce carbon footprint of your neighborhood.'),
                  _style.SpacingH('medium'),
                  _style.Text1('As the group grows to 100 - 150 people, larger green projects become possible.'),
                ]
              )),
            ]
          ),
          _style.SpacingH('xlarge'),
          _style.Text1('Get started today', size: 'large', fontWeight: FontWeight.bold),
          _style.SpacingH('medium'),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buttons.LinkElevated(context, 'Create event', '/weekly-event-save'),
              _style.SpacingV('xlarge'),
              _buttons.LinkElevated(context, 'Join an event', '/weekly-events'),
            ]
          ),
          _style.SpacingH('xlarge'),
        ]
      )
    );
  }
}
