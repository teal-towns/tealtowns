import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import './modules/user_auth/current_user_state.dart';
import './routes.dart';

_launchURL(url) async {
  //const url = 'https://flutter.dev';
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}

class AppScaffoldComponent extends StatefulWidget {
  Widget? body;

  AppScaffoldComponent({this.body});

  @override
  _AppScaffoldState createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffoldComponent> {
  Widget _buildLinkButton(BuildContext context, String routePath, String label) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(width: 1, color: Theme.of(context).primaryColor)),
      ),
      child: ListTile(
        //onPressed: () {
        onTap: () {
          //if (Scaffold.of(context).isEndDrawerOpen) {
          Navigator.of(context).pop();
          //}
          context.go(routePath);
        },
        //child: Text(label),
        title: Text(label, style: TextStyle( color: Theme.of(context).primaryColor )),
      ),
    );
  }

  Widget _buildUserButton(BuildContext context, currentUserState, { double width = 100, double fontSize = 13 }) {
    if (currentUserState.isLoggedIn) {
      return SizedBox.shrink();
    }
    return TextButton(
      onPressed: () {
        context.go(Routes.login);
      },
      style: TextButton.styleFrom(
        backgroundColor: Colors.white,
        minimumSize: Size.fromWidth(width),
        padding: EdgeInsets.all(0),
      ),
      child: Container(
        padding: EdgeInsets.only(top: 10),
        child: Column(
          children: <Widget>[
            Icon(Icons.person, color: Theme.of(context).primaryColor),
            Text(
              'Log In',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: fontSize,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(context, currentUserState) {
    if (currentUserState.isLoggedIn) {
      return _buildLinkButton(context, '/logout', 'Logout');
    }
    return SizedBox.shrink();
  }

  Widget _buildNavButton(String route, String text, IconData icon, BuildContext context, { double width = 100, double fontSize = 13 }) {
    return TextButton(
      onPressed: () {
        context.go(route);
      },
      style: TextButton.styleFrom(
        backgroundColor: Colors.white,
        minimumSize: Size.fromWidth(width),
        padding: EdgeInsets.all(0),
      ),
      child: Container(
        padding: EdgeInsets.only(top: 10),
        child: Column(
          children: <Widget>[
            Icon(icon, color: Theme.of(context).primaryColor),
            Text(
              text,
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: fontSize,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerButton(BuildContext context, { double width = 100, double fontSize = 13 }) {
    return Builder(
      builder: (BuildContext context) {
        return TextButton(
          onPressed: () {
            Scaffold.of(context).openEndDrawer();
          },
          style: TextButton.styleFrom(
            backgroundColor: Colors.white,
            minimumSize: Size.fromWidth(width),
            padding: EdgeInsets.all(0),
          ),
          child: Container(
            padding: EdgeInsets.only(top: 10),
            child: Column(
              children: <Widget>[
                Icon(Icons.menu, color: Theme.of(context).primaryColor),
                Text(
                  'More',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: fontSize,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildDrawer(BuildContext context, var currentUserState) {
    List<Widget> columns = [];
    if (currentUserState.hasRole('admin')) {
    }

    return Drawer(
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                flex: 1,
                child: Text(''),
              ),
              IconButton(
                icon: Icon(Icons.close),
                color: Theme.of(context).primaryColor,
                onPressed: () {
                  Navigator.of(context).pop();
                }
              ),
            ],
          ),
          _buildLogoutButton(context, currentUserState),
          ...columns,
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, var currentUserState) {
    List<Widget> rows = [
      Expanded(
        flex: 1,
        child: _buildNavButton('/home', 'Home', Icons.home, context, width: double.infinity, fontSize: 10),
      ),
    ];
    if (!currentUserState.isLoggedIn) {
      rows.add(Expanded(
        flex: 1,
        child: _buildUserButton(context, currentUserState, width: double.infinity, fontSize: 10),
      ));
    }
    rows.add(
      Expanded(
        flex: 1,
        child: _buildDrawerButton(context, width: double.infinity, fontSize: 10),
      ),
    );

    return SafeArea(
      child: Container(
        height: 55,
        child: Row(
          children: <Widget>[
            ...rows,
          ]
        ),
        color: Colors.white,
        // decoration: BoxDecoration(
        //   boxShadow: [
        //     BoxShadow(
        //       color: Colors.grey.shade300,
        //       spreadRadius: 2,
        //       blurRadius: 4,
        //       offset: Offset(0, 0),
        //     )
        //   ]
        // ),
      )
    );
  }

  Widget _buildBody(BuildContext context, var currentUserState, { bool header = false }) {
    if (header) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildHeader(context, currentUserState),
          // For drop shadow, otherwise it is cut off.
          // SizedBox(height: 5),
          Expanded(
            child: Container(
              color: Colors.white,
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  width: 1200,
                  child: widget.body,
                  color: Colors.white,
                )
              )
            )
          ),
        ]
      );
    }
    return Container(
      color: Colors.white,
      child: Align(
        alignment: Alignment.center,
        child: Container(
          width: 1200,
          child: widget.body,
          color: Colors.white,
        )
      )
    );
  }

  Widget _buildSmall(BuildContext context, var currentUserState) {
    return Scaffold(
      endDrawer: _buildDrawer(context, currentUserState),
      body: _buildBody(context, currentUserState, header: true),
    );
  }

  Widget _buildMedium(BuildContext context, var currentUserState) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: Image.asset('assets/images/logo.png', width: 100, height: 50),
        actions: <Widget>[
          _buildNavButton('/home', 'Home', Icons.home, context),
          _buildUserButton(context, currentUserState),
          _buildDrawerButton(context),
        ],
      ),
      endDrawer: _buildDrawer(context, currentUserState),
      body: _buildBody(context, currentUserState),
    );
  }

  @override
  Widget build(BuildContext context) {
    var currentUserState = context.watch<CurrentUserState?>();
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return _buildMedium(context, currentUserState);
        } else {
          return _buildSmall(context, currentUserState);
        }
      }
    );
  }
}
