import 'package:flutter/material.dart';

class AlertService {
  AlertService._privateConstructor();
  static final AlertService _instance = AlertService._privateConstructor();
  factory AlertService() {
    return _instance;
  }

  void Show(BuildContext context, String message, { int seconds = 5 } ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        // action: SnackBarAction(
        //   label: 'Action',
        //   onPressed: () {
        //     // Code to execute.
        //   },
        // ),
        content: Row(
          children: [
            Expanded(flex: 1, child: Container()),
            Text(message, style: TextStyle(color: Colors.white),),
            Expanded(flex: 1, child: Container()),
          ]
        ),
        duration: Duration(milliseconds: seconds * 1000),
        // width: 280.0,
        padding: EdgeInsets.only(top: 50, bottom: 50, left: 20, right: 20),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
    );
  }
}