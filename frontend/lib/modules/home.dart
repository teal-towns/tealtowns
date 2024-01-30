import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_scaffold.dart';

class HomeComponent extends StatefulWidget {
  @override
  _HomeComponentState createState() => _HomeComponentState();
}

class _HomeComponentState extends State<HomeComponent> {

  @override
  void initState() {
    super.initState();
    Timer(Duration(milliseconds: 500), () {
      context.go('/weekly-events');
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffoldComponent(
      body: ListView(
        children: [
          Text('Loading..'),
        ]
      )
    );
  }
}
