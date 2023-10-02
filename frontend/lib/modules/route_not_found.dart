import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routes.dart';

class RouteNotFoundPage extends StatelessWidget {
  final String? attemptedRoute;

  RouteNotFoundPage({this.attemptedRoute});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
                "Route ${attemptedRoute != null ? attemptedRoute : ''} not found"),
            TextButton(
              onPressed: () => context.go(Routes.home),
              child: Text("Go Home"),
            )
          ],
        ),
      ),
    );
  }
}
