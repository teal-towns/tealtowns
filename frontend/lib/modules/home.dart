import 'package:flutter/material.dart';

import '../app_scaffold.dart';

class HomeComponent extends StatefulWidget {
  @override
  _HomeComponentState createState() => _HomeComponentState();
}

class _HomeComponentState extends State<HomeComponent> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffoldComponent(
      body: ListView(
        children: [
          Text('Home'),
        ]
      )
    );
  }
}
